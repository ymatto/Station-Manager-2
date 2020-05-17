#!/Users/omm/.opam/default/bin/liquidsoap -v

%include "passwords.liq"  # sets variable: icecastpassword


# LOAD STATION CONFIG
# TODO: allow multiple configs within the config file for multiple output streams of the same station
stationconfig_file = file.contents("stationconfig_shortiez.json") # CHANGEME TO TEST
station_config_strings = of_json(default=[("error", "no station config")], stationconfig_file)
station_config_ints = of_json(default=[("", 0)], stationconfig_file)

if station_config_strings["error"] == "no station config" then
  log("station config invalid")
end

# TODO: These should probably all use list.assoc to have specified defaults
station_name = station_config_strings["name"]
station_description = station_config_strings["description"]
# station_spoken_ID = station_config_strings["spoken_ID"]
station_log_path = station_config_strings["log_path"]
station_tracklog_path = station_config_strings["tracklog_path"]
station_currentshow_path = station_config_strings["currentshow_path"]
# station_output_encoding = station_config_strings["currentshow_encoding"]
# station_output_bitrate = list.assoc(default=192, "bitrate", station_config_ints)
# station_format = # ... TODO: Have defined list of "formats" to specify from
station_host = station_config_strings["host"]
station_port = list.assoc(default=8000, "port", station_config_ints)
station_mount = station_config_strings["mount"]
station_genre = station_config_strings["genre"]
station_url = station_config_strings["url"]
station_playlists_root = ref station_config_strings["playlists_root"] # FIX: better way than using ref?
station_showconfig_path = station_config_strings["showconfig_path"]

# Log dir
set("log.file.path",station_log_path)


# LOAD SHOW config
# TODO: For now just pulling a list of names for the sake of the currentShow.log
# TODO: Probably build other lists other than show_names here at some point.
# TODO: Deal with failure to read better with thoughtful defaults and handling

show_paths = ref []
show_names = ref []

showconfig_file = file.contents(station_showconfig_path)
showconfig = of_json(default=[("error", [("no show found", "")])], showconfig_file)

def get_show(thisshow) =
  thisshowkey = fst(thisshow)
  thisshowdata = snd(thisshow)
  thisshowpath = list.assoc (default="error", "playlist_path", thisshowdata) # TODO: deal with failure better
  show_paths := list.append([(thisshowkey, "#{!station_playlists_root}#{thisshowpath}")], !show_paths)

  thisshowname = list.assoc (default="error", "show_name", thisshowdata)
  show_names := list.append([(thisshowkey, thisshowname)], !show_names)
end

if list.mem_assoc("error", showconfig) == false then
  list.iter(get_show, showconfig)
end





# FUNCTIONS TO UPDATE LOG DATA ON NEW TRACK

currentshow = ref ""
recenttracks = ref []
new_tracklog = ref ""

# Write stuff whenever there's a new track

def addtotracklog(nexttrack) =
  new_tracklog := string.concat([!new_tracklog, nexttrack, "\n"])
end

def logtrack(metadata) =
  newline="#{metadata[\"artist\"]} - #{metadata[\"album\"]} - #{metadata[\"title\"]}"
  recenttracks := list.add(newline, !recenttracks)
  if (list.length(!recenttracks) > 20) then
    recenttracks := list.rev(list.tl(list.rev(!recenttracks)))
  end
  new_tracklog := ""
  list.iter(addtotracklog, !recenttracks)
  ignore(
    file.write(
      data=!new_tracklog,
      append=false,
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







# LOAD SHOW SCHEDULE
# TODO: Figure out how to pull in showschedule to do this dynamically.
#       Hard-coding a match to the existing schedule for now.
# TODO: If no file configured, should be smart enough to just pull list of
#       directories from station_playlists_path and use default settings

%include "shortiez_schedule.liq" # CHANGEME TO TEST





# BUILD THE HARBOR SOURCE FOR SCHEDULED SHOW SWITCHING

set("harbor.bind_addr","0.0.0.0")
scheduled_source = input.harbor("broadcast-harbor", port=8033, password="ncr89nqenfihs997hfxa")

hout = output.icecast(%wav,
  port = 8033,
  host = "0.0.0.0",
  mount = "broadcast-harbor",
  password = "ncr89nqenfihs997hfxa")

hout(radio)  # switchy logic replaces this




# BUILD THE BROADCAST SOURCE

broadcast_source = mksafe(on_metadata(logtrack, scheduled_source))

# CREATE THE STREAM
output.icecast(%mp3(bitrate=192),
  host = station_host, port = station_port,
  password = icecastpassword, mount = station_mount,
  name = station_name,
  description = station_description,
  genre = station_genre,
  url = station_url, broadcast_source)
