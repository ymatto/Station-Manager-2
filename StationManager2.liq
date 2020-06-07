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
# TODO: Probably build other lists other than show_longnames/paths here at some point.
# TODO: Deal with failure-to-read better with thoughtful defaults and handling

show_paths = ref [] # ("Beats", "files/Instrumental Hip-Hop"), ("Groovestyle", "files/Stylish Background"), ...
show_longnames = ref [] # ("Beats", "Straight Beats"), ("Groovestyle", "Groovestyle"), ...

showconfig_file = file.contents(station_showconfig_path)
showconfig = of_json(default=[ ( "error" , [("no show found", "")] ) ], showconfig_file)

def get_show(thisshow) =
  thisshowkey = fst(thisshow)
  thisshowdata = snd(thisshow)

  thisshowpath = list.assoc (default="error", "playlist_path", thisshowdata) # TODO: deal with failure better
  show_paths := list.append([(thisshowkey, "#{!station_playlists_root}#{thisshowpath}")], !show_paths)
  thisshowlongname = list.assoc (default="error", "show_longname", thisshowdata) # TODO: deal with failure better
  show_longnames := list.append([(thisshowkey, thisshowlongname)], !show_longnames)
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
showschedule_show_hours = ref [] # [0, 7, 16], [0, 12], ...

showschedule_file = file.contents(station_showschedule_path)

showschedule_string_pairs = of_json(                         # types
    default=[ [ ("strings_error", "") ] ],
    showschedule_file
    )
showschedule_stringlist_pairs = of_json(                    # days, show_names
    default=[ [ ("stringarrays_error", [ "" ]) ] ],
    showschedule_file
    )
showschedule_intlist_pairs = of_json(                       # show_hours
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
    this_show_hours = list.assoc (default=[0], "show_hours", intarray_pairs) # TODO: check default handling?
    showschedule_show_hours := list.append([this_show_hours], !showschedule_show_hours)
end

list.iter(get_showschedule_strings, showschedule_string_pairs)
list.iter(get_showschedule_stringlists, showschedule_stringlist_pairs)
list.iter(get_showschedule_intlists, showschedule_intlist_pairs)





# FUNCTIONS TO UPDATE LOG DATA ON NEW METADATA

currentshow_logname = ref ""
recent_tracks = ref []
new_tracklog = ref ""

# Write stuff whenever there's new metadata

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
        data=list.assoc(default="", newshow, !show_longnames),
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
# TODO: Allow injection of commands to be run in X seconds... can timestamp when
#       it should run, and keep track of a "next timed command" that the command
#       loop can check. With that, put a little delay before show switches, etc.

current_show_name = ref ""
current_show_source = ref [hout(blank())]

fadeout_trackend = ref false
fadeout_instant = ref false

track_endtime = ref false

trackend_command_queue = ref []

def trackend_enqueue(command) =
    #FIXME dumb
    trackend_command_queue := [command]
end

def trackend_readqueue() =
    #FIXME dumb
    command = list.hd(default=[""], !trackend_command_queue)
    trackend_command_queue := []
    command
end

def set_fadeout_trackend (status) =
    fadeout_trackend := status
end

def set_fadeout_instant (status) =
    fadeout_instant := status
end

def shutdown_output() =
    list.iter(source.shutdown, !current_show_source)
end

def change_show_trackend(showname) =
    if (list.assoc(default="error", showname, !show_paths) != "error") then
        set_fadeout_trackend(true)
        trackend_enqueue(["change_show_trackend_finish", showname])
    else
        log("No playlist path specified for requested show: " ^ showname)
    end
end

def handle_track_end (offset, metadata) =
    log("--- track change ---")
    track_endtime := true # triggers the command_loop
end

def output_new_show (show_name) =
    log("New show selected: " ^ show_name)
    show_path = list.assoc(default="error", show_name, !show_paths)
    show_source = playlist(id=show_name, show_path)
    output_source =
        mksafe(
            crossfade(duration=5.0, #TODO make this (and offset below) a config parameter
                on_offset(offset=5.0, handle_track_end, # should basically hit end of track
                    switch( track_sensitive=false, [ ({!fadeout_instant == true}, blank()), ({true},
                        switch( track_sensitive=true, [ ({!fadeout_trackend == true}, blank()), ({true},
                            show_source
                        ) ] )
                    ) ] )
                )
            )
        )
    s = hout(output_source)
    current_show_source := [s]
    current_show_name := show_name
end

def change_show_trackend_finish(showname) =
    shutdown_output() # Can't be within output_new_show for reasons I can't figure out
    output_new_show(showname)
    set_fadeout_trackend(false)
end

def change_show_now(showname) =
    if (list.assoc(default="error", showname, !show_paths) != "error") then
        shutdown_output() # Can't be within output_new_show for reasons I can't figure out
        output_new_show(showname)
    else
        log("No playlist path specified for requested show: " ^ showname)
    end
end

def command_loop() =
    if (!track_endtime) then
        if (list.length(!trackend_command_queue) > 0) then
            # FIXME: write a real trackend queue handler
            command = trackend_readqueue()
            commandname = list.hd(default="", command)
            commandarg = list.nth(default="", command, 1)
            log("processing command: " ^ commandname ^ " - with argument: " ^ commandarg)
            if (commandname == "change_show_trackend_finish") then
                change_show_trackend_finish(commandarg)
            end
        end
        track_endtime := false
    end
    0.1
end

add_timeout(0.1, command_loop)




# SET UP AUTOMATED HARBOR SOURCE CONTROL VIA SCHEDULE – AKA DJ LOOPER

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

def get_tomorrow() =
    localtime(gettimeofday()+86400.0, get_weekday_name)
end

def get_hour_int(~sec, ~min, ~hour, ~mday, ~mon, ~year, ~wday, ~yday, ~isdst) =
    hour
end

def get_current_hour() =
    localtime(gettimeofday(), get_hour_int)
end

def get_time_since_midnight(~sec, ~min, ~hour, ~mday, ~mon, ~year, ~wday, ~yday, ~isdst) =
    float_of_int(sec + (min * 60 + (hour * 3600)))
end

# returns the unixtime at midnight at the start of today
def get_today_start_time() =
    now = gettimeofday()
    time_since_midnight = localtime(now, get_time_since_midnight)
    now - time_since_midnight
end


# functions for show management

current_scheduled_show_name = ref ""
current_scheduled_show_hour = ref 0
current_scheduled_show_time = ref 0.0
next_scheduled_show_name = ref ""
next_scheduled_show_hour = ref 0
next_scheduled_show_time = ref 0.0

def add_indices(this_index, this_listitem) =
    (this_index, this_listitem)
end

def find_todays_dow_types (listpair) =
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

def find_tomorrows_dow_types (listpair) =
    this_index = fst(listpair)
    this_type = snd(listpair)
    deez_schedule_days = list.nth(default=[""], !showschedule_days, this_index)
    tomorrow = get_tomorrow() # <-- note
    if (this_type == "daysofweek" and list.mem(tomorrow, deez_schedule_days)) then
        true
    else
        false
    end
end

def is_prior_hour(listpair) =
    this_index = fst(listpair)
    this_hour = snd(listpair)
    now_hour = get_current_hour()
    if (this_hour <= now_hour) then
        true
    else
        false
    end
end

def update_current_next_shows () =
    log("Updating current and next shows...")
    todays_schedule_index = ref 0
    todays_show_names = ref []
    todays_show_hours = ref [0]
    tomorrows_schedule_index = ref 0
    tomorrows_show_names = ref []
    tomorrows_show_hours = ref [0]


    today_start_time = get_today_start_time()
    tomorrow_start_time = today_start_time + 86400.0
    indexed_schedule_types = list.mapi(add_indices, !showschedule_types)

    #TODO: search for "daysofyear" types first
    todays_indexed_dow_schedules = list.filter(find_todays_dow_types, indexed_schedule_types)
    # is there a top heirarchy schedule type for today?
    if (list.length(todays_indexed_dow_schedules) > 0) then
        todays_schedule_index := fst(list.hd(default=(0, ""), todays_indexed_dow_schedules))
        todays_show_names := list.nth(default=[""], !showschedule_show_names, !todays_schedule_index)
        todays_show_hours := list.nth(default=[0], !showschedule_show_hours, !todays_schedule_index)
    else
        # TODO: go look for "everyday" schedules and remove this placeholder crap
        todays_schedule_index := 0
        todays_show_names := [""]
        todays_show_hours := [0]
    end
    indexed_todays_show_hours = list.mapi(add_indices, !todays_show_hours)
    prior_indexed_todays_show_hours = list.filter(is_prior_hour, indexed_todays_show_hours)
    todays_current_index = fst(list.hd(default=(0, 0), list.rev(prior_indexed_todays_show_hours)))
    current_scheduled_show_name := list.nth(default="", !todays_show_names, todays_current_index)
    current_scheduled_show_hour := list.nth(default=0, !todays_show_hours, todays_current_index)
    current_scheduled_show_time := today_start_time + float_of_int(!current_scheduled_show_hour) * 3600.0
    # now let's see if we can just grab the next show from today's schedule...
    if (list.length(!todays_show_names) > todays_current_index + 1) then
        # yup, grab it!
        next_scheduled_show_name := list.nth(default="", !todays_show_names, todays_current_index + 1)
        next_scheduled_show_hour := list.nth(default=0, !todays_show_hours, todays_current_index + 1)
        next_scheduled_show_time := today_start_time + float_of_int(!next_scheduled_show_hour) * 3600.0
    else
        # okay, gotta use tomorrow's schedule...
        log("Gotta use tomorrow's schedule for next show...")

        #TODO: search for "daysofyear" types first
        tomorrows_indexed_dow_schedules = list.filter(find_tomorrows_dow_types, indexed_schedule_types)
        # is there a top heirarchy schedule type for tomorrow?
        if (list.length(tomorrows_indexed_dow_schedules) > 0) then
            tomorrows_schedule_index := fst(list.hd(default=(0, ""), tomorrows_indexed_dow_schedules))
            tomorrows_show_names := list.nth(default=[""], !showschedule_show_names, !tomorrows_schedule_index)
            tomorrows_show_hours := list.nth(default=[0], !showschedule_show_hours, !tomorrows_schedule_index)
        else
            # TODO: go look for "everyday" schedules and remove this placeholder crap
            tomorrows_schedule_index := 0
            tomorrows_show_names := [""]
            tomorrows_show_hours := [0]
        end
        next_scheduled_show_name := list.hd(default="", !tomorrows_show_names)
        next_scheduled_show_hour := list.hd(default=0, !tomorrows_show_hours)
        next_scheduled_show_time := tomorrow_start_time + float_of_int(!next_scheduled_show_hour) * 3600.0
    end
    log("Current show name updated:  " ^ !current_scheduled_show_name)
    log("Next show name updated:     " ^ !next_scheduled_show_name)
end



# the control loop

default_pulse = 5.0 # seconds between loops if there's no other need
next_pulse = ref 0.0

def dj_looper() =
    next_pulse := default_pulse
    now = gettimeofday()
    if (now >= !next_scheduled_show_time) then
        if (!current_show_name == "") then # startup condition, or just recovery from a problem
            update_current_next_shows()
            log("DJ LOOPER: Starting up " ^ !current_scheduled_show_name)
            change_show_now(!current_scheduled_show_name)
        end
        if (now >= !next_scheduled_show_time) then
            log("DJ LOOPER: Coming up next... " ^ !next_scheduled_show_name)
            change_show_trackend(!next_scheduled_show_name)
            update_current_next_shows()
        end
    end

    !next_pulse
end


# kick off automatic show management
# TODO: make initiating and halting the DJ control loop control board functions

log("Initiating DJ LOOPER...")
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
