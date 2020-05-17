#!/Users/omm/.opam/default/bin/liquidsoap -v

%include "passwords.liq"  # sets variable: icecastpassword

set("log.file.path","/tmp/simpletest.log")

show1 = playlist("/Users/omm/Radio Station/Music/Afterparty/")

radio1 = mksafe(show1)

out = output.icecast(%wav,
    host = "localhost", port=8050,
    password = "fat", mount = "test-harbor")

harborstream = input.harbor("test-harbor", port=8050, password="fat")

final = mksafe(harborstream)

output.icecast(%mp3(bitrate=192),
  host = "localhost", port = 8000,
  password = icecastpassword, mount = "basscadettest.mp3",
  name = "BASSCADETTEST", final)

out(radio1)
