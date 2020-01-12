#!/Users/omm/.opam/default/bin/liquidsoap -v
# Log dir
set("log.file.path","/tmp/quick_test_withoutput.log")

%include "passwords.liq" # sets variable: icecastpassword

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






# simulated output from config file
station_playlists_root = ref "/Users/omm/Radio Station/MusicTest/"


# build the list of playlists for output

playlist_list = ref []

config_file = file.contents("showconfig_shortiez.json")
showconfig = of_json(default=[("error", [("no show found", "")])], config_file)

def get_show(thisshow) =
  thisshowkey = fst(thisshow)
  thisshowdata = snd(thisshow)
  thisshowpath = list.assoc (default="error", "playlist_path", thisshowdata) # TODO: deal with failure better
  thisfullpath = "#{!station_playlists_root}#{thisshowpath}"
  thisplaylist = playlist(id=thisshowkey, thisfullpath)
  playlist_list := list.append([(thisshowkey, thisplaylist)], !playlist_list)
end

if list.mem_assoc("error", showconfig) == false then
  list.iter(get_show, showconfig)
end


# build the schedule

# reeeeeead that showschedule file

blank_playlist = blank()

radio = mksafe(
          crossfade(
            switch(
              [
                ({ 0m-41m }, list.assoc(default=blank_playlist, "Shortiez1", !playlist_list)),
                ({ 41m-60m }, list.assoc(default=blank_playlist, "Shortiez2", !playlist_list))
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
