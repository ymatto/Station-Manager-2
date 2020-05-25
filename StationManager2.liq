#!/Users/omm/.opam/default/bin/liquidsoap -v

%include "passwords.liq"  # sets variable: icecastpassword


# LOAD STATIONCONFIG

# TODO: allow multiple configs within the config file for multiple output streams of the same station
stationconfig_file = file.contents("stationconfig.json") # CHANGEME TO TEST
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
station_showschedule_path = station_config_strings["showschedule_path"]

# Log dir
set("log.file.path",station_log_path)




# LOAD SHOWCONFIG

# TODO: For now just pulling a list of names for the sake of the currentShow.log, need to parse the rest
# TODO: Probably build other lists other than show_names/paths here at some point.
# TODO: Deal with failure-to-read better with thoughtful defaults and handling

show_paths = ref [] # ("Beats", "files/Instrumental Hip-Hop"), ("Groovestyle", "files/Stylish Background"), ...
show_names = ref [] # ("Beats", "Straight Beats"), ("Groovestyle", "Groovestyle"), ...

showconfig_file = file.contents(station_showconfig_path)
showconfig = of_json(default=[ ( "error" , [("no show found", "")] ) ], showconfig_file)

def get_show(thisshow) =
  thisshowkey = fst(thisshow)
  thisshowdata = snd(thisshow)

  thisshowpath = list.assoc (default="error", "playlist_path", thisshowdata) # TODO: deal with failure better
  show_paths := list.append([(thisshowkey, "#{!station_playlists_root}#{thisshowpath}")], !show_paths)
  thisshowname = list.assoc (default="error", "show_name", thisshowdata) # TODO: deal with failure better
  show_names := list.append([(thisshowkey, thisshowname)], !show_names)
end

list.iter(get_show, showconfig)




# LOAD SHOW SCHEDULE

# TODO: If no file configured, should be smart enough to just pull list of
#       directories from station_playlists_path and use default settings
# TODO: Deal with failure-to-read better with thoughtful defaults and handling

# %include "basscadet_schedule.liq" # DELETE...

showschedule_types = ref [] # "daysofweek", "everyday", ...
showschedule_days = ref [] # ["Mondays", "Wednesdays"], [""], ...
showschedule_show_names = ref [] # ["Afterparty", "Groovestyle", "Nightmode"], ["Braindance", "Beats"], ...
showschedule_show_times = ref [] # [0, 7, 16], [0, 12], ...

showschedule_file = file.contents(station_showschedule_path)

showschedule_string_pairs = of_json(                         # types
    default=[ [ ("strings_error", "") ] ],
    showschedule_file
    )
showschedule_stringlist_pairs = of_json(                    # days, show_names
    default=[ [ ("stringarrays_error", [ "" ]) ] ],
    showschedule_file
    )
showschedule_intlist_pairs = of_json(                       # show_times
    default=[ [ ("intarrays_error", [ 0 ]) ] ],
    showschedule_file
    )

def get_showschedule_strings(string_pairs) =
    this_type = list.assoc (default="everyday", "type", string_pairs) # TODO: check default handling?
    showschedule_types := list.append([this_type], !showschedule_types)
end

def get_showschedule_stringlists(stringlist_pairs) =
    this_days = list.assoc (default=[""], "days", stringlist_pairs) # TODO: check default handling?
    showschedule_days := list.append([this_days], !showschedule_days)
    this_show_names = list.assoc (default=[""], "show_names", stringlist_pairs) # TODO: make a blank or something
    showschedule_show_names := list.append([this_show_names], !showschedule_show_names)
end

def get_showschedule_intlists(intarray_pairs) =
    this_show_times = list.assoc (default=[0], "show_times", intarray_pairs) # TODO: check default handling?
    showschedule_show_times := list.append([this_show_times], !showschedule_show_times)
end

list.iter(get_showschedule_strings, showschedule_string_pairs)
list.iter(get_showschedule_stringlists, showschedule_stringlist_pairs)
list.iter(get_showschedule_intlists, showschedule_intlist_pairs)


# FUNCTIONS TO INITIALIZE SHOW SCHEDULE FOR TODAY

todays_show_names = ref [] # list o' show names
todays_show_times = ref [] # corresponding list o' show times when they should start

def set_todays_schedule() =
    # FIXME: temp shit to work out looper logic before figuring this out
    todays_show_names := ["Braindance", "Beats"]
    todays_show_times := [0, 13]
end





# FUNCTIONS TO UPDATE LOG DATA ON NEW TRACK

currentshow_logname = ref ""
recent_tracks = ref []
new_tracklog = ref ""

# Write stuff whenever there's a new track

def addtotracklog(nexttrack) =
  new_tracklog := string.concat([!new_tracklog, nexttrack, "\n"])
end

def logtrack(metadata) =
  newline="#{metadata[\"artist\"]} - #{metadata[\"album\"]} - #{metadata[\"title\"]}"
  recent_tracks := list.add(newline, !recent_tracks)
  if (list.length(!recent_tracks) > 20) then
    recent_tracks := list.rev(list.tl(list.rev(!recent_tracks)))
  end
  new_tracklog := ""
  list.iter(addtotracklog, !recent_tracks)
  ignore(
    file.write(
      data=!new_tracklog,
      append=false,
      station_tracklog_path
    )
  )
  newshow = "#{metadata[\"source\"]}"
  oldshow = !currentshow_logname
  if newshow != oldshow then
    currentshow_logname := newshow
    ignore(
      file.write(
        data=list.assoc(default="", newshow, !show_names),
        append=false,
        station_currentshow_path
      )
    )
  end
end





# BUILD THE HARBOR SOURCE FOR SCHEDULED SHOW SWITCHING

set("harbor.bind_addr","0.0.0.0")
scheduled_source = input.harbor("broadcast-harbor", port=8033, password="ncr89nqenfihs997hfxa")

hout = output.icecast(%wav,
      port = 8033,
      host = "0.0.0.0",
      mount = "broadcast-harbor",
      password = "ncr89nqenfihs997hfxa") #TODO: randomly generate password for this?



# SET UP AUTOMATED HARBOR SOURCE CONTROL VIA SCHEDULE

current_show_name = ref ""
current_show_source = ref []

default_pulse = ref 10.0 # seconds between loops if there's no other need
current_day = ref ""

# time crap

def get_weekday_name(~sec, ~min, ~hour, ~mday, ~mon, ~year, ~wday, ~yday, ~isdst) =
    daymapping = [
        (0, "Sunday"),
        (1, "Monday"),
        (2, "Tuesday"),
        (3, "Wednesday"),
        (4, "Thursday"),
        (5, "Friday"),
        (6, "Saturday")
    ]
    list.assoc(default="error", wday, daymapping)
end

def get_today() =
    localtime(gettimeofday(), get_weekday_name)
end

# show control

def changeshow (showname) =
    show_source = mksafe(crossfade(playlist(id=showname, list.assoc(default="error", showname, !show_paths))))
    s = hout(show_source)
    current_show_source := [s]
    current_show_name := showname
end

def get_correct_show() =
    #FIXME
    "Braindance"
end

def dj_looper () =
    print("DJ Looper checking in...")
    now_day = get_today()
    if (!current_day != now_day) then
        current_day := now_day
        set_todays_schedule()
    end
    correct_show = get_correct_show()
    if (!current_show_name != correct_show) then
        print("Time for a new show!")
        list.iter(source.shutdown, !current_show_source) # FIXME can this move into changeshow?
        changeshow(correct_show)
        current_show_name := correct_show
    end

  !default_pulse #FIXME needs to at least try to change shows at ends of tracks
end

add_timeout(5.0, dj_looper)







# BUILD THE BROADCAST OUTPUT

broadcast_source = mksafe(on_metadata(logtrack, scheduled_source))

# CREATE THE STREAM
output.icecast(%mp3(bitrate=192),
  host = station_host, port = station_port,
  password = icecastpassword, mount = station_mount,
  name = station_name,
  description = station_description,
  genre = station_genre,
  url = station_url, broadcast_source)
