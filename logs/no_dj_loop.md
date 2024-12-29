2024/12/28 05:09:26 [lang:3] STARTUP: loading stationconfig...
2024/12/28 05:09:26 [json.parse:3] You are parsing a JSON value without type annotation. This has confusing side-effects. Consider adding a type annotation: `let json.parse (x : ...) = ...`
2024/12/28 05:09:26 [lang.deprecated:2] WARNING: "string_of" is deprecated and will be removed in future version. Please use "string" instead.
2024/12/28 05:09:26 [lang:3] STARTUP: loading showconfig...
2024/12/28 05:09:26 [lang:3] STARTUP: loading show schedule...
2024/12/28 05:09:26 [lang:3] STARTUP: setting up switchable harbor...
2024/12/28 05:09:26 [lang:3] STARTUP: setting up bootstrap output to harbor with blank source...
2024/12/28 05:09:26 [lang:3] STARTUP: initiating AUTO-DJ...

LS DOES END OF SCRIPT STUFF BEFORE STARTING UP SOURCES

2024/12/28 05:09:26 [main:3] User script loaded in 0.69 seconds.
2024/12/28 05:09:26 [frame:3] Using 44100Hz audio, 25Hz video, 44100Hz main.
2024/12/28 05:09:26 [frame:3] Video frame size set to: 1280x720
2024/12/28 05:09:26 [frame:3] Targeting 'frame.duration': 0.02s = 882 ticks.
2024/12/28 05:09:26 [sandbox:3] Sandboxing disabled
2024/12/28 05:09:26 [startup:3] DSSI plugins registration: 0.00s
2024/12/28 05:09:26 [startup:3] FFmpeg filters registration: 0.02s
2024/12/28 05:09:26 [startup:3] FFmpeg bitstream filters registration: 0.00s
2024/12/28 05:09:26 [startup:3] Lilv plugins registration: 0.00s
2024/12/28 05:09:26 [startup:3] Frei0r plugin registration: 0.00s
2024/12/28 05:09:26 [startup:3] LADSPA plugins registration: 0.00s
2024/12/28 05:09:26 [startup:3] main script hash computation: 0.03s
2024/12/28 05:09:26 [startup:3] main script cache retrieval: 0.03s
2024/12/28 05:09:26 [startup:3] stdlib hash computation: 0.03s
2024/12/28 05:09:26 [startup:3] Loading stdlib from cache!
2024/12/28 05:09:26 [startup:3] stdlib cache retrieval: 0.28s
2024/12/28 05:09:26 [startup:3] Typechecking main script: 0.02s
2024/12/28 05:09:26 [startup:3] Evaluating main script: 0.02s
2024/12/28 05:09:26 [clock:3] Starting clock generic with 4 source(s) and sync: auto
2024/12/28 05:09:26 [clock:3] Starting clock generic.2 with 2 source(s) and sync: auto
2024/12/28 05:09:26 [video.converter:3] Using preferred video converter: ffmpeg.
2024/12/28 05:09:26 [audio.converter:3] Using samplerate converter: libsamplerate.
2024/12/28 05:09:26 [video.text:3] Using sdl implementation
2024/12/28 05:09:26 [blank.2:3] Content type is {audio=pcm(stereo)}.

REAL STARTUP OF SOURCES BEGINS

2024/12/28 05:09:26 [output_to_harbor:3] Content type is {audio=pcm(stereo)}.
2024/12/28 05:09:26 [output_to_harbor:3] Content type is {audio=pcm(stereo)}.
2024/12/28 05:09:26 [safe_blank:3] Content type is {audio=pcm(stereo)}.
2024/12/28 05:09:26 [internal_input_harbor:3] Content type is {audio=pcm(stereo)}.
2024/12/28 05:09:26 [harbor:3] Adding mountpoint '/broadcast-harbor' on port 8061
2024/12/28 05:09:26 [broadcast_source_from_harbor:3] Content type is {audio=pcm(stereo)}.
2024/12/28 05:09:26 [broadcast_output:3] Content type is {audio=pcm(stereo)}.
2024/12/28 05:09:26 [broadcast_output:3] Content type is {audio=pcm(stereo)}.
2024/12/28 05:09:26 [broadcast_source_from_harbor:3] Switch to safe_blank.
2024/12/28 05:09:26 [broadcast_output:3] Connecting mount sm2_test.mp3 for source@icecast...
2024/12/28 05:09:26 [output_to_harbor:3] Connecting mount broadcast-harbor for source@0.0.0.0...
2024/12/28 05:09:26 [output_to_harbor:3] Connection setup was successful.
2024/12/28 05:09:26 [lang:3] Input harbor connected, with headers:
2024/12/28 05:09:26 [lang:3] [("Host", "0.0.0.0:8061"), ("ice-name", "broadcast-harbor"), ("Authorization", "Basic c291cmNlOmludGVybmFsX2hhcmJvcl9zZWNyZXQxMzgzODA3NTQ="), ("ice-public", "1"), ("User-Agent", "Liquidsoap/2.3.0 (Unix; OCaml 4.14.2)"), ("ice-audio-info", " "), ("Content-Type", "application/ogg")]
2024/12/28 05:09:26 [internal_input_harbor:3] Decoding...
2024/12/28 05:09:26 [broadcast_output:3] Connection setup was successful.

.... 14 SECONDS ELAPSES with broadcast_source_from_harbor on safe_blank ....

2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 884736)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:09:50 [broadcast_source_from_harbor:3] Switch to internal_input_harbor with transition.

.... 20 SECONDS ELAPSES with broadcast_source_from_harbor on the actual internal_input_harbor ....

2024/12/28 05:10:10 [broadcast_source_from_harbor:3] Switch to safe_blank with transition.

???? SWITCHES BACK TO safe_blank, FOR 4 SECONDS ????

2024/12/28 05:10:14 [broadcast_source_from_harbor:3] Switch to internal_input_harbor with transition.
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 883854)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 884332)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 885214)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/28 05:10:14 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..