#!/Users/omm/.opam/default/bin/liquidsoap -v

%include "passwords.liq"  # sets variable: icecastpassword

set("log.file.path","/tmp/simpletest.log")

track_end = ref false
fadeout_trackend = ref false

def run_on_track_end (time, metadata) =
    track_end := true
end




justtheplaylist = playlist("/Users/omm/Radio Station/Music/Instrumental Hip-Hop/")

testshow =
    mksafe(
        crossfade(duration=5.0,
            on_offset(offset=5.0, run_on_track_end,
                switch( track_sensitive=true,
                    [ ({!fadeout_trackend == true}, blank()), ({true}, justtheplaylist) ]
                )
            )
        )
    )

out = output.icecast(%wav,
    host = "localhost", port=8050,
    password = "fat", mount = "test-harbor")

harborstream = input.harbor("test-harbor", port=8050, password="fat")

final = mksafe(harborstream)

output.icecast(%mp3(bitrate=192),
  host = "localhost", port = 8000,
  password = icecastpassword, mount = "basscadettest.mp3",
  name = "BASSCADETTEST", final)

s = out(testshow)




# loop_count = ref 0

def looper () =
#    if (!loop_count > 30 and !fadeout_trackend == false) then
#        log("Fade out at end of this track!")
#        fadeout_trackend := true
#    end
    if (!track_end) then
        log("Track end!")
        track_end := false
    end
    log("Source remaining = " ^ string_of(source.remaining(testshow)))
#    loop_count := !loop_count + 1
    0.2
end

add_timeout(1.0, looper)
