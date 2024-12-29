WITH A 20 SECOND WAIT FROM BOOTSTRAPPING WITH "FUNKY" TO ACTUALLY STARTING THE DJ LOOP

2024/12/28 16:24:52 [lang:3] STARTUP: loading stationconfig...
2024/12/28 16:24:52 [json.parse:3] You are parsing a JSON value without type annotation. This has confusing side-effects. Consider adding a type annotation: `let json.parse (x : ...) = ...`
2024/12/28 16:24:52 [lang.deprecated:2] WARNING: "string_of" is deprecated and will be removed in future version. Please use "string" instead.
2024/12/28 16:24:52 [lang:3] STARTUP: loading showconfig...
2024/12/28 16:24:52 [lang:3] STARTUP: loading show schedule...
2024/12/28 16:24:52 [lang:3] STARTUP: setting up switchable harbor...
2024/12/28 16:24:52 [lang:3] STARTUP: setting up bootstrap output to harbor with blank source...
2024/12/28 16:24:52 [lang:3] STARTUP: initiating AUTO-DJ...
2024/12/28 16:24:52 [main:3] User script loaded in 0.69 seconds.
2024/12/28 16:24:52 [frame:3] Using 44100Hz audio, 25Hz video, 44100Hz main.
2024/12/28 16:24:52 [frame:3] Video frame size set to: 1280x720
2024/12/28 16:24:52 [frame:3] Targeting 'frame.duration': 0.02s = 882 ticks.
2024/12/28 16:24:52 [sandbox:3] Sandboxing disabled
2024/12/28 16:24:52 [startup:3] DSSI plugins registration: 0.00s
2024/12/28 16:24:52 [startup:3] FFmpeg filters registration: 0.02s
2024/12/28 16:24:52 [startup:3] FFmpeg bitstream filters registration: 0.00s
2024/12/28 16:24:52 [startup:3] Lilv plugins registration: 0.00s
2024/12/28 16:24:52 [startup:3] Frei0r plugin registration: 0.00s
2024/12/28 16:24:52 [startup:3] LADSPA plugins registration: 0.00s
2024/12/28 16:24:52 [startup:3] main script hash computation: 0.04s
2024/12/28 16:24:52 [startup:3] main script cache retrieval: 0.04s
2024/12/28 16:24:52 [startup:3] stdlib hash computation: 0.04s
2024/12/28 16:24:52 [startup:3] Loading stdlib from cache!
2024/12/28 16:24:52 [startup:3] stdlib cache retrieval: 0.26s
2024/12/28 16:24:52 [startup:3] Typechecking main script: 0.02s
2024/12/28 16:24:52 [startup:3] Evaluating main script: 0.02s
2024/12/28 16:24:52 [clock:3] Starting clock generic with 4 source(s) and sync: auto
2024/12/28 16:24:52 [clock:3] Starting clock generic.2 with 4 source(s) and sync: auto
2024/12/28 16:24:52 [safe_blank:3] Content type is {audio=pcm(stereo)}.
2024/12/28 16:24:52 [internal_input_harbor:3] Content type is {audio=pcm(stereo)}.
2024/12/28 16:24:52 [harbor:3] Adding mountpoint '/broadcast-harbor' on port 8061
2024/12/28 16:24:52 [broadcast_source_from_harbor:3] Content type is {audio=pcm(stereo)}.
2024/12/28 16:24:52 [broadcast_output:3] Content type is {audio=pcm(stereo)}.
2024/12/28 16:24:52 [broadcast_output:3] Content type is {audio=pcm(stereo)}.
2024/12/28 16:24:52 [broadcast_source_from_harbor:3] Switch to safe_blank.
2024/12/28 16:24:52 [broadcast_output:3] Connecting mount sm2_test.mp3 for source@icecast...
2024/12/28 16:24:52 [video.converter:3] Using preferred video converter: ffmpeg.
2024/12/28 16:24:52 [audio.converter:3] Using samplerate converter: libsamplerate.
2024/12/28 16:24:52 [safe_blank.2:3] Content type is {audio=pcm(stereo)}.
2024/12/28 16:24:52 [funky:3] Content type is {audio=pcm(stereo)}.
2024/12/28 16:24:52 [mksafe:3] Content type is {audio=pcm(stereo)}.
2024/12/28 16:24:52 [output_to_harbor:3] Content type is {audio=pcm(stereo)}.
2024/12/28 16:24:52 [output_to_harbor:3] Content type is {audio=pcm(stereo)}.
2024/12/28 16:24:52 [mksafe:3] Switch to safe_blank.2.
2024/12/28 16:24:52 [broadcast_output:3] Connection setup was successful.
2024/12/28 16:24:52 [output_to_harbor:3] Connecting mount broadcast-harbor for source@0.0.0.0...
2024/12/28 16:24:52 [video.text:3] Using sdl implementation
2024/12/28 16:24:52 [lang:3]    >>> Input harbor CONNECTED, with headers:
2024/12/28 16:24:52 [lang:3] [("Host", "0.0.0.0:8061"), ("ice-name", "broadcast-harbor"), ("Authorization", "Basic c291cmNlOmludGVybmFsX2hhcmJvcl9zZWNyZXQxNTUyMzQzODY="), ("ice-public", "1"), ("User-Agent", "Liquidsoap/2.3.0 (Unix; OCaml 4.14.2)"), ("ice-audio-info", " "), ("Content-Type", "application/ogg")]
2024/12/28 16:24:52 [internal_input_harbor:3] Decoding...
2024/12/28 16:24:52 [output_to_harbor:3] Connection setup was successful.
[mp3 @ 0xffff44006c70] Estimating duration from bitrate, this may be inaccurate
[mp3 @ 0xffff44006c70] Estimating duration from bitrate, this may be inaccurate
2024/12/28 16:24:52 [decoder.ffmpeg:3] Requested content-type for "music/funky/10 Mutowa.mp3": {audio=pcm(stereo)}
2024/12/28 16:24:52 [decoder.ffmpeg:3] FFmpeg recognizes "music/funky/10 Mutowa.mp3" as audio: {codec: mp3, 44100Hz, 2 channel(s)}, video: {codec: mjpeg, 1200x1200, yuvj444p}
2024/12/28 16:24:52 [decoder.ffmpeg:3] Decoded content-type for "music/funky/10 Mutowa.mp3": {audio=pcm(stereo)}
[mp3 @ 0xffff3c095fe0] Estimating duration from bitrate, this may be inaccurate
[mp3 @ 0xffff3c095fe0] Estimating duration from bitrate, this may be inaccurate
2024/12/28 16:24:52 [funky:3] Prepared "music/funky/10 Mutowa.mp3" (RID 0).
2024/12/28 16:24:52 [mksafe:3] Switch to funky with transition.
[mp3 @ 0xffff44006c70] Estimating duration from bitrate, this may be inaccurate
[mp3 @ 0xffff44006c70] Estimating duration from bitrate, this may be inaccurate
2024/12/28 16:24:53 [decoder.ffmpeg:3] Requested content-type for "music/funky/03 Reverse Of The Void.mp3": {audio=pcm(stereo)}
2024/12/28 16:24:53 [decoder.ffmpeg:3] FFmpeg recognizes "music/funky/03 Reverse Of The Void.mp3" as audio: {codec: mp3, 44100Hz, 2 channel(s)}, video: {codec: mjpeg, 200x200, yuvj420p}
2024/12/28 16:24:53 [decoder.ffmpeg:3] Decoded content-type for "music/funky/03 Reverse Of The Void.mp3": {audio=pcm(stereo)}

SWITCH AWAY FROM BLANK BECAUSE AUDIO IS NOW COMING THROUGH FROM THE INPUT HARBOR

2024/12/28 16:25:04 [broadcast_source_from_harbor:3] Switch to internal_input_harbor with transition.

WAITING for DJ LOOP TO START ....

2024/12/28 16:25:12 [lang:3]  *** AUTO-DJ: Updating current and next scheduled shows...
2024/12/28 16:25:12 [lang:3]     Getting first show of tomorrow's schedule...
2024/12/28 16:25:12 [lang:3]     Current show:  Hiphop
2024/12/28 16:25:12 [lang:3]     Next show:     Funky
2024/12/28 16:25:12 [lang:3]  *** AUTO-DJ: Starting up with... Hiphop
2024/12/28 16:25:12 [lang.deprecated:2] WARNING: "string_of" is deprecated and will be removed in future version. Please use "string" instead.
2024/12/28 16:25:12 [lang.deprecated:2] WARNING: "string_of" is deprecated and will be removed in future version. Please use "string" instead.
2024/12/28 16:25:12 [lang:3] Timed DJ command received:         ["change_show", "Hiphop"] with execution set to 0.0 seconds from now
2024/12/28 16:25:12 [lang:3] PROCESSING DJ COMMAND: change_show - with argument: Hiphop
2024/12/28 16:25:12 [lang:3]   --- New show starting: Hiphop ------------------------------------
2024/12/28 16:25:12 [lang:3]    Shutting down current show....
2024/12/28 16:25:12 [lang:3]    New voice selected: Alex
2024/12/28 16:25:13 [lang:3]    Outputting new show: Hiphop
2024/12/28 16:25:13 [clock:3] Starting clock generic.3 with 16 source(s) and sync: auto
2024/12/28 16:25:13 [clock:3] Starting clock generic.child.child with 5 source(s) and sync: passive
2024/12/28 16:25:13 [safe_blank.3:3] Content type is {audio=pcm(stereo)}.
2024/12/28 16:25:13 [blank.6:3] Content type is {audio=pcm(stereo)}.
2024/12/28 16:25:13 [playover_source:3] Content type is {audio=pcm(stereo)}.
2024/12/28 16:25:13 [track_amplify:3] Content type is {audio=pcm(stereo)}.
2024/12/28 16:25:13 [fade_scale:3] Content type is {audio=pcm(stereo)}.
2024/12/28 16:25:13 [switch.5:3] Content type is {audio=pcm(stereo)}.
2024/12/28 16:25:13 [cross:3] Content type is {audio=pcm(stereo)}.
2024/12/28 16:25:13 [fadeout_instant_handler:3] Content type is {audio=pcm(stereo)}.
2024/12/28 16:25:13 [blank.4:3] Content type is {audio=pcm(stereo)}.
2024/12/28 16:25:13 [fadeout_trackend_handler:3] Content type is {audio=pcm(stereo)}.
2024/12/28 16:25:13 [blank.5:3] Content type is {audio=pcm(stereo)}.
2024/12/28 16:25:13 [scheduled_show_playlist:3] Content type is {audio=pcm(stereo)}.
2024/12/28 16:25:13 [track_metadata_deduplicate:3] Content type is {}.
2024/12/28 16:25:13 [metadata_deduplicate:3] Content type is {audio=pcm(stereo)}.
2024/12/28 16:25:13 [track_amplify.2:3] Content type is {audio=pcm(stereo)}.
2024/12/28 16:25:13 [fade_scale.2:3] Content type is {audio=pcm(stereo)}.
2024/12/28 16:25:13 [audio.add:3] Content type is {audio=pcm(stereo)}.
2024/12/28 16:25:13 [source.4:3] Content type is {audio=pcm(stereo)}.
2024/12/28 16:25:13 [track_end_handler:3] Content type is {audio=pcm(stereo)}.
2024/12/28 16:25:13 [switchboard_source:3] Content type is {audio=pcm(stereo)}.
2024/12/28 16:25:13 [output_to_harbor.2:3] Content type is {audio=pcm(stereo)}.
2024/12/28 16:25:13 [output_to_harbor.2:3] Content type is {audio=pcm(stereo)}.
2024/12/28 16:25:13 [switch.5:3] Switch to blank.6.
[mp3 @ 0xffff5c006ef0] Estimating duration from bitrate, this may be inaccurate
2024/12/28 16:25:13 [switchboard_source:3] Switch to track_end_handler.

AND HERE WE'RE TRYING TO STREAM TO THE INPUT HARBOR, BUT THE OTHER SOURCE NEVER DISCONNECTED.

2024/12/28 16:25:13 [output_to_harbor.2:3] Connecting mount broadcast-harbor for source@0.0.0.0...
2024/12/28 16:25:13 [output_to_harbor.2:3] Connection setup was successful.
2024/12/28 16:25:13 [output_to_harbor.2:2] Error while sending data: could not write data to host: Unix.Unix_error(Unix.EPIPE, "write", "")!
2024/12/28 16:25:13 [output_to_harbor.2:3] Closing connection...
2024/12/28 16:25:13 [output_to_harbor.2:3] Will try to reconnect in 3.00 seconds.
[mp3 @ 0xffff5c006ef0] Estimating duration from bitrate, this may be inaccurate
2024/12/28 16:25:13 [decoder.ffmpeg:3] Requested content-type for "music/hiphop/03 Retransmission.mp3": {audio=pcm(stereo)}
2024/12/28 16:25:13 [decoder.ffmpeg:3] FFmpeg recognizes "music/hiphop/03 Retransmission.mp3" as audio: {codec: mp3, 44100Hz, 2 channel(s)}, video: {codec: mjpeg, 300x297, yuvj420p}
2024/12/28 16:25:13 [decoder.ffmpeg:3] Decoded content-type for "music/hiphop/03 Retransmission.mp3": {audio=pcm(stereo)}
[mp3 @ 0xffff90092070] Estimating duration from bitrate, this may be inaccurate
[mp3 @ 0xffff90092070] Estimating duration from bitrate, this may be inaccurate
2024/12/28 16:25:13 [scheduled_show_playlist:3] Prepared "music/hiphop/03 Retransmission.mp3" (RID 2).
2024/12/28 16:25:13 [fadeout_trackend_handler:3] Switch to scheduled_show_playlist.
2024/12/28 16:25:13 [fadeout_instant_handler:3] Switch to fadeout_trackend_handler.
2024/12/28 16:25:13 [cross.buffer:3] Content type is {audio=pcm(stereo)}.
[mp3 @ 0xffff48007080] Estimating duration from bitrate, this may be inaccurate
[mp3 @ 0xffff48007080] Estimating duration from bitrate, this may be inaccurate
2024/12/28 16:25:13 [decoder.ffmpeg:3] Requested content-type for "music/hiphop/02 Judgement Day.mp3": {audio=pcm(stereo)}
2024/12/28 16:25:13 [decoder.ffmpeg:3] FFmpeg recognizes "music/hiphop/02 Judgement Day.mp3" as audio: {codec: mp3, 44100Hz, 2 channel(s)}, video: {codec: mjpeg, 300x297, yuvj420p}
2024/12/28 16:25:13 [decoder.ffmpeg:3] Decoded content-type for "music/hiphop/02 Judgement Day.mp3": {audio=pcm(stereo)}
2024/12/28 16:25:17 [output_to_harbor.2:3] Connecting mount broadcast-harbor for source@0.0.0.0...
2024/12/28 16:25:17 [output_to_harbor.2:3] Connection setup was successful.
2024/12/28 16:25:17 [output_to_harbor.2:2] Error while sending data: could not write data to host: Unix.Unix_error(Unix.EPIPE, "write", "")!
2024/12/28 16:25:17 [output_to_harbor.2:3] Closing connection...
2024/12/28 16:25:17 [output_to_harbor.2:3] Will try to reconnect in 3.00 seconds.
2024/12/28 16:25:21 [output_to_harbor.2:3] Connecting mount broadcast-harbor for source@0.0.0.0...
2024/12/28 16:25:21 [output_to_harbor.2:3] Connection setup was successful.
2024/12/28 16:25:21 [output_to_harbor.2:2] Error while sending data: could not write data to host: Unix.Unix_error(Unix.EPIPE, "write", "")!
2024/12/28 16:25:21 [output_to_harbor.2:3] Closing connection...
2024/12/28 16:25:21 [output_to_harbor.2:3] Will try to reconnect in 3.00 seconds.
2024/12/28 16:25:25 [output_to_harbor.2:3] Connecting mount broadcast-harbor for source@0.0.0.0...
2024/12/28 16:25:25 [output_to_harbor.2:3] Connection setup was successful.
2024/12/28 16:25:25 [output_to_harbor.2:2] Error while sending data: could not write data to host: Unix.Unix_error(Unix.EPIPE, "write", "")!
2024/12/28 16:25:25 [output_to_harbor.2:3] Closing connection...
2024/12/28 16:25:25 [output_to_harbor.2:3] Will try to reconnect in 3.00 seconds.
2024/12/28 16:25:29 [output_to_harbor.2:3] Connecting mount broadcast-harbor for source@0.0.0.0...
2024/12/28 16:25:29 [output_to_harbor.2:3] Connection setup was successful.
2024/12/28 16:25:29 [output_to_harbor.2:2] Error while sending data: could not write data to host: Unix.Unix_error(Unix.EPIPE, "write", "")!
2024/12/28 16:25:29 [output_to_harbor.2:3] Closing connection...
2024/12/28 16:25:29 [output_to_harbor.2:3] Will try to reconnect in 3.00 seconds.
2024/12/28 16:25:33 [output_to_harbor.2:3] Connecting mount broadcast-harbor for source@0.0.0.0...
2024/12/28 16:25:33 [output_to_harbor.2:3] Connection setup was successful.
2024/12/28 16:25:33 [output_to_harbor.2:2] Error while sending data: could not write data to host: Unix.Unix_error(Unix.EPIPE, "write", "")!
2024/12/28 16:25:33 [output_to_harbor.2:3] Closing connection...
2024/12/28 16:25:33 [output_to_harbor.2:3] Will try to reconnect in 3.00 seconds.
2024/12/28 16:25:36 [clock.generic:2] We must catchup 0.22 seconds!
2024/12/28 16:25:36 [clock.generic.2:2] We must catchup 0.54 seconds!
2024/12/28 16:25:36 [clock.generic.3:2] We must catchup 0.45 seconds!
2024/12/28 16:25:37 [output_to_harbor.2:3] Connecting mount broadcast-harbor for source@0.0.0.0...
2024/12/28 16:25:37 [output_to_harbor.2:3] Connection setup was successful.
2024/12/28 16:25:37 [output_to_harbor.2:2] Error while sending data: could not write data to host: Unix.Unix_error(Unix.EPIPE, "write", "")!
2024/12/28 16:25:37 [output_to_harbor.2:3] Closing connection...
2024/12/28 16:25:37 [output_to_harbor.2:3] Will try to reconnect in 3.00 seconds.
2024/12/28 16:25:41 [output_to_harbor.2:3] Connecting mount broadcast-harbor for source@0.0.0.0...
2024/12/28 16:25:41 [output_to_harbor.2:3] Connection setup was successful.
2024/12/28 16:25:41 [output_to_harbor.2:2] Error while sending data: could not write data to host: Unix.Unix_error(Unix.EPIPE, "write", "")!
2024/12/28 16:25:41 [output_to_harbor.2:3] Closing connection...
2024/12/28 16:25:41 [output_to_harbor.2:3] Will try to reconnect in 3.00 seconds.
2024/12/28 16:25:45 [output_to_harbor.2:3] Connecting mount broadcast-harbor for source@0.0.0.0...
2024/12/28 16:25:45 [output_to_harbor.2:3] Connection setup was successful.
2024/12/28 16:25:45 [output_to_harbor.2:2] Error while sending data: could not write data to host: Unix.Unix_error(Unix.EPIPE, "write", "")!
2024/12/28 16:25:45 [output_to_harbor.2:3] Closing connection...
2024/12/28 16:25:45 [output_to_harbor.2:3] Will try to reconnect in 3.00 seconds.