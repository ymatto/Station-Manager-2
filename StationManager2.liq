#!/Users/omm/.opam/default/bin/liquidsoap -v
# NOTE if this is being run by launchd on the mac, voice synthesis requires it run as an agent, not a daemon (because "say" is a GUI app)

# LOAD STATIONCONFIG

# TODO: Halt script if certain minimum things aren't set?

stationconfig_file = file.contents(argv(default="", 1)) # TODO: allow script to proceed with defaults without argv?
station_config_strings = of_json(default=[("error", "no station config")], stationconfig_file)
station_config_ints = of_json(default=[("", 0)], stationconfig_file)
station_config_bools = of_json(default=[("", false)], stationconfig_file)

if station_config_strings["error"] == "no station config" then
  log("station config invalid")
end

%include "encoding_formats.liq"

# TODO: These should all use list.assoc to have specified defaults when not specified in config file
# TODO: These should all be refs so that a new config file can be loaded runtime, and so they're okay even if not used
station_name = station_config_strings["name"]
station_description = station_config_strings["description"]
station_spoken_ID = station_config_strings["spoken_ID"]
station_voice_type = station_config_strings["voice_type"]
station_default_voice = station_config_strings["default_voice"]
station_log_path = station_config_strings["log_path"]
station_tracklog_path = station_config_strings["tracklog_path"]
station_currentshow_path = station_config_strings["currentshow_path"]
station_output_encoding = list.assoc(default=%mp3, list.assoc(default="mp3_128", "output_encoding", station_config_strings), encoding_formats)
station_host = list.assoc(default="localhost", "host", station_config_strings)
station_port = list.assoc(default=8000, "port", station_config_ints)
station_mount = list.assoc(default="radio.mp3", "mount", station_config_strings)
station_genre = list.assoc(default="", "genre", station_config_strings)
station_url = list.assoc(default="", "url", station_config_strings)
station_playlists_root = ref station_config_strings["playlists_root"] # FIX: better way than using ref?
station_showconfig_path = station_config_strings["showconfig_path"]
station_showschedule_path = station_config_strings["showschedule_path"]
station_icecast_password = station_config_strings["icecast_password"]
station_telnet_server = list.assoc(default=false, "telnet_server", station_config_bools)
station_telnet_server_port = list.assoc(default=1234, "telnet_server_port", station_config_ints)
station_telnet_server_timeout = float_of_int(list.assoc(default=30, "telnet_server_timeout", station_config_ints))
station_telnet_server_netmask = list.assoc(default="0.0.0.0", "telnet_server_netmask", station_config_strings)
station_harbor_port = list.assoc(default=station_port+10, "harbor_port", station_config_ints)
station_harbor_password = list.assoc(default=station_icecast_password^string_of(random.int()), "harbor_password", station_config_strings)

# Logs setup
set("log.file.path",station_log_path)

# Server setup
if (station_telnet_server) then
    set("server.telnet", station_telnet_server)
    set("server.telnet.port", station_telnet_server_port)
    set("server.telnet.bind_addr", station_telnet_server_netmask)
    set("server.timeout", station_telnet_server_timeout) # negative value disables timeout
end




# LOAD SHOWCONFIG

# TODO: For now just pulling a list of names for the sake of the currentShow.log, need to parse the rest
# TODO: Deal with failure-to-read better with thoughtful defaults and handling

# TODO should do show_names here too, just as a convenient list of keys for the other lists
show_paths = ref [] # ("Beats", "files/Instrumental Hip-Hop"), ("Groovestyle", "files/Stylish Background"), ...
show_longnames = ref [] # ("Beats", "Straight Beats"), ("Groovestyle", "Groovestyle"), ...
show_voices = ref [] # ("Beats", "Whisper"), ("Groovestyle", "Ava"), ...
show_signons = ref []
show_signoffs = ref []
show_shufflemodes = ref []

showconfig_file = file.contents(station_showconfig_path)
showconfig = of_json(default=[ ( "error" , [("no show found", "")] ) ], showconfig_file)

def get_show(thisshow) =
  thisshowkey = fst(thisshow) # TODO <-- AKA this_show_name, see note above
  thisshowdata = snd(thisshow)

  thisshowpath = list.assoc (default="error", "playlist_path", thisshowdata) # TODO: deal with failure better
  show_paths := list.append([(thisshowkey, "#{!station_playlists_root}#{thisshowpath}")], !show_paths)
  thisshowlongname = list.assoc (default="error", "show_longname", thisshowdata) # TODO: deal with failure better
  show_longnames := list.append([(thisshowkey, thisshowlongname)], !show_longnames)
  thisshowDJvoice = list.assoc (default="", "DJ_voice", thisshowdata)
  show_voices := list.append([(thisshowkey, thisshowDJvoice)], !show_voices)
  thissignon = list.assoc (default="", "signon", thisshowdata)
  show_signons := list.append([(thisshowkey, thissignon)], !show_signons)
  thissignoff = list.assoc (default="", "signoff", thisshowdata)
  show_signoffs := list.append([(thisshowkey, thissignoff)], !show_signoffs)
  thisshufflemode = list.assoc (default="songs", "shuffle_mode", thisshowdata) # TODO: make do something
  show_shufflemodes := list.append([(thisshowkey, thisshufflemode)], !show_shufflemodes)
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

recent_tracks = ref []
new_tracklog = ref ""

# Write stuff whenever there's new metadata

def addtotracklog(nexttrack) =
  new_tracklog := string.concat([!new_tracklog, nexttrack, "\n"])
end

def logtrack(metadata) =
    #TODO don't log if the info is blank or "-" or whatever at show changes
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
end





# BUILD THE HARBOR SOURCE FOR SCHEDULED SHOW SWITCHING

set("harbor.bind_addr","0.0.0.0")
scheduled_source = input.harbor(
    id="internal_input_harbor",
    "broadcast-harbor",
    port=station_harbor_port,
    password=station_harbor_password )

hout = output.icecast(
    %wav,
    port = station_harbor_port,
    host = "0.0.0.0",
    mount = "broadcast-harbor",
    password = station_harbor_password )





# TIME FUNCTIONS

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

def get_time_since_last_hour(~sec, ~min, ~hour, ~mday, ~mon, ~year, ~wday, ~yday, ~isdst) =
    float_of_int(sec + (min * 60))
end

# returns the unixtime at midnight at the start of today
def get_today_start_time() =
    now = gettimeofday()
    time_since_midnight = localtime(now, get_time_since_midnight)
    now - time_since_midnight
end






# DJ CONTROL BOARD FUNCTIONS

current_show_name = ref "" # name of actual broadcasting show (independent of schedule - if there even is one)
current_output_source = ref [hout(blank())] # broadcasting source that can be killed. hour(blank()) is to make sure the ref is explicitly an active_source
current_show_source = ref blank() # the current show playlist source that can be monitored or controlled
current_voice = ref "" # name of current voice to use for synthesized DJ statements

fadeout_trackend = ref false
fadeout_instant = ref false

track_endtime = ref false

timed_command_queue = ref [] # [([commandname, arg], exec_unixtime), ...]
trackend_command_queue = ref [] # [([commandname, arg], exec_delay_after_trackend), ...]
pre_trackend_command_queue = ref [] # [([commandname, arg], exec_time_before_trackend), ...]

# command queue management functions

def sort_command_queue_by_time_ascending(command_pair1, command_pair2) =
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

def sort_command_queue_by_time_descending(command_pair1, command_pair2) =
    command_time1 = snd(command_pair1)
    command_time2 = snd(command_pair2)
    if (command_time1 < command_time2) then
        1
    elsif (command_time1 > command_time2) then
        -1
    else
        0
    end
end

def timed_enqueue(command, exec_delay) = # command (list), exec_delay (float, seconds)
    now = gettimeofday()
    command_time = now + exec_delay # needs to be ref to be visible within func below?
    log("Timed DJ command received:         " ^ string_of(command) ^ " with execution set to " ^ string_of(exec_delay) ^ " seconds from now")
    command_pair = [(command, command_time)] # timed queue uses absolute times for execution
    timed_command_queue := list.append(!timed_command_queue, command_pair)
    # now sort it by time (least first) so we can just check the head of the list in the command loop
    timed_command_queue := list.sort(sort_command_queue_by_time_ascending, !timed_command_queue)
    # log("timed command queue now: " ^ string_of(!timed_command_queue))
end

def trackend_enqueue(command, exec_delay) =
    log("Trackend DJ command received:      " ^ string_of(command) ^ " with execution delay: " ^ string_of(exec_delay) ^ " after end of this track")
    command_pair = [(command, exec_delay)] # trackend queue uses a delay, all of which can be turned into fixed timed_enqueue requests at track end
    trackend_command_queue := list.append(!trackend_command_queue, command_pair)
    # log("trackend command queue now: " ^ string_of(!trackend_command_queue))
end

def pre_trackend_enqueue(command, exec_delay) =
    log("Pre-trackend DJ command received:  " ^ string_of(command) ^ " with execution time: " ^ string_of(exec_delay) ^ " before end of this track")
    command_pair = [(command, exec_delay)]
    pre_trackend_command_queue := list.append(!pre_trackend_command_queue, command_pair)
    # now sort it by pre-trackend delay (largest first) so we can just look check the head of the list in the command loop
    pre_trackend_command_queue := list.sort(sort_command_queue_by_time_descending, !pre_trackend_command_queue)
    # log("pre-trackend command queue now: " ^ string_of(!pre_trackend_command_queue))
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

playover_source = audio_to_stereo(request.queue(id="playover_source"))

def set_voice (voicename) =
    newvoice = ref ""
    if (voicename == "normal") then
        newvoice := station_default_voice
        showvoice = list.assoc(default="", !current_show_name, !show_voices)
        if (showvoice != "") then
            newvoice := showvoice
        end
    else
        newvoice := voicename
    end
    current_voice := !newvoice
    log("New voice selected: " ^ !newvoice)
end

def say (text) =
    speech_filename = file.temp("SM2_speech_", ".wav")
    if (!current_voice == "") then
        log("No voice configured. Say ignored.")
    else
        if (station_voice_type == "mac") then
            # NOTE The 4000ms of silence is to copensate for the fade time on the playover_source
            command_string = "say -o " ^ speech_filename ^ " --data-format=LEI16@44100 --channels=2 -v " ^ !current_voice ^ " \"[[ slnc 4000 ]] " ^ text ^ " \""
            process_return = run_process(timeout = 20.0, command_string)
            if (process_return != ("","",("exit", "0"))) then
                log("SAY DJ COMMAND FAILED: " ^ string_of(process_return))
            else
                log("SPEAKING [" ^ !current_voice ^ "]: " ^ text)
                ignore(server.execute("playover_source.push " ^ speech_filename)) # NOTE Likely will change in later version of LiquidSoap
            end
        else
            log("Station voice_type not set to supported speech synthesizer. Say ignored.")
        end
    end
end


# show management functions (plus change_show queueable command)

def shutdown_output() =
    list.iter(source.shutdown, !current_output_source)
end

def handle_track_end (offset, metadata) =
    log("  - track change signal -")
    track_endtime := true # triggers the command_loop
end

def output_new_show (show_name) =
    log("  --- New show starting: " ^ show_name ^ " ------------------------------------")
    show_path = list.assoc(default="error", show_name, !show_paths)
    show_source = playlist(id="scheduled_show_playlist", show_path)
    current_show_source := show_source
    # TODO maybe use noise() or sine() instead of blank() to prevent players from disconnecting (supposedly)
    output_source =
        mksafe(
            smooth_add(delay=0.5, p=0.1, special=playover_source, normal=
                crossfade(duration=5.0, #TODO make this (and offset below) a config parameter? per show ideally?
                    on_offset(offset=0.0, handle_track_end,
                        switch( track_sensitive=false, [ ({!fadeout_instant == true}, blank()), ({true},
                            switch( track_sensitive=true, [ ({!fadeout_trackend == true}, blank()), ({true},
                                show_source
                            ) ] )
                        ) ] )
                    )
                )
            )
        )
    s = hout(id="scheduled_show_output", output_source)
    current_output_source := [s]
end

def change_show(showname) =
    if (list.assoc(default="error", showname, !show_paths) != "error") then
        log("CHANGING SHOW TO: " ^ showname)
        shutdown_output() # Can't be within output_new_show for reasons I can't figure out
        output_new_show(showname)
        current_show_name := showname
        current_show_longname = list.assoc(default="", showname, !show_longnames)
        set_voice("normal")
        ignore(
            file.write(
                    data=current_show_longname,
                    append=false,
                    station_currentshow_path
                )
        )
    else
        log("No playlist path specified for requested show: " ^ showname)
    end
    set_fadeout_trackend("false") # TODO Does this always running cause any problems?
end

# queue execution functions

def execute_a_command(command) =
    command_name = list.hd(default="", command)
    command_arg = list.nth(default="", command, 1)
    log("PROCESSING DJ COMMAND: " ^ command_name ^ " - with argument: " ^ command_arg)
    if (command_name == "change_show") then
        change_show(command_arg)
    elsif (command_name == "set_fadeout_trackend") then
        set_fadeout_trackend(command_arg)
    elsif (command_name == "set_fadeout_instant") then
        set_fadeout_instant(command_arg)
    elsif (command_name == "say") then
        say(command_arg)
    elsif (command_name == "set_voice") then
        set_voice(command_arg)
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

def process_pre_trackend_command_queue() =
    track_remaining_time = source.remaining(!current_show_source)
    def process_commands(this_command_pair) =
        this_command = fst(this_command_pair)
        this_command_time = snd(this_command_pair)
        if (track_remaining_time <= this_command_time) then
            # do it now! (actually queue it for immediate execution if possible)
            timed_enqueue(this_command, 0.0)
            false # done, doesn't get saved in the updated list
        else
            true
        end
    end
    pre_trackend_command_queue := list.filter(process_commands, !pre_trackend_command_queue) # updated queue
end

def process_trackend_command_queue() =
    def process_trackend_commands (this_command_pair) =
        this_command = fst(this_command_pair)
        this_command_delay = snd(this_command_pair)
        if (this_command_delay <= 0.0) then
            # queue it now!
            timed_enqueue(this_command, 0.0)
        else
            # inject commands with non-zero delay into timed queue
            timed_enqueue(this_command, this_command_delay + 0.0)
        end
        false # just return an empty queue to the filter
    end
    def process_pretrackend_commands(this_command_pair) =
        this_command = fst(this_command_pair)
        this_command_time = snd(this_command_pair)
        # queue it now!
        timed_enqueue(this_command, 0.0)
        false # just return an empty queue to the filter
    end

    remaining_pre_trackend_commands = list.length(!pre_trackend_command_queue)
    if (remaining_pre_trackend_commands > 0) then
        log(string_of(remaining_pre_trackend_commands) ^ " pre-trackend DJ commands present in queue at track's end. Running these first.")
        pre_trackend_command_queue := list.filter(process_pretrackend_commands, !pre_trackend_command_queue) # will just be cleared out
    end

    if (list.length(!trackend_command_queue) > 0) then
        trackend_command_queue := list.filter(process_trackend_commands, !trackend_command_queue) # will just be cleared out
    end
end

# loop that executes commands out of queues at the proper time

def command_loop() =
    now = gettimeofday()
    # check pre_trackend_command_queue
    track_remaining_time = source.remaining(!current_show_source)
    next_pre_trackend_time = snd(list.hd(default=(["", ""], -1.0), !pre_trackend_command_queue))
    if (track_remaining_time <= next_pre_trackend_time) then
        process_pre_trackend_command_queue()
    end
    # check trackend_command_queue
    if (!track_endtime) then
        process_trackend_command_queue()
        track_endtime := false # reset and start waiting for next trackend
    end
    # check timed_command_queue
    next_timed_command_time = snd(list.hd(default=(["", ""], 0.0), !timed_command_queue))
    if (now >= next_timed_command_time and next_timed_command_time != 0.0) then
        process_timed_command_queue()
    end
    0.1
end

add_timeout(0.1, command_loop)





# SERVER FUNCTIONS

def dj_trackend_enqueue (input_string) =
    trimmed_input = string.trim(input_string)
    command_name = ref ""
    command_arg = ref ""
    command_time = ref 0.0
    input_list = string.split(separator=" ", trimmed_input)
    input_list_length = list.length(input_list)
    input_length = string.length(trimmed_input)
    if (input_list_length > 0) then
        command_name := list.nth(default="", input_list, 0)
        last_input = list.nth(default="", input_list, input_list_length-1)
        last_input_as_float = float_of_string(default=0.8686, last_input) # hack to just check if there's a float there or not while allowing positive or negative input
        command_name_length = string.length(!command_name)
        if (last_input_as_float != 0.8686) then # float found, so user provided a delay to be used rather than default
            command_time := last_input_as_float
            command_time_length = string.length(last_input)
            # command_arg is everything between command (at start) and time (at end)
            command_arg := string.sub(trimmed_input, start=command_name_length + 1, length=input_length - command_name_length - command_time_length - 2)
        else
            # command_arg is everything after command (at start)
            command_arg := string.sub(trimmed_input, start=command_name_length + 1, length=input_length - command_name_length - 1)
        end
        if (!command_time >= 0.0) then
            trackend_enqueue([!command_name, !command_arg], !command_time)
        else
            pre_trackend_enqueue([!command_name, !command_arg], 0.0-!command_time)
        end
        "Done"
    else
        "No DJ command provided"
    end
end

def dj_timed_enqueue (input_string) =
    trimmed_input = string.trim(input_string)
    command_name = ref ""
    command_arg = ref ""
    command_time = ref 0.0
    input_list = string.split(separator=" ", trimmed_input)
    input_list_length = list.length(input_list)
    input_length = string.length(trimmed_input)
    if (input_list_length > 0) then
        command_name := list.nth(default="", input_list, 0)
        last_input = list.nth(default="", input_list, input_list_length-1)
        last_input_as_float = float_of_string(default=-1.0, last_input)
        command_name_length = string.length(!command_name)
        if (last_input_as_float >= 0.0) then
            command_time := last_input_as_float
            command_time_length = string.length(last_input)
            # command_arg is everything between command (at start) and time (at end)
            command_arg := string.sub(trimmed_input, start=command_name_length + 1, length=input_length - command_name_length - command_time_length - 2)
        else
            # command_arg is everything after command (at start)
            command_arg := string.sub(trimmed_input, start=command_name_length + 1, length=input_length - command_name_length - 1)
        end
        timed_enqueue([!command_name, !command_arg], !command_time)
        "Done"
    else
        "No DJ command provided"
    end
end

server.register(namespace="dj",
                usage="trackend <command> [<argument>] [<time>]",
                description="Inserts a command into the DJ queue to be run at an optional delay time (s) from track's end\n" ^
                            "  Supported commands:\n" ^
                            "      change_show [show name]\n" ^
                            "      set_fadeout_trackend [true/false]\n" ^
                            "      set_fadeout_instant [true/false]\n" ^
                            "      say [statement]\n" ^
                            "      set_voice [voice name]\n",
                "trackend",
                dj_trackend_enqueue)

server.register(namespace="dj",
                usage="now <command> [<argument>] [<time>]",
                description="Inserts a command into the DJ queue to be run after an optional delay time (s) from now\n" ^
                            "  Supported commands:\n" ^
                            "      change_show [show name]\n" ^
                            "      set_fadeout_trackend [true/false]\n" ^
                            "      set_fadeout_instant [true/false]\n" ^
                            "      say [statement]\n" ^
                            "      set_voice [voice name]\n",
                "now",
                dj_timed_enqueue)





# SET UP AUTOMATED HARBOR SOURCE CONTROL VIA SCHEDULE – AKA AUTO-DJ

current_scheduled_show_name = ref ""
current_scheduled_show_hour = ref 0
current_scheduled_show_time = ref 0.0
next_scheduled_show_name = ref ""
next_scheduled_show_hour = ref 0
next_scheduled_show_time = ref 0.0

def update_current_next_shows () =

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

    # TODO: search for "daysofyear" types first
    todays_indexed_dow_schedules = list.filter(find_todays_dow_types, indexed_schedule_types)
    # is there a top-heirarchy schedule type for today?
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
    prior_indexed_todays_show_hours = list.filter(is_prior_hour, indexed_todays_show_hours) # here is where we actually check the time
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
        log("    Getting first show of tomorrow's schedule...")
        # TODO: search for "daysofyear" types first
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


# auto-dj control loop

default_pulse = 2.0 # seconds between loops if there's no other need
next_pulse = ref 0.0
last_handled_hour_time = ref 0.0 # time of the last hour mark that was "handled" by show switch/station ID

def auto_dj_loop() =
    next_pulse := default_pulse
    now = gettimeofday()
    this_hour = get_current_hour()
#    time_since_last_hour = get_time_since_last_hour()
    track_remaining_time = source.remaining(!current_show_source)
    today_start_time = get_today_start_time()
    track_end_time = now + track_remaining_time

    # startup condition, or just recovery from a problem
    if (!current_show_name == "") then
        update_current_next_shows() # figure out what's supposed to be going on
        log(" *** AUTO-DJ: Starting up with... " ^ !current_scheduled_show_name)
        timed_enqueue(["change_show", !current_scheduled_show_name], 0.0)
        last_handled_hour_time := today_start_time + (float_of_int(this_hour) * 3600.0)
    end
    up_next_hour_time = !last_handled_hour_time + 3600.0

    if (now >= !next_scheduled_show_time) then # always keep the latest schedule info correct, regardless of other logic
        update_current_next_shows()
    end

    # do show signoffs, signons, and station IDs when it's time
    if (now > up_next_hour_time - 60.0 and track_end_time >= up_next_hour_time) then
        log(" *** AUTO-DJ: Time to handle the hour.")
        if (track_end_time < up_next_hour_time + (10.0 * 60.0)) then # do stuff at the trackend
            # NOTE ideally this should be an == without the 100.0s slop, but I don't trust my float times
            if (!next_scheduled_show_time < up_next_hour_time + 100.0 and !next_scheduled_show_name != !current_scheduled_show_name) then
                log (" *** AUTO-DJ: Coming up next... " ^ !next_scheduled_show_name)
                timed_enqueue(["set_fadeout_trackend", "true"], 0.0)
                trackend_enqueue(["change_show", !next_scheduled_show_name], 3.0)
                current_signoff = list.assoc(default="", !current_scheduled_show_name, !show_signoffs)
                if (current_signoff != "") then
                    pre_trackend_enqueue(["say", current_signoff], 40.0)
                end
                next_signon = list.assoc(default=station_spoken_ID, !next_scheduled_show_name, !show_signons)
                if (next_signon != "") then
                    trackend_enqueue(["say", next_signon], 13.0)
                end
            else # no scheduled show switch this hour, so see about doing a station ID
                if (station_spoken_ID != "") then
                    log(" *** AUTO-DJ: Time for a station ID announcement.")
                    pre_trackend_enqueue(["say", station_spoken_ID], 12.0)
                end
            end
        else # it's time to go but the current track ends 10 minutes after the hour, so just do it without waiting for track end.
            # NOTE same as above
            if (!next_scheduled_show_time < up_next_hour_time + 100.0 and !next_scheduled_show_name != !current_scheduled_show_name) then
                log (" *** AUTO-DJ: Coming up next... " ^ !next_scheduled_show_name)
                log (" *** AUTO-DJ: Current track ends more than 10 minutes after the hour. ")
                timed_enqueue(["set_fadeout_instant", "true"], 40.0)
                timed_enqueue(["change_show", !next_scheduled_show_name], 43.0)
                timed_enqueue(["set_fadeout_instant", "false"], 43.1)
                current_signoff = list.assoc(default="", !current_scheduled_show_name, !show_signoffs)
                if (current_signoff != "") then
                    timed_enqueue(["say", current_signoff], 0.0)
                end
                next_signon = list.assoc(default=station_spoken_ID, !next_scheduled_show_name, !show_signons)
                if (next_signon != "") then
                    timed_enqueue(["say", next_signon], 63.0)
                end
            else # no scheduled show switch this hour, so see about doing a station ID right around the hour
                if (station_spoken_ID != "") then
                    log(" *** AUTO-DJ: Time for a station ID announcement.")
                    timed_enqueue(["say", station_spoken_ID], 60.0)
                end
            end
        end
        last_handled_hour_time := up_next_hour_time # one way or the other, this hour is handled and this section won't run again
    end

    !next_pulse
end


# kick off automatic show management
# TODO: make initiating and halting the DJ control loop control board functions

log(" *** Initiating AUTO-DJ...")
add_timeout(0.0, auto_dj_loop) # start it up!! # TODO make starting it up optional







# BUILD THE BROADCAST OUTPUT

broadcast_source = mksafe(on_metadata(logtrack, scheduled_source))

# CREATE THE STREAM
output.icecast(id="broadcast_output",
    station_output_encoding,
    host = station_host, port = station_port,
    password = station_icecast_password, mount = station_mount,
    name = station_name,
    description = station_description,
    genre = station_genre,
    url = station_url, broadcast_source)
