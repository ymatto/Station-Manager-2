#!/Users/omm/.opam/default/bin/liquidsoap -v

%include "passwords.liq"  # sets variable: icecastpassword

set("log.file.path","/tmp/simpletest.log")

show1 = playlist("/Users/omm/Radio Station/Music/Afterparty/")
show2 = playlist("/Users/omm/Radio Station/Music/Laid Back Hip-Hop/")

radio = mksafe(crossfade(show1))
radio2 = mksafe(crossfade(show2))

out = output.icecast(%wav,
      host = "localhost", port=8050,
      password = "fat", mount = "test-switching")

currentshow = ref []



harborstream = input.harbor("test-switching", port=8050, password="fat")

final = mksafe(harborstream)

output.icecast(%mp3(bitrate=192),
    host = "localhost", port = 8000,
    password = icecastpassword, mount = "basscadettest.mp3",
    name = "BASSCADETTEST", final)


def playit (show) =
  s = out(show)
  currentshow := [s]
end

def looper () =
  list.iter(source.shutdown, !currentshow)
  playit(radio2)
  10.0
end

playit(radio)

add_timeout(10.0, looper)
