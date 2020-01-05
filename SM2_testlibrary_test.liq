#!/Users/omm/.opam/default/bin/liquidsoap -v
# Log dir
set("log.file.path","/tmp/SM2_test.log")

# sets variable: icecastpassword
%include "passwords.liq"

currentshow = ref ""

# Write stuff whenever there's a new track
def logtrack(metadata) =
  ignore(
    file.write(
      data="#{metadata[\"artist\"]} - #{metadata[\"album\"]} - #{metadata[\"title\"]}\n",
      append=true,
      "recentTracks_test.log"
    )
  )
  newshow = "#{metadata[\"source\"]}"
  oldshow = !currentshow
  if newshow != oldshow then
    currentshow := newshow
    ignore(
      file.write(
        data=newshow,
        append=false,
        "currentShow_test.log"
      )
    )
  end
end

# Music (shuffle mode is default)
pl_shortiez = playlist(id="Shortiez", "/Users/omm/Radio Station/MusicTest/Short Tracks/")
pl_shortiez2 = playlist(id="Shortiez2", "/Users/omm/Radio Station/MusicTest/Short Tracks 2/")

radio = mksafe(
          crossfade(
            switch(
              [
                ({ 0m-41m }, pl_shortiez),
                ({ 41m-60m }, pl_shortiez2)
              ]
            )
          )
        )


radio = on_metadata(logtrack,radio)

# Stream it out
output.icecast(%mp3(bitrate=192),
  host = "localhost", port = 8868,
  password = icecastpassword, mount = "test.mp3",
  name = "TEST RADIO",
  description = "Testing something out",
  genre = "TEST",
  url = "",
  radio)
