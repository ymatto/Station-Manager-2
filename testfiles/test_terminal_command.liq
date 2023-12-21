#!/Users/omm/.opam/default/bin/liquidsoap -v

current_voice = ref ("Alex")
# speech_filename = file.temp("SM2_speech_", ".wav")
speech_filename = "speech.wav"

text = "hello everybody."

command_string = "say -o " ^ speech_filename ^ " --data-format=LEI16@44100 --channels=2 -v \"" ^ !current_voice ^ "\" \"[[ slnc 4000 ]] " ^ text ^ " \""
process_return = process.run(timeout = 20.0, command_string) # the new style

print("process returned:  #{process_return}")

if (process_return.stderr == "") then
    print("glorious success!")
else
    print("cruel failure! the process said:")
    print("#{process_return.stderr}")
end