#!/Users/omm/.opam/default/bin/liquidsoap -v

set("server.telnet",true)

set("log.file.path","/tmp/simpletest.log")

playover_source = audio_to_stereo(request.queue(id="playover_source"))

radio = smooth_add(delay=30.0, p=0.2, special=playover_source, normal=
    mksafe(playlist("/Users/omm/Radio Station/Music/Afterparty/"))
    )

output.icecast(%mp3(bitrate=192),
  host = "localhost", port = 8000,
  password = "GUEvoN3gKVKc9vwW", mount = "basscadettest.mp3",
  name = "BASSCADETTEST", radio)
