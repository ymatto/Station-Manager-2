#!/Users/omm/.opam/default/bin/liquidsoap -v

%include "passwords.liq"  # sets variable: icecastpassword


# LOAD STATIONCONFIG

stationconfig_file = file.contents(argv(default="", 1)) # TODO: allow script to proceed with defaults without argv?
station_config_strings = of_json(default=[("error", "no station config")], stationconfig_file)
station_config_ints = of_json(default=[("", 0)], stationconfig_file)

if station_config_strings["error"] == "no station config" then
  log("station config invalid")
end

# TODO: These should  all use list.assoc to have specified defaults when not specified in config file
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

# TODO: If no file configured, should be smart enough to just pull list of directories
#       from station_playlists_root (if specified) and set reasonable defaults
# TODO: Deal with failure-to-read better with thoughtful defaults and handling
# TODO: Ultimately this should probably be in a func so the file can be re-read for updates?

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
      password = "ncr89nqenfihs997hfxa") # TODO: randomly generate password for this?




# CONTROL BOARD

current_show_name = ref ""
current_show_output = ref []

end_show = ref false

def changeshow (showname) =
    log("New show selected: " ^ showname)
    show_path = list.assoc(default="error", showname, !show_paths)
    show_source = mksafe(playlist(id=showname, show_path))
    blank_source = blank()
    final_source = crossfade(switch(track_sensitive=true, [({!end_show == true}, blank_source), ({true}, show_source)]))
    s = hout(final_source)
    current_show_output := [s]
    current_show_name := showname
end




# SET UP AUTOMATED HARBOR SOURCE CONTROL VIA SCHEDULE – AKA DJ LOOPER

default_pulse = ref 10.0 # seconds between loops if there's no other need
current_day = ref ""

# time utilities

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

def get_hour_int(~sec, ~min, ~hour, ~mday, ~mon, ~year, ~wday, ~yday, ~isdst) =
    hour
end

def get_current_hour() =
    localtime(gettimeofday(), get_hour_int)
end


# functions for daily show management

todays_show_names = ref [] # list of hours
todays_show_times = ref [] # corresponding list of shows
# and finally, what the DJ can easily scan through...
todays_schedule = ref [] # list of (hour, "Showname") pairs

def add_indices(this_index, this_listitem) =
    (this_index, this_listitem)
end

def find_dow_types (listpair) =
    this_index = fst(listpair)
    this_type = snd(listpair)
    deez_schedule_days = list.nth(default=[""], !showschedule_days, this_index)
    today = get_today()
    if (this_type == "daysofweek" and list.mem(today, deez_schedule_days)) then
        true
    else
        false
    end
end

def build_show_pair(this_index, this_show_time) =
    this_show_name = list.nth(default="", !todays_show_names, this_index)
    (this_show_time, this_show_name)
end

def set_todays_schedule() =
    indexed_schedule_types = list.mapi(add_indices, !showschedule_types)
    matching_indexed_dow_types = list.filter(find_dow_types, indexed_schedule_types)
    if (list.length(matching_indexed_dow_types) > 0) then # top heirarchy schedule type found
        chosen_schedule_index = fst(list.hd(default=(0, ""), matching_indexed_dow_types))
        todays_show_names := list.nth(default=[""], !showschedule_show_names, chosen_schedule_index)
        todays_show_times := list.nth(default=[0], !showschedule_show_times, chosen_schedule_index)
        todays_schedule := list.mapi(build_show_pair, !todays_show_times)
    else
        todays_schedule := [(0, "blank")] # FIXME: first go look for "everyday" schedules...
    end
    log("New schedule for today loaded.") # TODO: log a textification of the schedule
end

def is_prior_show(show) =
    now_hour = get_current_hour()
    if (fst(show) <= now_hour) then
        true
    else
        false
    end
end

def get_correct_show() = # look through todays_schedule to find the right show name
    prior_schedule = list.filter(is_prior_show, !todays_schedule)
    snd(list.hd(default=(0, "none"), list.rev(prior_schedule))) # TODO better default thinking
end


# the control loop

def dj_looper() =
    now_day = get_today()
    if (!current_day != now_day) then
        print("It's a new day, listeners! Let's pull up today's schedule!")
        current_day := now_day
        set_todays_schedule()
    end
    correct_show = get_correct_show()
    if (!current_show_name != correct_show) then
        print("Time for " ^ correct_show ^ "!")
        list.iter(source.shutdown, !current_show_output) # TODO I dunno why this works here but not in changeshow
        changeshow(correct_show)
        current_show_name := correct_show
    end

    !default_pulse # FIXME needs to at least try to change shows at ends of tracks
end

log("Starting DJ control loop.")
add_timeout(0.0, dj_looper) #start it up!







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
