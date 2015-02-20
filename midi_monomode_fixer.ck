"Midi Through" => string midi_in_name;
"USB MIDI Dark Energy" => string midi_out_name;

0 => int out_channel;

MidiMsg midi_msg;
MidiOut midi_out;
MidiIn midi_in;

[
-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
-1,-1,-1,-1,-1,-1,-1,-1,-1,-1] @=> int notes[];

-1 => int current_note;
-1 => int last_note;
0 => int current_velocity;

if(!midi_in.open(midi_in_name)){
    <<<"error opening " + midi_in_name>>>;
    me.exit();
}

if(!midi_out.open(midi_out_name)){
    <<<"error opening " + midi_out_name>>>;
    me.exit();
}

fun int is_held(int note){
    for(0 => int i; i<notes.cap(); i++){
        if(note == notes[i]){
            return true;
        }
        else
        if(notes[i] == -1){
            return false;
        }
    }
    return false;
}



fun void bend(int pitch){
    MidiMsg msg;
    
    0xe0 + out_channel => msg.data1;
    0 => msg.data2;
    pitch => msg.data3;
    midi_out.send(msg);
    //<<<"bend:" + pitch>>>;
}

fun void controller(int ctrl, int value){
    MidiMsg msg;
    
    0xb0 + out_channel => msg.data1;
    ctrl => msg.data2;
    value => msg.data3;
    midi_out.send(msg);
    //<<<"ctrl:" + ctrl + ", value:" + value>>>;
}

fun void note_on(int note, int velocity){
    MidiMsg msg;
    
    0x90 + out_channel => msg.data1;
    note => msg.data2;
    velocity => msg.data3;
    midi_out.send(msg);
    //<<<"on: " + note>>>;
}

fun void note_off(int note){
    MidiMsg msg;
    
    0x80 + out_channel => msg.data1;
    note => msg.data2;
    127 => msg.data3;
    midi_out.send(msg);
    //<<<"off:" + note>>>;
    
}



fun int pop(int note){
    0 => int shift;
    if(is_held(note)){
        for(0 => int i; i<notes.cap(); i++){
            if(shift & i > 0){
                notes[i] => notes[i-1];
                if(notes[i] == -1){
                    break;
                }
            }
            else if(note == notes[i]){
                1 => shift;
            }
        }
    }

    for(0 => int i; i<notes.cap(); i++){
        if(notes[i+1] == -1){
            return notes[i];
        }
    }
    
}

fun void push(int note){
    if(is_held(note)){
        return;
    }
    for(0 => int i; i<notes.cap(); i++){
        if(notes[i] == -1){
            note => notes[i];
            return;
        }
    }
}

while(true){
    midi_in => now;
    while(midi_in.recv(midi_msg)){
         midi_msg.data1 & 0x0f => int event_channel;
        ((midi_msg.data1 & 0xf0) >> 4) => int event_type;
        if(event_type == 0xb & midi_msg.data2 == 74){
            continue;
        }
        //<<<"midi_msg.data1:" + midi_msg.data1 + "midi_msg.data2:" + midi_msg.data2 + "midi_msg.data3:" + midi_msg.data3>>>;
        //<<<"event_channel: " + event_channel + ", event_type:" + event_type>>>;

        if(event_type == 11){
            // controller
            controller(midi_msg.data2, midi_msg.data3);
        }
        else
        if(event_type == 14){
            // pitch bend
            bend(midi_msg.data3);
        }
        
        if(event_type == 9){
            //<<<"note on">>>;
            current_note => last_note;
            midi_msg.data2 => current_note;
            midi_msg.data3 => current_velocity;
            push(current_note);
            
        }
        else
        if(event_type == 8){
            //<<<"note off">>>;
            current_note => last_note;
            pop(midi_msg.data2) => current_note;
        }

        if(event_type == 8 || event_type == 9){
            if(last_note != -1 && current_note != last_note){
                note_off(last_note);
            }
            //1::ms => now;
            if(current_note != -1 & current_note != last_note){
                note_on(current_note, current_velocity);
            }
        }

        
    }
}