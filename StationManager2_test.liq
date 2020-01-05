#!/Users/omm/.opam/default/bin/liquidsoap -v
# Log dir
set("log.file.path","/tmp/StationManager2_test.log")

# sets variable: icecastpassword
%include "passwords.liq"

currentshow = ref ""

# Write stuff whenever there's a new track
def logtrack(metadata) =
  ignore(
    file.write(
      data="#{metadata[\"artist\"]} - #{metadata[\"album\"]} - #{metadata[\"title\"]}\n",
      append=true,
      "recentTracks.log"
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
        "currentShow.log"
      )
    )
  end
end


# Music (shuffle mode is default)
pl_afterparty = playlist(id="afterparty", "/Users/omm/Radio Station/Music/Afterparty")
pl_braindance = playlist(id="braindance", "/Users/omm/Radio Station/Music/Braindance")
pl_bump = playlist(id="bump", "/Users/omm/Radio Station/Music/Bump in the Trunk")
pl_beats = playlist(id="beats", "/Users/omm/Radio Station/Music/Instrumental Hip-Hop")
pl_headnod = playlist(id="headnod", "/Users/omm/Radio Station/Music/Laid Back Hip-Hop")
pl_nightmode = playlist(id="nightmode", "/Users/omm/Radio Station/Music/Late Night Electronic")
pl_groovestyle = playlist(id="groovestyle", "/Users/omm/Radio Station/Music/Stylish Background")

radio = mksafe(
          crossfade(
            switch(
              [
                ({ 0w and 0h-7h }, pl_afterparty),
                ({ 0w and 7h-20h }, pl_groovestyle),
                ({ 0w and 20h-24h }, pl_nightmode),
                ({ (1w or 3w) and 0h-7h }, pl_afterparty),
                ({ (1w or 3w) and 7h-10h }, pl_groovestyle),
                ({ (1w or 3w) and 10h-20h }, pl_braindance),
                ({ (1w or 3w) and 20h-24h }, pl_nightmode),
                ({ (2w or 4w) and 0h-7h }, pl_beats),
                ({ (2w or 4w) and 7h-11h }, pl_headnod),
                ({ (2w or 4w) and 11h-16h }, pl_bump),
                ({ (2w or 4w) and 16h-22h }, pl_headnod),
                ({ (2w or 4w) and 22h-24h }, pl_beats),
                ({ 5w and 0h-4h }, pl_afterparty),
                ({ 5w and 4h-10h }, pl_groovestyle),
                ({ 5w and 10h-20h }, pl_braindance),
                ({ 5w and 20h-24h }, pl_afterparty),
                ({ 6w and 0h-7h }, pl_afterparty),
                ({ 6w and 7h-12h }, pl_groovestyle),
                ({ 6w and 12h-20h }, pl_braindance),
                ({ 6w and 20h-24h }, pl_nightmode)
              ]
            )
          )
        )


# Add some jingles
# radio = random(weights = [1, 4],[jingles, radio])

# Add fallback security
# If something goes wrong, we'll play this
# security = single("~/radio/sounds/default.ogg")
# radio = fallback(track_sensitive = false, [radio, security])

radio = on_metadata(logtrack,radio)

# Stream it out
output.icecast(%mp3(bitrate=192),
  host = "localhost", port = 8868,
  password = icecastpassword, mount = "new.mp3",
  name = "Y2MATTK Radio",
  description = "An eclectic mix of Electronic and Hip-Hop tracks all day",
  genre = "Electronic & Hip-Hop",
  url = "http://y2mattk.kicks-ass.net:8868/",
  radio)
