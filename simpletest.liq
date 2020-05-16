#!/Users/omm/.opam/default/bin/liquidsoap -v

%include "passwords.liq"  # sets variable: icecastpassword

set("log.file.path","/tmp/simpletest.log")

show1 = playlist("/Users/omm/Radio Station/Music/Afterparty/")
show2 = playlist("/Users/omm/Radio Station/Music/Braindance/")

radio = mksafe(crossfade(show1))
radio2 = mksafe(crossfade(show2))

currentshow = ref radio

broadcast = output.icecast(%mp3(bitrate=192),
  host = "localhost", port = 8000,
  password = icecastpassword, mount = "basscadettest.mp3",
  name = "BASSCADETTEST")

def doit () =
  output = broadcast(!currentshow)
  15.0
end

switchdelay = doit()

currentshow := radio2

add_timeout(switchdelay, doit)
