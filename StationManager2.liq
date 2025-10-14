#!/Users/omm/.opam/default/bin/liquidsoap -v
# If not running this from the commandline (such as launchd), make sure to include '--' before the configuration file argument
# ie.: /Users/omm/Basscadet/StationManager2.liq -- stationconfig.json

#<
MIT License

Copyright (c) 2025 Matthew Hine

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
>#

# Designed to run with Liquidsoap v2.4



# LOAD STATIONCONFIG

log("STARTUP")

stationconfig_filename = argv(default="stationconfig.json", 1)
log("STARTUP: Loading station congifuration from " ^ stationconfig_filename)

if not file.exists(stationconfig_filename) then
    shutdown()
end
stationconfig_file = file.contents(stationconfig_filename)


# TODO: Use proper type annotation once it's possible to specify defaults there. Until then, just accept the log warning.
let json.parse stationconfig = stationconfig_file

# TODO: Halt script if certain minimum things aren't set?
# TODO: These should maybe all be refs so that a new config file can be loaded runtime, and so they're okay even if not used

station_showconfig_path = stationconfig.showconfig_path ?? "showconfig.json"
station_showschedule_path = stationconfig.showschedule_path ?? "showschedule.json"
station_specials_path = stationconfig.specials_path ?? "station_specials.json"
station_specials_reqs_path = stationconfig.specials_reqs_path ?? "station_specials_reqs.json"
station_nonrepetition_reqs_path = stationconfig.nonrepetition_reqs_path ?? "station_nonrepetition_reqs.json"
station_playlists_root = ref (stationconfig.playlists_root ?? "music/") # TODO: better way than using ref?

station_icecast_name = stationconfig.icecast_name ?? ""
station_icecast_description = stationconfig.icecast_description ?? ""
%include "encoding_formats.liq"
station_icecast_encoding = list.assoc(default=%mp3, stationconfig.icecast_encoding ?? "mp3_128k", encoding_formats)
station_icecast_host = stationconfig.icecast_host ?? "localhost"
station_icecast_port = stationconfig.icecast_port ?? 8000
station_icecast_mount = stationconfig.icecast_mount ?? "radio.mp3"
station_icecast_genre = stationconfig.icecast_genre ?? ""
station_icecast_url = stationconfig.icecast_url ?? ""
station_icecast_password = stationconfig.icecast_password ?? ""

station_id_announcement = stationconfig.id_announcement ?? ""
station_voice_type = stationconfig.voice_type ?? ""
station_default_voice = stationconfig.default_voice ?? ""
station_tts_server_endpoint = stationconfig.tts_server_endpoint ?? "http://host.docker.internal:3000/say"

station_log_path = stationconfig.log_path ?? "logs/StationManager2.log"
station_tracklog_path = stationconfig.tracklog_path ?? "logs/recent_tracks.log"
station_currentshow_path = stationconfig.currentshow_path ?? "logs/current_show.log"

station_telnet_server = stationconfig.telnet_server ?? false
station_telnet_server_port = stationconfig.telnet_server_port ?? 1234
station_telnet_server_timeout = float_of_int(stationconfig.telnet_server_timeout ?? 60)
station_telnet_server_netmask = stationconfig.telnet_server_netmask ?? "0.0.0.0"

station_announcements_path = stationconfig.announcements_path ?? "announcements/"
station_tts_announcements_path = stationconfig.tts_announcements_path ?? "/tmp/"

station_trackcheck_timeout = stationconfig.trackcheck_timeout ?? 2.0

# Logs setup
if (station_log_path != "") then
    settings.log.file.path.set(station_log_path)
end
# I dunno, this doesn't seem to actually quiet the ffmpeg logs, but leaving it anyway
settings.ffmpeg.log.verbosity.set("quiet")
settings.ffmpeg.log.level := -8

# Don't parse dumb ID3 tags that have image data and throw errors
settings.request.metadata_decoders.recode.exclude := ["id3v2_priv.www.amazon.com", "priv", "apic", "pic", "metadata_block_picture", "coverart"]

# Server setup
if (station_telnet_server) then
    settings.server.telnet.set(station_telnet_server)
    settings.server.telnet.port.set(station_telnet_server_port)
    settings.server.telnet.bind_addr.set(station_telnet_server_netmask)
    settings.server.timeout.set(station_telnet_server_timeout) # negative value disables timeout
end




# LOAD STATION SPECIALS

log("STARTUP: Loading specials...")

# This is your definition for specials to classify tracks with and filter on
#   `name` is your own name for the special, to be referred to in the station_specials_reqs
#   `rules` is a list of rules that must all be fulfilled for a track to be classified with this special
#       `tag` is the metadata tag to use for the rule
#       `filter` is one of a fixed list that defines how to interpret and filter based on the tag:
#           is number equal to
#           is number no less than
#           is number no more than
#           is string
#           is string that includes
#           is timestamp in the last seconds (tag must be in unix time)
#           is year in the last years (tag must be YYYY format)
#           is date in the last days (tag must be YYYY-MM-DD format)
#       `value` is what to measure the rule against
station_specials = ref([])
if (file.exists(station_specials_path)) then
    station_specials_file = file.contents(station_specials_path)
    let json.parse ( new_station_specials :
        [
            {
                name: string,
                rules: [
                    {
                        tag: string,
                        filter: string,
                        value: string
                    }
                ]
            }
        ] ) = station_specials_file 
    station_specials := new_station_specials
else
    log("         Skipping, no specials file found at: " ^ station_specials_path)
end



# LOAD STATION SPECIALS REQUIREMENTS

log("STARTUP: Loading specials requirements...")

# This is your definition for when or how often specials should ideally be played
#   `special_name` refers to one of the specials you defined in station_specials
#   `per_hour_target`, if set, is a target number of plays for the special within a given hour
#   `try_top_of_hour`, if set, tries to play the special as the first thing after an hour switch
# TODO ... also want to implement options for `try_show_start` and `try_show_end`
station_specials_reqs = ref([])
if (file.exists(station_specials_reqs_path)) then
    station_specials_reqs_file = file.contents(station_specials_reqs_path)
    let json.parse ( new_station_specials_reqs :
        [ 
            {
                special_name: string,
                per_hour_target: int,
                try_top_of_hour: bool
            }
        ] ) = station_specials_reqs_file
    station_specials_reqs := new_station_specials_reqs
else
    log("         Skipping, no specials requirements file found at: " ^ station_specials_reqs_path)
end



# LOAD STATION NON-REPEITITION REQUIREMENTS

log("STARTUP: Loading non-repetition requirements...")

# This is your definition for what sorts of repetitions should be disallowed
#   `tag_name` sets a metadata tag to check for repetition ("filename" isn't technically an ID3 tag but can be treated like one here)
#   `dont_repeat_within_last` is one of a fixed list of options for the period during which the tag should not be repeated:
#       track
#       15 minutes
#       hour
#       3 hours
#       12 hours
#       day
station_nonrepetition_reqs = ref([])
if (file.exists(station_nonrepetition_reqs_path)) then
    station_nonrepetition_reqs_file = file.contents(station_nonrepetition_reqs_path)
    let json.parse ( new_station_nonrepetition_reqs :
        [
            {
                tag_name: string,
                dont_repeat_within_last: string
            }
        ] ) = station_nonrepetition_reqs_file
    station_nonrepetition_reqs := new_station_nonrepetition_reqs
else
    log("         Skipping, no specials requirements file found at: " ^ station_specials_reqs_path)
end





# LOAD SHOWCONFIG

log("STARTUP: loading showconfig...")

# TODO: For now just pulling a list of names for the sake of the currentShow.log, need to parse the rest

# TODO should do show_names here too, just as a convenient list of keys for the other lists
show_paths = ref ([]) # ("Beats", "files/Instrumental Hip-Hop"), ("Groovestyle", "files/Stylish Background"), ...
show_longnames = ref ([]) # ("Beats", "Straight Beats"), ("Groovestyle", "Groovestyle"), ...
show_descriptions = ref([]) # ("Beats", "instrumental hip-hop"), ("Groovestyle", "your personal soundtrack")
show_voices = ref ([]) # ("Beats", "Whisper"), ("Groovestyle", "Ava"), ...
show_signon_announcements = ref ([])
show_signoff_announcements = ref ([])
show_shuffle_modes = ref ([])

showconfig_file = file.contents(station_showconfig_path)

let json.parse (show_list : [(
    string * {
        playlist_path: string,
        show_longname: string?,
        show_description: string?,
        DJ_voice: string?,
        signon_announcement: string?, 
        signoff_announcement: string?,
        shuffle_mode: string?  
    }
)] as json.object ) = showconfig_file

def get_show(thisshow) =
    thisshowkey = fst(thisshow) # TODO <-- AKA this_show_name, see note above
    thisshowdata = snd(thisshow)

    # TODO: all these "list.append" usages can probably be list.add... we're just adding one element
    thisshowpath = thisshowdata.playlist_path # this is required - will fail if missing
    show_paths := list.append([(thisshowkey, "#{station_playlists_root()}#{thisshowpath}")], show_paths())
    thisshowlongname = thisshowdata.show_longname ?? "error" # TODO: deal with failure better
    show_longnames := list.append([(thisshowkey, thisshowlongname)], show_longnames())
    thisshowDJvoice = thisshowdata.DJ_voice ?? ""
    show_voices := list.append([(thisshowkey, thisshowDJvoice)], show_voices())
    thissignonannouncement = thisshowdata.signon_announcement ?? ""
    show_signon_announcements := list.append([(thisshowkey, thissignonannouncement)], show_signon_announcements())
    thissignoffannouncement = thisshowdata.signoff_announcement ?? ""
    show_signoff_announcements := list.append([(thisshowkey, thissignoffannouncement)], show_signoff_announcements())
    thisshuffle_mode = thisshowdata.shuffle_mode ?? "songs" # TODO: make actually do something
    show_shuffle_modes := list.append([(thisshowkey, thisshuffle_mode)], show_shuffle_modes())
end

list.iter(get_show, show_list)



# LOAD SHOW SCHEDULE

log("STARTUP: loading show schedule...")

# TODO: Ultimately this should probably be in a func so it can be skipped, and so the file can be re-read for updates

showschedule_types = ref ([]) # "daysofweek", "everyday", ...
showschedule_days = ref ([]) # ["Mondays", "Wednesdays"], [""], ...
showschedule_show_names = ref ([]) # ["Afterparty", "Groovestyle", "Nightmode"], ["Braindance", "Beats"], ...
showschedule_show_hours = ref ([]) # [0, 7, 16], [0, 12], ...

showschedule_file = file.contents(station_showschedule_path)

# no optioanl types here - all required as shown to have a valid schedule
let json.parse (showschedule_list : [{
        type: string,
        days: [string],
        show_names: [string],
        show_hours: [int]
    }]
) = showschedule_file

def get_showschedule(thisshowschedule) =
    this_type = thisshowschedule.type ?? "everyday" # TODO: check default handling?
    showschedule_types := list.append([this_type], showschedule_types())
    this_days = thisshowschedule.days ?? [""] # TODO: check default handling?
    showschedule_days := list.append([this_days], showschedule_days())
    this_show_names = thisshowschedule.show_names ?? [""] # TODO: check default handling?
    showschedule_show_names := list.append([this_show_names], showschedule_show_names())
    this_show_hours = thisshowschedule.show_hours ?? [0] # TODO: check default handling?
    showschedule_show_hours := list.append([this_show_hours], showschedule_show_hours())
end
    
list.iter(get_showschedule, showschedule_list)





# --- BROADCAST --------------------------------------------------------------------


# SET UP BROADCAST WITH DYNAMIC SOURCE

log("STARTUP: setting up dynamic broadcast...")

# Create current_output_source. Changing source contents of this will change what is broadcast, using the dynamic broadcast_source
current_output_source = ref(blank())

# Handler to get the current dynamic source
def get_source_for_broadcast() =
    current_output_source()
end

broadcast_source = source.dynamic(id="broadcast_source", get_source_for_broadcast)

def dynsource_handle_shutdown() =
    log("    Dynamic source SHUTDOWN")
end

def dynsource_handle_wake_up() =
    log("    Dynamic source WAKE UP")
end

# add handles on status
broadcast_source.on_shutdown(synchronous=true, dynsource_handle_shutdown)
broadcast_source.on_wake_up(synchronous=true, dynsource_handle_wake_up)

# Create final broadcast output to public icecast
output.icecast(
    id="broadcast_output",
    station_icecast_encoding,
    host = station_icecast_host,
    port = station_icecast_port,
    password = station_icecast_password,
    mount = station_icecast_mount,
    name = station_icecast_name,
    description = station_icecast_description,
    genre = station_icecast_genre,
    url = station_icecast_url,
    mksafe(broadcast_source))
    

    

# --- SHOW CONTROL --------------------------------------------------------------------


# METADATA FUNCTIONS, INCLUDING LOGGING

# metadata cache, so we can delay resolving requests, and to avoid continually looking up metadata from files themselves unnecessarily
track_metadata_cache = ref([]) # [("/music/playlist/01-trackname.mp3", [("artist", "Big Name"), ... ]), ...]

# list of readable recent tracks to dump to log
recent_tracks = ref ([])
new_tracklog = ref ("")

# Get metadata for a request, from cache if possible, resolved if necessary
def get_metadata_for_request(this_request)
    this_filename = request.uri(this_request)
    cached_metadata = list.assoc(default=[("","")], this_filename, track_metadata_cache())
    if ( cached_metadata != [("","")] ) then # already cached, return it
        cached_metadata
    else # gotta look it up and cache it for the future
        ignore(request.resolve(this_request))
        new_metadata = request.metadata(this_request)
        # update cache
        track_metadata_cache := list.append(track_metadata_cache(), [(this_filename, new_metadata)])
        new_metadata
    end
end

# Get a metadata tag's value, including dealing with weird ID3 ambiguities
def get_metadata_value(this_tag, this_metadata)
    if ( this_tag == "date" or this_tag == "year" ) then
        # "date" is technically deprecated in favor of "year", but lots of tracks have
        # used date, so most software just treats both tags as "year". we'll try to be
        # as nice as we can here.
        this_date = list.assoc(default="", "date", this_metadata)
        this_year = list.assoc(default="", "year", this_metadata)
        if ( this_date == "" and this_year == "" ) then
            ""
        elsif ( this_date == "" and this_year != "" ) then
            this_year
        elsif ( this_date != "" and this_year == "" ) then
            this_date
        else
            # if they're both set, return the one that was specifically requested
            if this_tag == "date" then
                this_date
            else
                this_year
            end
        end
    elsif ( this_tag == "artist") then
        # when asking for "artist", albumartist may be a reasonable thing to use anyway
        this_artist = list.assoc(default="", "artist", this_metadata)
        this_albumartist = list.assoc(default="", "albumartist", this_metadata)
        if ( this_artist == "" and this_albumartist == "") then
            ""
        elsif ( this_artist == "" and this_albumartist != "") then
            this_albumartist
        elsif ( this_artist != "" and this_albumartist == "") then
            this_artist
        else
            # if they're both set, prefer albumartist
            this_albumartist
        end
    else
        # the tag isn't any of our special cases, so just get what's in there and return it
        list.assoc(default="", this_tag, this_metadata)
    end
end

# Write stuff whenever there's new metadata
def addtotracklog(nexttrack) =
  new_tracklog := string.concat([new_tracklog(), nexttrack, "\n"])
end

def logtrack(this_metadata) =
    # TODO (maybe, if still relevant) don't log if the info is blank or "-" or whatever at show changes
    if (station_tracklog_path != "") then
        artist = get_metadata_value("artist", this_metadata)
        album = get_metadata_value("album", this_metadata)
        title = get_metadata_value("title", this_metadata)
        newline="#{artist} - #{album} - #{title}"
        recent_tracks := list.add(newline, recent_tracks())
        if (list.length(recent_tracks()) > 20) then
            recent_tracks := list.rev(list.tl(list.rev(recent_tracks())))
        end
        new_tracklog := ""
        list.iter(addtotracklog, recent_tracks())
        ignore(
            file.write(
                data=new_tracklog(),
                append=false,
                station_tracklog_path
            )
        )
    end
end


# TIME FUNCTIONS FOR CONTROL BOARD

def get_weekday_name(week_day_int) =
    daymapping = [
        (0, "Sunday"),
        (1, "Monday"),
        (2, "Tuesday"),
        (3, "Wednesday"),
        (4, "Thursday"),
        (5, "Friday"),
        (6, "Saturday")
    ]
    list.assoc(default="error", week_day_int, daymapping)
end

def get_today() =
    get_weekday_name(time.local().week_day)
end

def get_tomorrow() =
    get_weekday_name(time.local(time()+86400.0).week_day)
end

def get_current_hour() =
    time.local().hour
end

def get_time_since_midnight() =
    this_sec = time.local().sec
    this_min = time.local().min
    this_hour = time.local().hour
    float_of_int(this_sec + (this_min * 60 + (this_hour * 3600)))
end

def get_time_since_last_hour() =
    this_sec = time.local().sec
    this_min = time.local().min
    float_of_int(this_sec + (this_min * 60))      
end

def get_time_since_last_hour_at(this_time)
    this_sec = time.local(this_time).sec
    this_min = time.local(this_time).min
    float_of_int(this_sec + (this_min * 60))      
end

# returns the unixtime at midnight at the start of today
def get_today_start_time() =
    now = time()
    time_since_midnight = get_time_since_midnight()
    now - time_since_midnight
end

# Convert from YYYY-MM-DD format to unix timestamp float
def time_from_YMD(YMD_string) 
    YMD_list = string.split(separator="-", YMD_string)
    if list.length(YMD_list) == 3 then
        time.make({
            year=int_of_string(list.nth(YMD_list, 0)),
            month=int_of_string(list.nth(YMD_list, 1)),
            day=int_of_string(list.nth(YMD_list, 2)),
            hour=0, min=0, sec=0, dst=false
        })
    else
        0.0
    end
end



# DJ CONTROL BOARD FUNCTIONS

current_show_name = ref ("") # name of actual broadcasting show (independent of schedule - if there even is one)
current_show_source = ref (blank()) # the current show playlist source that can be monitored or controlled
current_voice = ref ("") # name of current voice to use for synthesized DJ statements

fadeout_trackend = ref (false)
fadeout_instant = ref (false)

track_endtime = ref (false)

timed_command_queue = ref ([]) # [([commandname, arg], exec_unixtime), ...]
trackend_command_queue = ref ([]) # [([commandname, arg], exec_delay_after_trackend), ...]
pre_trackend_command_queue = ref ([]) # [([commandname, arg], exec_time_before_trackend), ...]

# keep track of specials plays what specials requirements are overdue
specials_req_overdue_states = ref([]) # [ ("Best Of", false), (...) ]
overdue_special_names = ref([]) # [ "Best Of", "90s Jams", ... ]
specials_hour = ref(time.local().hour)
specials_plays_this_hour = ref([]) # [ ("Best Of", 3), (...) ] - resets at the hour
specials_day = ref(time.local().day)
specials_plays_today = ref([]) # [ ("Best Of", 3), (...) ] - resets at midnight
specials_plays_continuous = ref([]) # [ ("Best Of", 3), (...) ] - never resets

# keep a cache of the specials each track matches to avoid repeated complicated analysis of metadata
track_special_matches_cache = ref([])
    # [
    #     ( "/path/to/file.mp3", ["Best Of", "Last 30-day Adds"] ),
    #     ( "/some/other/file.mp3", ["Best Of"] )
    # ]

# keep track of when various types of things played for repetition filtering
last_plays_cache = ref([])
    # [
    #     ("album", [("Oversteps", 1749521413.0), ("ISDN", 1749521413.0)]),
    #     ("filename", [("/path/to/music.mp3", 1749521413.0), "/some/other/file.mp3", 1749521413.0])
    # ]




# Source/track processing functions

# Return the list of this station's specials that the track in question matches
def classify_track(this_metadata)

    # Set the context for the track for handlers
    classifying_track_metadata = ref(this_metadata)

    # Iterator to see if each rule is met
    def check_rule(this_rule)
        # bunch of logic to check classifying_track_metadata against this_rule.tag/.filter/.value
        this_tag = this_rule.tag
        this_filter = this_rule.filter
        this_value = this_rule.value
        track_value = get_metadata_value(this_tag, classifying_track_metadata())

        if ( this_tag == "" or this_value == "" ) then
            # rule is incompletely defined... I guess we consider it "met"
            log("WARNING: Missing special tag or value - special cannot be satisfied")
            true
        elsif this_filter == "is number equal to" then
            track_value_float = float_of_string(track_value, default=0.0)    
            this_value_float = float_of_string(this_value)
            track_value_float == this_value_float
        elsif this_filter == "is number no less than" then
            track_value_float = float_of_string(track_value, default=0.0)
            this_value_float = float_of_string(this_value)
            track_value_float >= this_value_float
        elsif this_filter == "is number no more than" then
            track_value_float = float_of_string(track_value, default=0.0)
            this_value_float = float_of_string(this_value)
            track_value_float <= this_value_float
        elsif this_filter == "is string" then
            track_value == this_value
        elsif this_filter == "is string that includes" then
            string.contains(substring=this_value, track_value)
        elsif this_filter == "is timestamp in the last seconds" then
            track_value_timestamp = float_of_string(track_value, default=0.0)
            this_value_time = float_of_string(this_value)
            (time() - track_value_timestamp) <= this_value_time
        elsif this_filter == "is year in the last years" then # YYYY
            track_value_year = int_of_string(track_value, default=0)    
            this_value_year = int_of_string(this_value)
            (time.local().year - track_value_year) <= this_value_year
        elsif this_filter == "is date in the last days" then # YYYY-MM-DD
            track_value_time = time_from_YMD(track_value)
            this_value_time = time_from_YMD(this_value)
            if this_value_time == 0.0 then
                # bogus filter, consider it "met"
                log("WARNING: Invalid YYYY-MM-DD format used in special definition - special cannot be satisfied")
                true
            elsif track_value_time == 0.0 then
                # track doesn't have anything to check against filter, don't consider it met
                false
            else
                (time() - track_value_time) <= this_value_time
            end
        else
            # again, if it's a bogus filter, then I guess consider it "met"
            log("WARNING: Unsupported special requirement rule filter encountered")
            true
        end
    end

    # Iterator to determine which specials a track fits
    def check_special(this_special)
        # iterate through rules, only add the special name if *all* rules are true
        if list.for_all(check_rule, this_special.rules) then
            this_special.name
        else
            null
        end
    end

    # Start the classification process
    this_filename = this_metadata["filename"]
    cached_specials_matched = list.assoc(default=[], this_filename, track_special_matches_cache())
    if cached_specials_matched != [] then # already classified
        # return the cached results
        cached_specials_matched
    else
        # iterate through station_specials to see which match this file, returning a list of matched specials
        specials_matched = list.filter_map(check_special, station_specials())
        # update the cache
        track_special_matches_cache := list.add((this_filename, specials_matched), track_special_matches_cache())
        # return the (now cached) results
        specials_matched
    end
end


# Keep track of some things *between calls* to is_request_approved, so we can be smarter when churning through request rejections
last_current_track_checked = ref("")
number_request_checks = ref(0)
time_request_check_start = ref(0.0)

# Called as source's check_next - decide if the next request should be played or not based on specials and repetition rules
def is_request_approved(req) =

    # Find out what the proposed request to play next is and consider its suitability
    next_request_filename = request.uri(req)
    next_request_metadata = ref([]) # don't get it until we know it's a valid file

    # big function to see what specials state we'll be in, considering the currently playing track **at the time when it finishes**
    # intended to be called just after a track has started playing, although it does avoid redundant tallying if called more than once during a track
    def update_specials_and_last_played_state()
        # get the playing track (likely just started as the next playlist request)
        current_track_metadata = current_show_source().last_metadata() ?? []
        current_track_remaining = source.remaining(current_show_source())
        current_track_filename = current_track_metadata["filename"]

        top_of_hour_play = ref(false)

        def increment_specials_plays(this_special_name)
            this_hour_playcount = list.assoc(default=0, this_special_name, specials_plays_this_hour())
            specials_plays_this_hour := list.add((this_special_name, this_hour_playcount + 1), list.assoc.remove(this_special_name, specials_plays_this_hour()))
            today_playcount = list.assoc(default=0, this_special_name, specials_plays_today())
            specials_plays_today := list.add((this_special_name, today_playcount + 1), list.assoc.remove(this_special_name, specials_plays_today()))
            continuous_playcount = list.assoc(default=0, this_special_name, specials_plays_continuous())
            specials_plays_continuous := list.add((this_special_name, continuous_playcount + 1), list.assoc.remove(this_special_name, specials_plays_continuous()))
        end

        # update state of specials and repetitions, if we haven't done so for the playing track
        if last_current_track_checked() != current_track_filename then # only do this once per track switch
            
            last_current_track_checked := current_track_filename

            # get the specials the playing track matches
            track_special_names = classify_track(current_track_metadata)
            # increment specials play counts with the the track_special_names, for the *current* time
            list.iter(increment_specials_plays, track_special_names)
            log("Updated specials play count for the " ^ string(specials_hour()) ^ ":00 hour with track " ^ current_track_filename ^ "\n    " ^ string(specials_plays_this_hour()))

            # if it will be a new hour at the *end* of this track, clear specials tracking for last hour
            # and reset current hour so we register this track's specials toward next hour
            time_at_track_end = time() + current_track_remaining
            hour_of_track_end = time.local(time_at_track_end).hour
            day_of_track_end = time.local(time_at_track_end).day
            if specials_hour() != hour_of_track_end then
                log("Next track will start in a new hour of specials!")
                specials_req_overdue_states := []
                specials_plays_this_hour := []
                specials_hour := hour_of_track_end
                top_of_hour_play := true
            else
                top_of_hour_play := false
            end
            if specials_day() != day_of_track_end then
                log("Next track will start in a new day!\nTotal specials plays today: " ^ string(specials_plays_today()) ^ "\nSpecials plays since launch: " ^ string(specials_plays_continuous()))
                specials_plays_today := []
                specials_day := day_of_track_end
            end

            # update specials_req_overdue_states **for time at the expected end of current track**

            # iterator to figure out the overdue status of a given special requirement
            def get_special_state(this_special_reqs)

                this_special_name = this_special_reqs.special_name # "Best Of"
                this_per_hour_target = this_special_reqs.per_hour_target ?? 0
                this_try_top_of_hour = this_special_reqs.try_top_of_hour ?? false
                this_special_overdue_state = ref(false)
                
                # TODO: add more options like perhaps try_show_end, try_show_start, per_day_target, per_show_target ?
                if this_try_top_of_hour and top_of_hour_play() then
                    # per_hour_target doesn't matter - top_of_hour requirement makes this special immediately overdue
                    this_special_overdue_state := true
                elsif this_per_hour_target > 0 then
                    # let's see about the per-hour target
                    req_period = 3600.0 / float_of_int(this_per_hour_target)
                    expected_time_since_hour = get_time_since_last_hour_at(time() + current_track_remaining) # at end of current track
                    target_plays = int_of_float(floor( (expected_time_since_hour + (req_period / 2.0)) / req_period ) )
                        # important math... for example:
                        # 1 play per hour adds target_play increment at 30 minute mark
                        # 3 plays per hour adds target_play increments at 10, 30, and 50 minute marks
                    actual_plays = list.assoc(default=0, this_special_name, specials_plays_this_hour())
                    if target_plays > actual_plays then
                        # we're behind - make this overdue
                        this_special_overdue_state := true
                    end
                end 

                (this_special_name, this_special_overdue_state())
            end

            new_specials_overdue_states = list.map(get_special_state, station_specials_reqs())
            specials_req_overdue_states := new_specials_overdue_states

            # Update last_plays_cache based on current_track's metadata
            # log("Updating last play times with: " ^ current_track_filename)
            def get_updated_last_plays_for_each_required_tag_name(this_nonrepetition_req)
                this_tag_name = this_nonrepetition_req.tag_name
                this_last_plays = list.assoc(default=[], this_tag_name, last_plays_cache())

                tag_of_current_track = list.assoc(default="", this_tag_name, current_track_metadata)
                updated_this_last_plays = list.add((tag_of_current_track, time()), list.assoc.remove(tag_of_current_track, this_last_plays))
                (this_tag_name, updated_this_last_plays)
            end

            last_plays_cache := list.map(get_updated_last_plays_for_each_required_tag_name, station_nonrepetition_reqs())
        end
    end

    def return_special_name_if_overdue(this_special_req_overdue_state)
         let (special_name, state) = this_special_req_overdue_state
        # only return the req_name if its overdue state is true
        if state then
            special_name
        else
            null
        end
    end

    classified_track_special_names = ref([]) # ["Best Of", "Last 30-day Adds"]

    def does_classified_track_include_special(this_special_name)
        list.exists(fun(x) -> x == this_special_name, classified_track_special_names())
    end

    def is_nonrepetition_req_satisfied(this_req)
        this_tag_name = this_req.tag_name
        this_dont_repeat_within_last = this_req.dont_repeat_within_last

        tag_of_this_track = list.assoc(default="", this_tag_name, next_request_metadata())
        within_time = ref(0.0)
        if this_dont_repeat_within_last == "track" then
            playing_track_metadata = current_show_source().last_metadata() ?? []
            tag_of_playing_track = list.assoc(default="", this_tag_name, playing_track_metadata)
            if tag_of_this_track == tag_of_playing_track then
                false
            else
                true
            end
        else
            if this_dont_repeat_within_last == "15 minutes" then
                within_time := 900.0
            elsif this_dont_repeat_within_last == "hour" then
                within_time := 3600.0
            elsif this_dont_repeat_within_last == "3 hours" then
                within_time := 10800.0
            elsif this_dont_repeat_within_last == "12 hours" then
                within_time := 43200.0
            elsif this_dont_repeat_within_last == "day" then
                within_time := 86400.0
            end

            last_plays_for_tag_name = list.assoc(default=[("",0.0)], this_tag_name, last_plays_cache())
            last_play = list.assoc(default=0.0, tag_of_this_track, last_plays_for_tag_name)

            if time() - last_play < within_time() then
                false
            else
                true
            end
        end
    end

    # Okay, with definitions done, let's get started with seeing if the requested track is good to go

    # make sure specials state is correct before looking at anything else, but don't repeat this if we've already done it at this track change
    if number_request_checks() < 1 then
        time_request_check_start := time() # start the clock on checks
        update_specials_and_last_played_state()
        # get list of the names of overdue requirements
        overdue_special_names := list.filter_map(return_special_name_if_overdue, specials_req_overdue_states())
        log("Overdue specials at end of this track: " ^ string(overdue_special_names()))
    end

    # log("CHECKING REQUEST: " ^ next_request_filename)
    number_request_checks := number_request_checks() + 1

    # Reject immediately if this is a dumb hidden file like .DS_store
    file_only_name = list.last(string.split(separator="/", next_request_filename))
    if (string.sub(file_only_name, start=0, length=1) == ".") then
        # log("REJECTED - Hidden file - not a valid track!")
        false
    else
        # If finding an approved track is taking too long, give up and move on to avoid latency problems
        if time() > time_request_check_start() + station_trackcheck_timeout then
            log("APPROVED " ^ next_request_filename ^ " - " ^ string(number_request_checks()) ^ " tries failed to meet requirements within " ^ string(station_trackcheck_timeout) ^ " seconds, so accepting this track to move on!")
            number_request_checks := 0
            true
        else
            next_request_metadata := get_metadata_for_request(req)

            #<
            md_for_log = next_request_metadata()
            # some raw dumping of specific fields
            log("TITLE:        " ^ md_for_log["title"])
            log("ALBUM:        " ^ md_for_log["album"])
            log("ARTIST:       " ^ md_for_log["artist"])
            log("ALBUM ARTIST: " ^ md_for_log["albumartist"])
            log("DATE:         " ^ md_for_log["date"])
            log("YEAR:         " ^ md_for_log["year"])
            # of if you want to take a look at all metadata (incl. album art)... but it's a lot
            # log(string(md_for_log))
            >#

            # Reject if the track is a repetition that violates the stations rules
            all_repetition_rules_satisfied = list.for_all(is_nonrepetition_req_satisfied, station_nonrepetition_reqs())
            if not all_repetition_rules_satisfied then
                # log("REJECTED - Track violates at least one repetition rule!")
                false
            else
                # Classify the track's specials and see if it meets any overdue specials requirements

                # classify the track no matter what, even if no speicials are overdue, to build up the cache if nothing else
                classified_track_special_names := classify_track(next_request_metadata())
                # log("Track matches specials: " ^ string(classified_track_special_names()))
                
                if list.length(overdue_special_names()) > 0 and not list.exists(does_classified_track_include_special, overdue_special_names()) then
                    # try again...
                    # log("REJECTED - Track doesn't meet any of the currently overdue requirements!")
                    false
                else
                    # success!
                    log("APPROVED " ^ next_request_filename ^ " " ^ string(classified_track_special_names()) ^ " after " ^ string(number_request_checks()) ^ " tries. Will meet requirements!")
                    # reset the counter and approve this track to play next
                    number_request_checks := 0
                    true
                end
            end
        end
    end
end




# Command queue management functions

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
    now = time()
    command_time = now + exec_delay # needs to be ref to be visible within func below?
    log("Timed DJ command received:         " ^ string(command) ^ " with execution set to " ^ string(exec_delay) ^ " seconds from now")
    command_pair = [(command, command_time)] # timed queue uses absolute times for execution
    timed_command_queue := list.append(timed_command_queue(), command_pair)
    # now sort it by time (least first) so we can just check the head of the list in the command loop
    timed_command_queue := list.sort(sort_command_queue_by_time_ascending, timed_command_queue())
    # log("timed command queue now: " ^ string(timed_command_queue()))
end

def trackend_enqueue(command, exec_delay) =
    log("Trackend DJ command received:      " ^ string(command) ^ " with execution delay: " ^ string(exec_delay) ^ " after end of this track")
    command_pair = [(command, exec_delay)] # trackend queue uses a delay, all of which can be turned into fixed timed_enqueue requests at track end
    trackend_command_queue := list.append(trackend_command_queue(), command_pair)
    # log("trackend command queue now: " ^ string(trackend_command_queue()))
end

def pre_trackend_enqueue(command, exec_delay) =
    log("Pre-trackend DJ command received:  " ^ string(command) ^ " with execution time: " ^ string(exec_delay) ^ " before end of this track")
    command_pair = [(command, exec_delay)]
    pre_trackend_command_queue := list.append(pre_trackend_command_queue(), command_pair)
    # now sort it by pre-trackend delay (largest first) so we can just check the head of the list in the command loop
    pre_trackend_command_queue := list.sort(sort_command_queue_by_time_descending, pre_trackend_command_queue())
    # log("pre-trackend command queue now: " ^ string(pre_trackend_command_queue()))
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

def set_fadeout_instant(arg) =
    if (arg == "true") then
        fadeout_instant := true
    elsif (arg == "false") then
        fadeout_instant := false
    else
        log("Bad arg to set_fadeout_instant")
    end
end

playover_source = request.queue(id="playover_source") # removed audio_to_stereo at v2.0

def set_voice(voicename) =
    newvoice = ref ("")
    if (voicename == "normal") then
        newvoice := station_default_voice
        showvoice = list.assoc(default="", current_show_name(), show_voices())
        if (showvoice != "") then
            newvoice := showvoice
        end
    else
        newvoice := voicename
    end
    current_voice := newvoice()
    log("   New voice selected: " ^ newvoice())
end


def playover(file_path) =
    # Queue up the speech along with some bookending silence
    playover_source.push(request.create("synth:shape=sine,frequency=0.0,duration=3"))
    playover_source.push(request.create("file:" ^ file_path))
    playover_source.push(request.create("synth:shape=sine,frequency=0.0,duration=1"))
end

def say(thing_to_say) =
    suffix = string.lowercase(string.sub(thing_to_say, start=(string.length(thing_to_say) - 4), length=4))
    if (suffix==".wav" or suffix==".mp3" or suffix==".ogg") then
        playover(station_announcements_path ^ thing_to_say)
    # TODO add more voice types, whether using tts_server or LS-native approach (non-docker only)    
    elsif (station_voice_type == "tts_server_macos") then
        say_request = {
            tts_type="macos",
            voice=current_voice(),
            text=thing_to_say,
        }
        json_say_request = json.stringify(say_request)

        # call the TTS server endpoint
        json_say_response = http.post(data=json_say_request, timeout=30.0, station_tts_server_endpoint)


        try
            # parse JSON response. using optional annotations mostly to avoid the warning in logs
            let json.parse ( say_response :
                {
                    result: string?,
                    data: string?
                }?
            ) = json_say_response
            result = say_response.result ?? "ERROR"
            data = say_response.data ?? "Bad response from TTS server"
            if (result == "SUCCESS") then
                # TODO probably should also check to see if there's a valid wav or something ideally.
                say_file_path = station_tts_announcements_path ^ data
                playover(say_file_path)
            else
                tts_error = data
                log("TTS error: " ^ tts_error)
            end
        catch err do
            log("Request to TTS server failed...\n    Kind: " ^ err.kind ^ "\n    Message: " ^ err.message)
        end 
    else
        log("Station voice_type not supported. SAY command ignored.")
    end
end


def skip () =
    source.skip(current_show_source()) 
    log("Skipping to next track in playlist!")
end


# show management functions (plus change_show queueable command)

def handle_track_end(this_metadata) =
    ignore(this_metadata)
    log("  - track change signal -")
    track_endtime := true # triggers the command_loop
end


def change_show(show_name) =
    if (list.assoc(default="error", show_name, show_paths()) != "error") then
        log("  --- New show starting: " ^ show_name ^ " ------------------------------------")
    
        show_path = list.assoc(default="error", show_name, show_paths())

        # The check_next handler kicks off checking if the potentially-next track meets specified requirements
        show_source = playlist(id="scheduled_show_playlist", check_next=is_request_approved, register_server_commands=false, show_path)
        
        # TODO consider switching to on_track (rather than on_metadata), which might avoid bogus metadata... same arguments and everything, one-line change
        show_source.on_metadata(synchronous=false, logtrack) # NOTE - this previously was part of line above... docs seemingly lying about this returning source, not unit
        current_show_source := show_source
    
        # TODO maybe use noise() or sine() instead of blank() to prevent players from disconnecting (supposedly)

        # First, disconnect the current source from the dynamic source before doing some prep for the new show
        current_output_source := blank()

        # We can't let the new source start up with this "true" because it will be stuck that way (track end to reevaluate will never come)
        set_fadeout_trackend("false")

        # Now create the new source for broadcast
        show_source_with_switches = 
            switch(id="fadeout_instant_handler", track_sensitive=false, [ ({fadeout_instant() == true}, blank()), ({true},
                switch(id="fadeout_trackend_handler", track_sensitive=true, [ ({fadeout_trackend() == true}, blank()), ({true},
                    show_source
                ) ] )
            ) ] )
        show_source_with_switches.on_track(synchronous=true, handle_track_end)
        new_output_source = smooth_add(duration=1.5, p=0.1, special=playover_source, normal=show_source_with_switches)

        # Set the source used by the dynamic broadcast source
        current_output_source := new_output_source
    

        current_show_name := show_name
        current_show_longname = list.assoc(default="", show_name, show_longnames())
        set_voice("normal")
        ignore(
            file.write(
                    data=current_show_longname,
                    append=false,
                    station_currentshow_path
                )
        )
    else
        log("No playlist path specified for requested show: " ^ show_name)
    end

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
    elsif (command_name == "skip") then
        skip()
    else
        log("   \"#{command_name}\" is not a supported command!")
    end
    #TODO moar commands
end

def process_timed_command_queue() =
    now = time()
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
    timed_command_queue := list.filter(process_commands, timed_command_queue()) # updated queue
end

def process_pre_trackend_command_queue() =
    track_remaining_time = source.remaining(current_show_source())
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
    pre_trackend_command_queue := list.filter(process_commands, pre_trackend_command_queue()) # updated queue
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

    remaining_pre_trackend_commands = list.length(pre_trackend_command_queue())
    if (remaining_pre_trackend_commands > 0) then
        log(string(remaining_pre_trackend_commands) ^ " pre-trackend DJ commands present in queue at track's end. Running these first.")
        pre_trackend_command_queue := list.filter(process_pretrackend_commands, pre_trackend_command_queue()) # will just be cleared out
    end

    if (list.length(trackend_command_queue()) > 0) then
        trackend_command_queue := list.filter(process_trackend_commands, trackend_command_queue()) # will just be cleared out
    end
end

# loop that executes commands out of queues at the proper time

def command_loop() =
    now = time()
    # check pre_trackend_command_queue
    track_remaining_time = source.remaining(current_show_source())
    next_pre_trackend_time = snd(list.hd(default=(["", ""], -1.0), pre_trackend_command_queue()))
    if (track_remaining_time <= next_pre_trackend_time) then
        process_pre_trackend_command_queue()
    end
    # check trackend_command_queue
    if (track_endtime()) then
        track_endtime := false # reset to start waiting for next trackend
        process_trackend_command_queue()
    end
    # check timed_command_queue
    next_timed_command_time = snd(list.hd(default=(["", ""], 0.0), timed_command_queue()))
    if (now >= next_timed_command_time and next_timed_command_time != 0.0) then
        process_timed_command_queue()
    end
    0.1
end

thread.run.recurrent(delay=0.1, command_loop)





# SERVER FUNCTIONS

# commands for auto DJ

def dj_trackend_enqueue(input_string) =
    trimmed_input = string.trim(input_string)
    command_name = ref ("")
    command_arg = ref ("")
    command_time = ref (0.0)
    input_list = string.split(separator=" ", trimmed_input)
    input_list_length = list.length(input_list)
    input_length = string.length(trimmed_input)
    if (input_list_length > 0) then
        command_name := list.nth(default="", input_list, 0)
        last_input = list.nth(default="", input_list, input_list_length-1)
        last_input_as_float = float_of_string(default=0.8686, last_input) # hack to just check if there's a float there or not while allowing positive or negative input
        command_name_length = string.length(command_name())
        if (last_input_as_float != 0.8686) then # float found, so user provided a delay to be used rather than default
            command_time := last_input_as_float
            command_time_length = string.length(last_input)
            # command_arg is everything between command (at start) and time (at end)
            command_arg := string.sub(trimmed_input, start=command_name_length + 1, length=input_length - command_name_length - command_time_length - 2)
        else
            # command_arg is everything after command (at start)
            command_arg := string.sub(trimmed_input, start=command_name_length + 1, length=input_length - command_name_length - 1)
        end
        if (command_time() >= 0.0) then
            trackend_enqueue([command_name(), command_arg()], command_time())
        else
            pre_trackend_enqueue([command_name(), command_arg()], 0.0-command_time())
        end
        "Done"
    else
        "No DJ command provided"
    end
end

def dj_timed_enqueue(input_string) =
    trimmed_input = string.trim(input_string)
    command_name = ref ("")
    command_arg = ref ("")
    command_time = ref (0.0)
    input_list = string.split(separator=" ", trimmed_input)
    input_list_length = list.length(input_list)
    input_length = string.length(trimmed_input)
    if (input_list_length > 0) then
        command_name := list.nth(default="", input_list, 0)
        last_input = list.nth(default="", input_list, input_list_length-1)
        last_input_as_float = float_of_string(default=-1.0, last_input)
        command_name_length = string.length(command_name())
        if (last_input_as_float >= 0.0) then
            command_time := last_input_as_float
            command_time_length = string.length(last_input)
            # command_arg is everything between command (at start) and time (at end)
            command_arg := string.sub(trimmed_input, start=command_name_length + 1, length=input_length - command_name_length - command_time_length - 2)
        else
            # command_arg is everything after command (at start)
            command_arg := string.sub(trimmed_input, start=command_name_length + 1, length=input_length - command_name_length - 1)
        end
        timed_enqueue([command_name(), command_arg()], command_time())
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
                "      set_voice [voice name]\n" ^
                "      skip\n",
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
                "      set_voice [voice name]\n" ^
                "      skip\n",
    "now",
    dj_timed_enqueue)

# commands for station control board

def station_get_specials(input_string) = 
    trimmed_input = string.trim(input_string)
    if trimmed_input == "this_hour" then
        json.stringify(specials_plays_this_hour())
    elsif trimmed_input == "today" then
        json.stringify(specials_plays_today())
    elsif trimmed_input == "continuous" then
        json.stringify(specials_plays_continuous())
    else
        "ERROR invalid timeframe specified, choose one of: this_hour, today, or continuous"
    end
end

server.register(namespace="station",
    usage="specials <this_hour|today|continuous>",
    description="Returns a JSON array of the counts of specials that have played during the specified timeframe",
    "specials",
    station_get_specials)



                
# --- AUTO DJ --------------------------------------------------------------------
# TODO probably should move relevant json importing stuff down here

# SET UP AUTOMATED DYNAMIC SOURCE CONTROL VIA SCHEDULE – AKA AUTO-DJ

current_scheduled_show_name = ref ("")
current_scheduled_show_hour = ref (0)
current_scheduled_show_time = ref (0.0)
next_scheduled_show_name = ref ("")
next_scheduled_show_hour = ref (0)
next_scheduled_show_time = ref (0.0)

def update_current_next_shows () =

    def add_indices(this_index, this_listitem) =
        (this_index, this_listitem)
    end

    def find_todays_dow_types (listpair) =
        this_index = fst(listpair)
        this_type = snd(listpair)
        deez_schedule_days = list.nth(default=[""], showschedule_days(), this_index)
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
        deez_schedule_days = list.nth(default=[""], showschedule_days(), this_index)
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

    log(" *** AUTO-DJ: Updating current and next scheduled shows...")
    todays_schedule_index = ref (0)
    todays_show_names = ref ([])
    todays_show_hours = ref ([0])
    tomorrows_schedule_index = ref (0)
    tomorrows_show_names = ref ([])
    tomorrows_show_hours = ref ([0])

    today_start_time = get_today_start_time()
    tomorrow_start_time = today_start_time + 86400.0
    indexed_schedule_types = list.mapi(add_indices, showschedule_types())

    # TODO: search for "daysofyear" types first
    todays_indexed_dow_schedules = list.filter(find_todays_dow_types, indexed_schedule_types)
    # is there a top-heirarchy schedule type for today?
    if (list.length(todays_indexed_dow_schedules) > 0) then
        todays_schedule_index := fst(list.hd(default=(0, ""), todays_indexed_dow_schedules))
        todays_show_names := list.nth(default=[""], showschedule_show_names(), todays_schedule_index())
        todays_show_hours := list.nth(default=[0], showschedule_show_hours(), todays_schedule_index())
    else
        # TODO: go look for "everyday" schedules and remove this placeholder crap
        todays_schedule_index := 0
        todays_show_names := [""]
        todays_show_hours := [0]
    end
    indexed_todays_show_hours = list.mapi(add_indices, todays_show_hours())
    prior_indexed_todays_show_hours = list.filter(is_prior_hour, indexed_todays_show_hours) # here is where we actually check the time
    todays_current_index = fst(list.hd(default=(0, 0), list.rev(prior_indexed_todays_show_hours)))
    current_scheduled_show_name := list.nth(default="", todays_show_names(), todays_current_index)
    current_scheduled_show_hour := list.nth(default=0, todays_show_hours(), todays_current_index)
    current_scheduled_show_time := today_start_time + float_of_int(current_scheduled_show_hour()) * 3600.0
    # now let's see if we can just grab the next show from today's schedule...
    if (list.length(todays_show_names()) > todays_current_index + 1) then
        # yup, grab it!
        next_scheduled_show_name := list.nth(default="", todays_show_names(), todays_current_index + 1)
        next_scheduled_show_hour := list.nth(default=0, todays_show_hours(), todays_current_index + 1)
        next_scheduled_show_time := today_start_time + float_of_int(next_scheduled_show_hour()) * 3600.0
    else
        # okay, gotta use tomorrow's schedule...
        log("    Getting first show of tomorrow's schedule...")
        # TODO: search for "daysofyear" types first
        tomorrows_indexed_dow_schedules = list.filter(find_tomorrows_dow_types, indexed_schedule_types)
        # is there a top heirarchy schedule type for tomorrow?
        if (list.length(tomorrows_indexed_dow_schedules) > 0) then
            tomorrows_schedule_index := fst(list.hd(default=(0, ""), tomorrows_indexed_dow_schedules))
            tomorrows_show_names := list.nth(default=[""], showschedule_show_names(), tomorrows_schedule_index())
            tomorrows_show_hours := list.nth(default=[0], showschedule_show_hours(), tomorrows_schedule_index())
        else
            # TODO: go look for "everyday" schedules and remove this placeholder crap
            tomorrows_schedule_index := 0
            tomorrows_show_names := [""]
            tomorrows_show_hours := [0]
        end
        next_scheduled_show_name := list.hd(default="", tomorrows_show_names())
        next_scheduled_show_hour := list.hd(default=0, tomorrows_show_hours())
        next_scheduled_show_time := tomorrow_start_time + float_of_int(next_scheduled_show_hour()) * 3600.0
    end
    log("    Current show:  " ^ current_scheduled_show_name() ^ "  (started at " ^ string(current_scheduled_show_hour()) ^ ":00)")
    log("    Next show:     " ^ next_scheduled_show_name() ^ "  (will start at " ^ string(next_scheduled_show_hour()) ^ ":00)")
end


# auto-dj control loop

default_pulse = 2.0 # seconds between loops if there's no other need
next_pulse = ref (0.0)
last_handled_hour_time = ref (0.0) # time of the last hour mark that was "handled" by show switch/station ID

def auto_dj_loop() =
    next_pulse := default_pulse
    now = time()
    this_hour = get_current_hour()
#    time_since_last_hour = get_time_since_last_hour()
    track_remaining_time = source.remaining(current_show_source())
    today_start_time = get_today_start_time()
    track_end_time = now + track_remaining_time

    # startup condition, or just recovery from a problem
    if (current_show_name() == "") then
        update_current_next_shows() # figure out what's supposed to be going on
        log(" *** AUTO-DJ: Starting up with... " ^ current_scheduled_show_name())
        timed_enqueue(["change_show", current_scheduled_show_name()], 0.0)
        last_handled_hour_time := today_start_time + (float_of_int(this_hour) * 3600.0)
    end
    up_next_hour_time = last_handled_hour_time() + 3600.0

    if (now >= next_scheduled_show_time()) then # always keep the latest schedule info correct, regardless of other logic
        update_current_next_shows()
    end

    # do show signoffs, signons, and station IDs when it's time
    if (now > up_next_hour_time - 60.0 and track_end_time >= up_next_hour_time) then
        log(" *** AUTO-DJ: Time to handle the hour.")
        if (track_end_time < up_next_hour_time + (10.0 * 60.0)) then # do stuff at the trackend
            # TODO - maybe ideally don't mostly repeat this code in two places (below), but for now make sure to make changes in both places
            # NOTE ideally this should be an == without the 100.0s slop, but I don't trust my float times
            if (next_scheduled_show_time() < up_next_hour_time + 100.0 and next_scheduled_show_name() != current_scheduled_show_name()) then
                log (" *** AUTO-DJ: Coming up next... " ^ next_scheduled_show_name())
                timed_enqueue(["set_fadeout_trackend", "true"], 0.0)
                trackend_enqueue(["change_show", next_scheduled_show_name()], 3.0)
                current_signoff_announcement = list.assoc(default="", current_scheduled_show_name(), show_signoff_announcements())
                if (current_signoff_announcement != "") then
                    pre_trackend_enqueue(["say", current_signoff_announcement], 40.0)
                end
                next_signon_announcement = list.assoc(default=station_id_announcement, next_scheduled_show_name(), show_signon_announcements())
                if (next_signon_announcement != "") then
                    trackend_enqueue(["say", next_signon_announcement], 13.0)
                end
            else # no scheduled show switch this hour, so see about doing a station ID
                if (station_id_announcement != "") then
                    log(" *** AUTO-DJ: Time for a station ID announcement.")
                    pre_trackend_enqueue(["say", station_id_announcement], 12.0)
                end
            end
        else # it's time to go but the current track ends 10 minutes after the hour, so just do it without waiting for track end.
            # NOTE mostly same as above
            if (next_scheduled_show_time() < up_next_hour_time + 100.0 and next_scheduled_show_name() != current_scheduled_show_name()) then
                log (" *** AUTO-DJ: Coming up next... " ^ next_scheduled_show_name())
                log (" *** AUTO-DJ: Current track ends more than 10 minutes after the hour. ")
                timed_enqueue(["set_fadeout_instant", "true"], 40.0)
                timed_enqueue(["change_show", next_scheduled_show_name()], 43.0)
                timed_enqueue(["set_fadeout_instant", "false"], 43.1)
                current_signoff_announcement = list.assoc(default="", current_scheduled_show_name(), show_signoff_announcements())
                if (current_signoff_announcement != "") then
                    timed_enqueue(["say", current_signoff_announcement], 0.0)
                end
                next_signon_announcement = list.assoc(default=station_id_announcement, next_scheduled_show_name(), show_signon_announcements())
                if (next_signon_announcement != "") then
                    timed_enqueue(["say", next_signon_announcement], 63.0)
                end
            else # no scheduled show switch this hour, so see about doing a station ID right around the hour
                if (station_id_announcement != "") then
                    log(" *** AUTO-DJ: Time for a station ID announcement.")
                    timed_enqueue(["say", station_id_announcement], 60.0)
                end
            end
        end
        last_handled_hour_time := up_next_hour_time # one way or the other, this hour is handled and this section won't run again
    end

    next_pulse()
end


# kick off automatic show management
# TODO: make initiating and halting the DJ control loop control board functions

log("STARTUP: initiating AUTO-DJ...")

thread.run.recurrent(delay=5.0, auto_dj_loop) # start it up!! # TODO make starting it up optional



