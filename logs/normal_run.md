2024/12/27 21:36:19 [lang:3] STARTUP: loading stationconfig...
2024/12/27 21:36:19 [json.parse:3] You are parsing a JSON value without type annotation. This has confusing side-effects. Consider adding a type annotation: `let json.parse (x : ...) = ...`
2024/12/27 21:36:19 [lang.deprecated:2] WARNING: "string_of" is deprecated and will be removed in future version. Please use "string" instead.
2024/12/27 21:36:19 [lang:3] STARTUP: loading showconfig...
2024/12/27 21:36:19 [lang:3] STARTUP: loading show schedule...
2024/12/27 21:36:19 [lang:3] STARTUP: setting up switchable harbor...
2024/12/27 21:36:19 [lang:3] STARTUP: bootstrapping output to harbor with blank source...
2024/12/27 21:36:19 [lang:3] STARTUP: initiating AUTO-DJ...

2024/12/27 21:36:19 [main:3] User script loaded in 0.73 seconds.
2024/12/27 21:36:19 [frame:3] Using 44100Hz audio, 25Hz video, 44100Hz main.
2024/12/27 21:36:19 [frame:3] Video frame size set to: 1280x720
2024/12/27 21:36:19 [frame:3] Targeting 'frame.duration': 0.02s = 882 ticks.
2024/12/27 21:36:19 [sandbox:3] Sandboxing disabled
2024/12/27 21:36:19 [startup:3] DSSI plugins registration: 0.00s
2024/12/27 21:36:19 [startup:3] FFmpeg filters registration: 0.02s
2024/12/27 21:36:19 [startup:3] FFmpeg bitstream filters registration: 0.00s
2024/12/27 21:36:19 [startup:3] Lilv plugins registration: 0.00s
2024/12/27 21:36:19 [startup:3] Frei0r plugin registration: 0.00s
2024/12/27 21:36:19 [startup:3] LADSPA plugins registration: 0.00s
2024/12/27 21:36:19 [startup:3] main script hash computation: 0.03s
2024/12/27 21:36:19 [startup:3] main script cache retrieval: 0.03s
2024/12/27 21:36:19 [startup:3] stdlib hash computation: 0.03s
2024/12/27 21:36:19 [startup:3] Loading stdlib from cache!
2024/12/27 21:36:19 [startup:3] stdlib cache retrieval: 0.30s
2024/12/27 21:36:19 [startup:3] Typechecking main script: 0.02s
2024/12/27 21:36:19 [startup:3] Evaluating main script: 0.02s
2024/12/27 21:36:19 [clock:3] Starting clock generic with 4 source(s) and sync: auto
2024/12/27 21:36:19 [clock:3] Starting clock generic.2 with 2 source(s) and sync: auto
2024/12/27 21:36:19 [video.converter:3] Using preferred video converter: ffmpeg.
2024/12/27 21:36:19 [audio.converter:3] Using samplerate converter: libsamplerate.

2024/12/27 21:36:19 [lang:3]  *** AUTO-DJ: Updating current and next scheduled shows...
2024/12/27 21:36:19 [lang:3]     Getting first show of tomorrow's schedule...
2024/12/27 21:36:19 [lang:3]     Current show:  Hiphop
2024/12/27 21:36:19 [lang:3]     Next show:     Funky
2024/12/27 21:36:19 [lang:3]  *** AUTO-DJ: Starting up with... Hiphop
2024/12/27 21:36:19 [lang.deprecated:2] WARNING: "string_of" is deprecated and will be removed in future version. Please use "string" instead.
2024/12/27 21:36:19 [lang.deprecated:2] WARNING: "string_of" is deprecated and will be removed in future version. Please use "string" instead.
2024/12/27 21:36:19 [lang:3] Timed DJ command received:         ["change_show", "Hiphop"] with execution set to 0.0 seconds from now
2024/12/27 21:36:19 [video.text:3] Using sdl implementation
2024/12/27 21:36:19 [safe_blank:3] Content type is {audio=pcm(stereo)}.
2024/12/27 21:36:19 [internal_input_harbor:3] Content type is {audio=pcm(stereo)}.
2024/12/27 21:36:19 [harbor:3] Adding mountpoint '/broadcast-harbor' on port 8071
2024/12/27 21:36:19 [broadcast_source_from_harbor:3] Content type is {audio=pcm(stereo)}.
2024/12/27 21:36:19 [broadcast_output:3] Content type is {audio=pcm(stereo)}.
2024/12/27 21:36:19 [broadcast_output:3] Content type is {audio=pcm(stereo)}.
2024/12/27 21:36:19 [broadcast_source_from_harbor:3] Switch to safe_blank.
2024/12/27 21:36:19 [broadcast_output:3] Connecting mount sm2_test.mp3 for source@icecast...
2024/12/27 21:36:19 [blank.2:3] Content type is {audio=pcm(stereo)}.
2024/12/27 21:36:19 [output_to_harbor:3] Content type is {audio=pcm(stereo)}.
2024/12/27 21:36:19 [output_to_harbor:3] Content type is {audio=pcm(stereo)}.
2024/12/27 21:36:19 [output_to_harbor:3] Connecting mount broadcast-harbor for source@0.0.0.0...
2024/12/27 21:36:19 [broadcast_output:3] Connection setup was successful.
2024/12/27 21:36:19 [lang:3] Input harbor connected, with headers:
2024/12/27 21:36:19 [lang:3] [("Host", "0.0.0.0:8071"), ("ice-name", "broadcast-harbor"), ("Authorization", "Basic c291cmNlOmludGVybmFsX2hhcmJvcl9zZWNyZXQ2NTkwNTI2NA=="), ("ice-public", "1"), ("User-Agent", "Liquidsoap/2.3.0 (Unix; OCaml 4.14.2)"), ("ice-audio-info", " "), ("Content-Type", "application/ogg")]
2024/12/27 21:36:19 [internal_input_harbor:3] Decoding...
2024/12/27 21:36:19 [output_to_harbor:3] Connection setup was successful.
2024/12/27 21:36:19 [lang:3] PROCESSING DJ COMMAND: change_show - with argument: Hiphop
2024/12/27 21:36:19 [lang:3]   --- New show starting: Hiphop ------------------------------------
2024/12/27 21:36:19 [lang:3]    Shutting down current show....
2024/12/27 21:36:19 [lang:3]    New voice selected: Alex


2024/12/27 21:36:20 [lang:3]    Outputting new show: Hiphop
2024/12/27 21:36:20 [clock:3] Starting clock generic.3 with 15 source(s) and sync: auto
2024/12/27 21:36:20 [clock:3] Starting clock generic.child.child with 6 source(s) and sync: passive
2024/12/27 21:36:20 [safe_blank.2:3] Content type is {audio=pcm(stereo)}.
2024/12/27 21:36:20 [blank.6:3] Content type is {audio=pcm(stereo)}.
2024/12/27 21:36:20 [playover_source:3] Content type is {audio=pcm(stereo)}.
2024/12/27 21:36:20 [track_amplify:3] Content type is {audio=pcm(stereo)}.
2024/12/27 21:36:20 [fade_scale:3] Content type is {audio=pcm(stereo)}.
2024/12/27 21:36:20 [switch.4:3] Content type is {audio=pcm(stereo)}.
2024/12/27 21:36:20 [cross:3] Content type is {audio=pcm(stereo)}.
2024/12/27 21:36:20 [track_end_handler:3] Content type is {audio=pcm(stereo)}.
2024/12/27 21:36:20 [fadeout_instant_handler:3] Content type is {audio=pcm(stereo)}.
2024/12/27 21:36:20 [blank.4:3] Content type is {audio=pcm(stereo)}.
2024/12/27 21:36:20 [fadeout_trackend_handler:3] Content type is {audio=pcm(stereo)}.
2024/12/27 21:36:20 [blank.5:3] Content type is {audio=pcm(stereo)}.
2024/12/27 21:36:20 [scheduled_show_playlist:3] Content type is {audio=pcm(stereo)}.
2024/12/27 21:36:20 [track_metadata_deduplicate:3] Content type is {}.
2024/12/27 21:36:20 [metadata_deduplicate:3] Content type is {audio=pcm(stereo)}.
2024/12/27 21:36:20 [track_amplify.2:3] Content type is {audio=pcm(stereo)}.
2024/12/27 21:36:20 [fade_scale.2:3] Content type is {audio=pcm(stereo)}.
2024/12/27 21:36:20 [audio.add:3] Content type is {audio=pcm(stereo)}.
2024/12/27 21:36:20 [source.4:3] Content type is {audio=pcm(stereo)}.
2024/12/27 21:36:20 [switchboard_source:3] Content type is {audio=pcm(stereo)}.
2024/12/27 21:36:20 [output_to_harbor.2:3] Content type is {audio=pcm(stereo)}.
2024/12/27 21:36:20 [output_to_harbor.2:3] Content type is {audio=pcm(stereo)}.
2024/12/27 21:36:20 [switch.4:3] Switch to blank.6.
2024/12/27 21:36:20 [switchboard_source:3] Switch to source.4.
2024/12/27 21:36:20 [output_to_harbor.2:3] Connecting mount broadcast-harbor for source@0.0.0.0...
2024/12/27 21:36:20 [output_to_harbor.2:3] Connection setup was successful.
[mp3 @ 0xffff1c007740] Estimating duration from bitrate, this may be inaccurate
2024/12/27 21:36:20 [output_to_harbor.2:2] Error while sending data: could not write data to host: Unix.Unix_error(Unix.EPIPE, "write", "")!
2024/12/27 21:36:20 [output_to_harbor.2:3] Closing connection...
2024/12/27 21:36:20 [output_to_harbor.2:3] Will try to reconnect in 3.00 seconds.
[mp3 @ 0xffff1c007740] Estimating duration from bitrate, this may be inaccurate
2024/12/27 21:36:20 [decoder.ffmpeg:3] Requested content-type for "music/hiphop/02 Bleak.mp3": {audio=pcm(stereo)}
2024/12/27 21:36:20 [decoder.ffmpeg:3] FFmpeg recognizes "music/hiphop/02 Bleak.mp3" as audio: {codec: mp3, 44100Hz, 2 channel(s)}, video: {codec: mjpeg, 200x200, yuvj420p}
2024/12/27 21:36:20 [decoder.ffmpeg:3] Decoded content-type for "music/hiphop/02 Bleak.mp3": {audio=pcm(stereo)}
[mp3 @ 0xffff0c467d90] Estimating duration from bitrate, this may be inaccurate
[mp3 @ 0xffff0c467d90] Estimating duration from bitrate, this may be inaccurate
2024/12/27 21:36:20 [scheduled_show_playlist:3] Prepared "music/hiphop/02 Bleak.mp3" (RID 0).
2024/12/27 21:36:20 [fadeout_trackend_handler:3] Switch to scheduled_show_playlist.
2024/12/27 21:36:20 [fadeout_instant_handler:3] Switch to fadeout_trackend_handler.
2024/12/27 21:36:20 [cross.buffer:3] Content type is {audio=pcm(stereo)}.
2024/12/27 21:36:20 [lang:3]   - track change signal -
2024/12/27 21:36:20 [lang:3]   - track change signal -
[mp3 @ 0xffff1c007740] Estimating duration from bitrate, this may be inaccurate
[mp3 @ 0xffff1c007740] Estimating duration from bitrate, this may be inaccurate
2024/12/27 21:36:20 [decoder.ffmpeg:3] Requested content-type for "music/hiphop/05 Split Mind.mp3": {audio=pcm(stereo)}
2024/12/27 21:36:20 [decoder.ffmpeg:3] FFmpeg recognizes "music/hiphop/05 Split Mind.mp3" as audio: {codec: mp3, 44100Hz, 2 channel(s)}, video: {codec: mjpeg, 300x297, yuvj420p}
2024/12/27 21:36:20 [decoder.ffmpeg:3] Decoded content-type for "music/hiphop/05 Split Mind.mp3": {audio=pcm(stereo)}
2024/12/27 21:36:20 [lang:3] Input harbor disconnected
2024/12/27 21:36:20 [lang:3] OOPS: input harbor broke - stopped to force a reboot



2024/12/27 21:36:24 [output_to_harbor.2:3] Connecting mount broadcast-harbor for source@0.0.0.0...
2024/12/27 21:36:24 [internal_input_harbor:2] Feeding stopped: Ogg.End_of_stream.
2024/12/27 21:36:24 [lang:3] Input harbor disconnected
2024/12/27 21:36:24 [lang:3] Input harbor connected, with headers:
2024/12/27 21:36:24 [lang:3] [("Host", "0.0.0.0:8071"), ("ice-name", "broadcast-harbor"), ("Authorization", "Basic c291cmNlOmludGVybmFsX2hhcmJvcl9zZWNyZXQ2NTkwNTI2NA=="), ("ice-public", "1"), ("User-Agent", "Liquidsoap/2.3.0 (Unix; OCaml 4.14.2)"), ("ice-audio-info", " "), ("Content-Type", "application/ogg")]
2024/12/27 21:36:24 [internal_input_harbor:3] Decoding...



2024/12/27 21:36:43 [output_to_harbor:2] Error while sending data: could not write data to host: Unix.Unix_error(Unix.EPIPE, "write", "")!
2024/12/27 21:36:43 [output_to_harbor:3] Closing connection...
2024/12/27 21:36:43 [output_to_harbor:3] Will try to reconnect in 3.00 seconds.

2024/12/27 21:36:47 [output_to_harbor:3] Connecting mount broadcast-harbor for source@0.0.0.0...
2024/12/27 21:36:47 [output_to_harbor:3] Connection setup was successful.
2024/12/27 21:36:47 [output_to_harbor:2] Error while sending data: could not write data to host: Unix.Unix_error(Unix.EPIPE, "write", "")!
2024/12/27 21:36:47 [output_to_harbor:3] Closing connection...
2024/12/27 21:36:47 [output_to_harbor:3] Will try to reconnect in 3.00 seconds.

2024/12/27 21:36:51 [output_to_harbor:3] Connecting mount broadcast-harbor for source@0.0.0.0...
2024/12/27 21:36:51 [output_to_harbor:3] Connection setup was successful.
2024/12/27 21:36:51 [output_to_harbor:2] Error while sending data: could not write data to host: Unix.Unix_error(Unix.EPIPE, "write", "")!
2024/12/27 21:36:51 [output_to_harbor:3] Closing connection...
2024/12/27 21:36:51 [output_to_harbor:3] Will try to reconnect in 3.00 seconds.

2024/12/27 21:36:54 [internal_input_harbor:2] Error while reading from client: Timed out after waiting for 30.00 sec.
2024/12/27 21:36:54 [output_to_harbor.2:2] Connection failed: Cry.Timeout
2024/12/27 21:36:54 [output_to_harbor.2:3] Will try again in 3.00 sec.
2024/12/27 21:36:54 [clock.generic.3:2] We must catchup 30.00 seconds!
2024/12/27 21:36:54 [lang:3] Input harbor disconnected
2024/12/27 21:36:54 [internal_input_harbor:2] Feeding stopped: Ogg.End_of_stream.
2024/12/27 21:36:54 [lang:3] Input harbor disconnected

2024/12/27 21:36:55 [output_to_harbor:3] Connecting mount broadcast-harbor for source@0.0.0.0...
2024/12/27 21:36:55 [output_to_harbor:3] Connection setup was successful.
2024/12/27 21:36:55 [lang:3] Input harbor connected, with headers:
2024/12/27 21:36:55 [lang:3] [("Host", "0.0.0.0:8071"), ("ice-name", "broadcast-harbor"), ("Authorization", "Basic c291cmNlOmludGVybmFsX2hhcmJvcl9zZWNyZXQ2NTkwNTI2NA=="), ("ice-public", "1"), ("User-Agent", "Liquidsoap/2.3.0 (Unix; OCaml 4.14.2)"), ("ice-audio-info", " "), ("Content-Type", "application/ogg")]
2024/12/27 21:36:55 [internal_input_harbor:3] Decoding...

2024/12/27 21:36:58 [output_to_harbor.2:3] Connecting mount broadcast-harbor for source@0.0.0.0...
2024/12/27 21:36:58 [output_to_harbor.2:3] Connection setup was successful.
2024/12/27 21:36:58 [output_to_harbor.2:2] Error while sending data: could not write data to host: Unix.Unix_error(Unix.EPIPE, "write", "")!
2024/12/27 21:36:58 [output_to_harbor.2:3] Closing connection...
2024/12/27 21:36:58 [output_to_harbor.2:3] Will try to reconnect in 3.00 seconds.

2024/12/27 21:37:02 [output_to_harbor.2:3] Connecting mount broadcast-harbor for source@0.0.0.0...
2024/12/27 21:37:02 [output_to_harbor.2:3] Connection setup was successful.
2024/12/27 21:37:02 [output_to_harbor.2:2] Error while sending data: could not write data to host: Unix.Unix_error(Unix.EPIPE, "write", "")!
2024/12/27 21:37:02 [output_to_harbor.2:3] Closing connection...
2024/12/27 21:37:02 [output_to_harbor.2:3] Will try to reconnect in 3.00 seconds.
2024/12/27 21:37:06 [output_to_harbor.2:3] Connecting mount broadcast-harbor for source@0.0.0.0...
2024/12/27 21:37:06 [output_to_harbor.2:3] Connection setup was successful.
2024/12/27 21:37:06 [output_to_harbor.2:2] Error while sending data: could not write data to host: Unix.Unix_error(Unix.EPIPE, "write", "")!
2024/12/27 21:37:06 [output_to_harbor.2:3] Closing connection...
2024/12/27 21:37:06 [output_to_harbor.2:3] Will try to reconnect in 3.00 seconds.
2024/12/27 21:37:10 [output_to_harbor.2:3] Connecting mount broadcast-harbor for source@0.0.0.0...
2024/12/27 21:37:10 [output_to_harbor.2:3] Connection setup was successful.
2024/12/27 21:37:10 [output_to_harbor.2:2] Error while sending data: could not write data to host: Unix.Unix_error(Unix.EPIPE, "write", "")!
2024/12/27 21:37:10 [output_to_harbor.2:3] Closing connection...
2024/12/27 21:37:10 [output_to_harbor.2:3] Will try to reconnect in 3.00 seconds.
2024/12/27 21:37:14 [output_to_harbor.2:3] Connecting mount broadcast-harbor for source@0.0.0.0...
2024/12/27 21:37:14 [output_to_harbor.2:3] Connection setup was successful.
2024/12/27 21:37:14 [output_to_harbor.2:2] Error while sending data: could not write data to host: Unix.Unix_error(Unix.EPIPE, "write", "")!
2024/12/27 21:37:14 [output_to_harbor.2:3] Closing connection...
2024/12/27 21:37:14 [output_to_harbor.2:3] Will try to reconnect in 3.00 seconds.
2024/12/27 21:37:18 [output_to_harbor.2:3] Connecting mount broadcast-harbor for source@0.0.0.0...
2024/12/27 21:37:18 [output_to_harbor.2:3] Connection setup was successful.
2024/12/27 21:37:18 [output_to_harbor.2:2] Error while sending data: could not write data to host: Unix.Unix_error(Unix.EPIPE, "write", "")!
2024/12/27 21:37:18 [output_to_harbor.2:3] Closing connection...
2024/12/27 21:37:18 [output_to_harbor.2:3] Will try to reconnect in 3.00 seconds.
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 884736)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/27 21:37:18 [broadcast_source_from_harbor:3] Switch to internal_input_harbor with transition.
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 885214)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 885214)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 884332)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 885214)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 885214)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/27 21:37:18 [internal_input_harbor:2] Generator max buffered length exceeded (882000 < 886096)! Dropping content..
2024/12/27 21:37:22 [output_to_harbor.2:3] Connecting mount broadcast-harbor for source@0.0.0.0...
2024/12/27 21:37:22 [output_to_harbor.2:3] Connection setup was successful.
2024/12/27 21:37:22 [output_to_harbor.2:2] Error while sending data: could not write data to host: Unix.Unix_error(Unix.EPIPE, "write", "")!
2024/12/27 21:37:22 [output_to_harbor.2:3] Closing connection...
2024/12/27 21:37:22 [output_to_harbor.2:3] Will try to reconnect in 3.00 seconds.
2024/12/27 21:37:26 [output_to_harbor.2:3] Connecting mount broadcast-harbor for source@0.0.0.0...
2024/12/27 21:37:26 [output_to_harbor.2:3] Connection setup was successful.
2024/12/27 21:37:26 [output_to_harbor.2:2] Error while sending data: could not write data to host: Unix.Unix_error(Unix.EPIPE, "write", "")!
2024/12/27 21:37:26 [output_to_harbor.2:3] Closing connection...
2024/12/27 21:37:26 [output_to_harbor.2:3] Will try to reconnect in 3.00 seconds.
2024/12/27 21:37:30 [output_to_harbor.2:3] Connecting mount broadcast-harbor for source@0.0.0.0...
2024/12/27 21:37:30 [output_to_harbor.2:3] Connection setup was successful.
2024/12/27 21:37:30 [output_to_harbor.2:2] Error while sending data: could not write data to host: Unix.Unix_error(Unix.EPIPE, "write", "")!
2024/12/27 21:37:30 [output_to_harbor.2:3] Closing connection...
2024/12/27 21:37:30 [output_to_harbor.2:3] Will try to reconnect in 3.00 seconds.