#!/Users/omm/.opam/default/bin/liquidsoap -v

%include "passwords.liq"  # sets variable: icecastpassword

set("log.file.path","/tmp/simpletest.log")


def run_on_end (delay, metadata) =
    log("---- Track ending in 150 ----")
end

justtheplaylist = playlist("/Users/omm/Radio Station/Music/Instrumental Hip-Hop/")

testshow =
    mksafe(on_end(delay=150.0, run_on_end, justtheplaylist))


out = output.icecast(%mp3(bitrate=192),
  host = "localhost", port = 8000,
  password = icecastpassword, mount = "basscadettest.mp3",
  name = "BASSCADETTEST")

s = out(testshow)

trackendtime = ref 0.0

def looper () =
    now = gettimeofday()
    remaining = source.remaining(testshow)
    trackendtime := now + remaining
#    log("Track ending at: " ^ string_of(!trackendtime - 1591490000.0))
    log ("Track ending in: " ^ string_of(remaining))
    0.1
end

add_timeout(0.0, looper)
