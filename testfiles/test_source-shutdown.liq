#!/Users/omm/.opam/default/bin/liquidsoap -v

%include "passwords.liq"  # sets variable: icecastpassword

set("log.file.path","/tmp/simpletest.log")

radio1 = mksafe(playlist("/Users/omm/Radio Station/Music/Afterparty/"))

out = output.icecast(%wav,
    host = "localhost", port=8050,
    password = "fat", mount = "test-harbor")

harborstream = input.harbor("test-harbor", port=8050, password="fat")

final = mksafe(harborstream)

output.icecast(%mp3(bitrate=192),
  host = "localhost", port = 8000,
  password = icecastpassword, mount = "basscadettest.mp3",
  name = "BASSCADETTEST", final)

# ----

sourcelist = ref []

s = out(radio1)

sourcelist := [s]

def switchit () =
    newshow = mksafe(playlist("/Users/omm/Radio Station/Music/Bump in the Trunk"))
    list.iter(source.shutdown, !sourcelist)
    s = out(newshow)
    sourcelist := [s]
    -1.0
end

add_timeout(10.0, switchit)
