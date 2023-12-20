#!/Users/omm/.opam/default/bin/liquidsoap -v

set("log.file.path","/tmp/simpletest.log")

settings.init.force_start.set(true) # supposedly required to be able to start without an active source
settings.server.telnet.set(true) # to create test commands - would be replaced by DJ bot logic


show1 = playlist("/Users/omm/Radio Station/Music/Afterparty/")

radio1 = mksafe(show1)

out = output.icecast(%wav,
    host = "localhost", port=8050,
    password = "fat", mount = "test-harbor", radio1)

harborstream = input.harbor("test-harbor", port=8050, password="fat")

final = mksafe(harborstream)

output.icecast(%mp3(bitrate=192),
  host = "localhost", port = 8000,
  password = "GUEvoN3gKVKc9vwW", mount = "basscadettest.mp3",
  name = "BASSCADETTEST", final)

# out(radio1)
