#!/Users/omm/.opam/default/bin/liquidsoap -v

set("log.file.path","/tmp/simpletest.log")

source = mksafe(playlist("/Users/omm/BasscadetMusic/Matt/Afterparty/"))

out = output.icecast(%mp3(bitrate=192),
    host = "localhost", port = 8000,
    password = "GUEvoN3gKVKc9vwW", mount = "basscadettest.mp3",
    name = "BASSCADETTEST", source) 