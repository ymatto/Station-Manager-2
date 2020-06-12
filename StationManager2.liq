#!/Users/omm/.opam/default/bin/liquidsoap -v

%include "passwords.liq"  # sets variable: icecastpassword

set("server.telnet",true)

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
# TODO: Deal with failure-to-read better with thoughtful defaults and handling

# TODO should do show_names here too, just as a convenient list of keys for the other lists
show_paths = ref [] # ("Beats", "files/Instrumental Hip-Hop"), ("Groovestyle", "files/Stylish Background"), ...
show_longnames = ref [] # ("Beats", "Straight Beats"), ("Groovestyle", "Groovestyle"), ...

showconfig_file = file.contents(station_showconfig_path)
showconfig = of_json(default=[ ( "error" , [("no show found", "")] ) ], showconfig_file)

def get_show(thisshow) =
  thisshowkey = fst(thisshow) # TODO <-- AKA this_show_name, see note above
  thisshowdata = snd(thisshow)

  thisshowpath = list.assoc (default="error", "playlist_path", thisshowdata) # TODO: deal with failure better
  show_paths := list.append([(thisshowkey, "#{!station_playlists_root}#{thisshowpath}")], !show_paths)
  thisshowlongname = list.assoc (default="error", "show_longname", thisshowdata) # TODO: deal with failure better
  show_longnames := list.append([(thisshowkey, thisshowlongname)], !show_longnames)
  # TODO other fields from json once relevant...
end

list.iter(get_show, showconfig)




# LOAD SHOW SCHEDULE

# TODO: If no file configured, should be smart enough to just pull list of directories
#       from station_playlists_root (if specified) and set reasonable defaults
# TODO: Deal with failure-to-read better with thoughtful defaults and handling
# TODO: Ultimately this should probably be in a func so it can be skipped, and so the file can be re-read for updates

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
scheduled_source = input.harbor(id="internal_input_harbor", "broadcast-harbor", port=8033, password="ncr89nqenfihs997hfxa")

hout = output.icecast(
    %wav,
    port = 8033, # TODO: configurable?
    host = "0.0.0.0",
    mount = "broadcast-harbor",
    password = "ncr89nqenfihs997hfxa" ) # TODO: randomly generate password for this?





# CONTROL BOARD

current_show_name = ref ""
current_show_source = ref [hout(blank())] # make sure the ref is explicitly an active_source

fadeout_trackend = ref false
fadeout_instant = ref false

track_endtime = ref false

trackend_command_queue = ref [] # [([commandname, arg], exec_delay), ...]
timed_command_queue = ref [] # [([commandname, arg], exec_time), ...]

# queue management functions

def sort_command_queue_by_time(command_pair1, command_pair2) =
    command_time1 = snd(command_pair1)
    command_time2 = snd(command_pair2)
    if (command_time1 > command_time2) then
        1
    elsif (command_time1 < command_time2) then
        -1
    else
        0
    end
end

def timed_enqueue(command, exec_delay) = # command (list), exec_delay (float, seconds)
    now = gettimeofday()
    command_time = now + exec_delay # needs to be ref to be visible within func below?
    log("Command received: " ^ string_of(command) ^ " with execution set to " ^ string_of(exec_delay) ^ " seconds from now")
    command_pair = [(command, command_time)] # timed queue uses absolute times for execution
    timed_command_queue := list.append(!timed_command_queue, command_pair)
    # now sort it by time so we can just look from the head of the list everywhere else
    timed_command_queue := list.sort(sort_command_queue_by_time, !timed_command_queue)
    log("timed command queue now: " ^ string_of(!timed_command_queue))
end

def trackend_enqueue(command, exec_delay) =
    log("Command received: " ^ string_of(command) ^ " with execution delay: " ^ string_of(exec_delay) ^ " from end of track")
    command_pair = [(command, exec_delay)] # trackend queue uses a delay, which can be turned into a fixed time at track end
    trackend_command_queue := list.append(!trackend_command_queue, command_pair)
end

# command-queueable functions

def set_fadeout_trackend(arg) =
    if (arg == "true") then
        fadeout_trackend := true
    elsif (arg == "false") then
        fadeout_trackend := false
    else
        log("Bad arg to set_fadeout_trackend")
    end
end

def set_fadeout_instant (arg) =
    if (arg == "true") then
        fadeout_instant := true
    else
        fadeout_instant := false
    end
end

# show management functions (plus change_show queueable command)

def shutdown_output() =
    list.iter(source.shutdown, !current_show_source)
end

def handle_track_end (offset, metadata) =
    log("  - track change -")
    track_endtime := true # triggers the command_loop
end

def output_new_show (show_name) =
    log("  ------ New show starting: " ^ show_name ^ " ------  ")
    show_path = list.assoc(default="error", show_name, !show_paths)
    show_source = playlist(id="scheduled_show_playlist", show_path)
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
    s = hout(id="scheduled_show_output", output_source)
    current_show_source := [s]
    current_show_name := show_name
end

def change_show(showname) =
    log("change_show running: " ^ showname)
    if (list.assoc(default="error", showname, !show_paths) != "error") then
        shutdown_output() # Can't be within output_new_show for reasons I can't figure out
        output_new_show(showname)
    else
        log("No playlist path specified for requested show: " ^ showname)
    end
    set_fadeout_trackend("false") # TODO Does this always running cause any problems?
end

# queue execution functions

def execute_a_command(command) =
    command_name = list.hd(default="", command)
    command_arg = list.nth(default="", command, 1)
    log("processing command: " ^ command_name ^ " - with argument: " ^ command_arg)
    if (command_name == "change_show") then
        change_show(command_arg)
    elsif (command_name == "set_fadeout_trackend") then
        set_fadeout_trackend(command_arg)
    elsif (command_name == "set_fadeout_instant") then
        set_fadeout_instant(command_arg)
    end
    #TODO moar commands
end

def process_timed_command_queue() =
    now = gettimeofday()
    def process_commands(this_command_pair) =
        this_command = fst(this_command_pair)
        this_command_time = snd(this_command_pair)
        if (this_command_time <= now) then
            execute_a_command(this_command)
            false # done, doesn't get saved in the updated list
        else
            true
        end
    end
    timed_command_queue := list.filter(process_commands, !timed_command_queue) # updated queue
end

def process_trackend_command_queue() =
    def process_commands (this_command_pair) =
        this_command = fst(this_command_pair)
        this_command_delay = snd(this_command_pair)
        if (this_command_delay <= 0.0) then
            # do it now!
            execute_a_command(this_command)
        else
            # inject commands with non-zero delay into timed queue
            timed_enqueue(this_command, this_command_delay)
        end
        false # just return an empty queue to the filter for now... unless there's some reason for leave something there?
    end
    if (list.length(!trackend_command_queue) > 0) then
        trackend_command_queue := list.filter(process_commands, !trackend_command_queue) # will just be cleared out
    end
    track_endtime := false # reset and start waiting for next trackend
end

# loop that executes commands out of queues at the proper time

def command_loop() =
    now = gettimeofday()
    if (!track_endtime) then
        process_trackend_command_queue()
    end
    next_timed_command_time = snd(list.hd(default=(["", ""], 0.0), !timed_command_queue))
    if (now >= next_timed_command_time and next_timed_command_time != 0.0) then
        process_timed_command_queue()
    end
    0.1
end

add_timeout(0.1, command_loop)


# SERVER FUNCTIONS

def cb_trackend_enqueue (input_string) =
    command_name = ref ""
    command_arg = ref ""
    command_time = ref 0.0
    command_list = string.split(separator=" ", input_string)
    command_length = list.length(command_list)
    if (command_length > 0) then
        command_name := list.nth(default="", command_list, 0)
        if (command_length > 1) then
            command_arg := list.nth(default="", command_list, 1)
            if (command_length > 2) then
                command_time := float_of_string(list.nth(default="", command_list, 2))
            end
        end
        trackend_enqueue([!command_name, !command_arg], !command_time)
        "Done"
    else
        "No command provided"
    end
end

def cb_timed_enqueue (input_string) =
    command_name = ref ""
    command_arg = ref ""
    command_time = ref 0.0
    command_list = string.split(separator=" ", input_string)
    command_length = list.length(command_list)
    if (command_length > 0) then
        command_name := list.nth(default="", command_list, 0)
        if (command_length > 1) then
            command_arg := list.nth(default="", command_list, 1)
            if (command_length > 2) then
                command_time := float_of_string(list.nth(default="", command_list, 2))
            end
        end
        timed_enqueue([!command_name, !command_arg], !command_time)
        "Done"
    else
        "No command provided"
    end
end

server.register(namespace="cb",
                usage="trackend_enqueue <command> [<argument> <time>]",
                description="Inserts a command into the queue to be run at at delay from track's end",
                "trackend_enqueue",
                cb_trackend_enqueue)

server.register(namespace="cb",
                usage="instant_enqueue <command> [<argument> <time>]",
                description="Inserts a command into the queue to be run after a delay",
                "timed_enqueue",
                cb_timed_enqueue)





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
    log("Updating current and next scheduled shows...")
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
        log("    Checking tomorrow's schedule for next show...")

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
    log("    Current show:  " ^ !current_scheduled_show_name)
    log("    Next show:     " ^ !next_scheduled_show_name)
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
            log(" *** DJ LOOPER: Starting up " ^ !current_scheduled_show_name)
            timed_enqueue(["change_show", !current_scheduled_show_name], 0.0)
        end
        if (now >= !next_scheduled_show_time) then
            log(" *** DJ LOOPER: Coming up next... " ^ !next_scheduled_show_name)
            timed_enqueue(["set_fadeout_trackend", "true"], 0.0)
            trackend_enqueue(["change_show", !next_scheduled_show_name], 3.0)
            update_current_next_shows()
        end
    end

    !next_pulse
end


# kick off automatic show management
# TODO: make initiating and halting the DJ control loop control board functions

log(" *** Initiating DJ LOOPER...")
add_timeout(0.0, dj_looper) #start it up!







# BUILD THE BROADCAST OUTPUT

broadcast_source = mksafe(on_metadata(logtrack, scheduled_source))

# CREATE THE STREAM
output.icecast(id="broadcast_output",
    %mp3(bitrate=192),
    host = station_host, port = station_port,
    password = icecastpassword, mount = station_mount,
    name = station_name,
    description = station_description,
    genre = station_genre,
    url = station_url, broadcast_source)
