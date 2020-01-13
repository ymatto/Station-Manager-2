#!/Users/omm/.opam/default/bin/liquidsoap -v
# Log dir
set("log.file.path","/tmp/quick_test_withoutput.log")

%include "passwords.liq" # sets variable: icecastpassword




# simulated output from config file
station_playlists_root = ref "/Users/omm/Radio Station/MusicTest/"
config_file = file.contents("showconfig_shortiez.json") # TODO: make configurable


# build the list of playlists for output

playlist_list = ref []
show_names = ref []

showconfig = of_json(default=[("error", [("no show found", "")])], config_file)

def get_show(thisshow) =
  thisshowkey = fst(thisshow)
  thisshowdata = snd(thisshow)
  thisshowpath = list.assoc (default="error", "playlist_path", thisshowdata) # TODO: deal with failure better
  thisfullpath = "#{!station_playlists_root}#{thisshowpath}"
  thisplaylist = playlist(id=thisshowkey, thisfullpath)
  playlist_list := list.append([(thisshowkey, thisplaylist)], !playlist_list)
  thisshowname = list.assoc (default="error", "show_name", thisshowdata)
  show_names := list.append([(thisshowkey, thisshowname)], !show_names)
end

if list.mem_assoc("error", showconfig) == false then
  list.iter(get_show, showconfig)
end




# UPDATE LOG DATA ON NEW TRACK

currentshow = ref ""

# Write stuff whenever there's a new track
def logtrack(metadata) =
  ignore(
    file.write(
      data="#{metadata[\"artist\"]} - #{metadata[\"album\"]} - #{metadata[\"title\"]}\n",
      append=true,
      station_tracklog_path
    )
  )
  newshow = "#{metadata[\"source\"]}"
  oldshow = !currentshow
  if newshow != oldshow then
    currentshow := newshow
    ignore(
      file.write(
        data=list.assoc(default="", newshow, !show_names),
        append=false,
        station_currentshow_path
      )
    )
  end
end




# build the schedule

# reeeeeead that showschedule file

def return_timeinterval (thing) =
  log(thing)
  { 0m-52m }
end

blank_playlist = blank()

radio = mksafe(
          crossfade(
            switch(
              [
                (return_timeinterval("Ididit"), list.assoc(default=blank_playlist, "Shortiez1", !playlist_list)),
                ({ 52m-60m }, list.assoc(default=blank_playlist, "Shortiez2", !playlist_list))
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
