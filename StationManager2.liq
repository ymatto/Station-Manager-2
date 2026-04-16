#!/Users/omm/.opam/default/bin/liquidsoap -v
# If not running this from the commandline (such as launchd), make sure to include '--' before the configuration file argument
# ie.: /Users/omm/Basscadet/StationManager2.liq -- stationconfig.json

# Designed to run with Liquidsoap v2.4.2


#<
MIT License

Copyright (c) 2026 Matthew Hine

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

station_log_path = stationconfig.log_path ?? ""
station_tracklog_path = stationconfig.tracklog_path ?? ""
station_tracklog_length = stationconfig.tracklog_length ?? 20
station_currentshow_path = stationconfig.currentshow_path ?? ""

station_telnet_server = stationconfig.telnet_server ?? false
station_telnet_server_port = stationconfig.telnet_server_port ?? 1234
station_telnet_server_timeout = float_of_int(stationconfig.telnet_server_timeout ?? 60)
station_telnet_server_netmask = stationconfig.telnet_server_netmask ?? "0.0.0.0"

station_http_endpoints = stationconfig.http_endpoints ?? false
station_http_endpoints_port = stationconfig.http_endpoints_port ?? 1080

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

# Don't parse ID3 tags that have image or other large data, causing warnings about "string over max length" to be thrown
settings.request.metadata_decoders.recode.exclude := ["id3v2_priv.www.amazon.com", "id3v2_priv.traktor", "priv", "apic", "pic", "metadata_block_picture", "coverart", "lyrics", "lyrics-none-eng", "unsyncedlyrics", "geob", "uslt", "cuesheet"]

# Telnet server setup
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
#   `per_show_target`, if set, is a target number of plays for the special during the expected playtime of the show
#   `try_top_of_hour`, if set, tries to play the special as the first thing after an hour switch
#   `try_show_start`, if set, tries to play the special as the first thing of a new show
# TODO ... also want to implement options for try_show_end, per_day_target and others
station_specials_reqs = ref([])

if (file.exists(station_specials_reqs_path)) then
    station_specials_reqs_file = file.contents(station_specials_reqs_path)
    let json.parse ( new_station_specials_reqs :
        [ 
            {
                special_name: string,
                per_hour_target: int?,
                per_show_target: int?,
                try_top_of_hour: bool?,
                try_show_start: bool?
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
#       30 minutes
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
show_specials_reqs = ref([]) # ("Beats", [<same format as station_specials_reqs>]), (...)
show_nonrepetition_reqs = ref([]) # ("Beats", [<same format as station_nonrepetition_reqs>]), (...)

showconfig_file = file.contents(station_showconfig_path)

let json.parse (show_list : [(
    string * {
        playlist_path: string,
        show_longname: string?,
        show_description: string?,
        DJ_voice: string?,
        signon_announcement: string?, 
        signoff_announcement: string?,
        shuffle_mode: string?,
        specials_reqs_path: string?,
        nonrepetition_reqs_path: string?
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
    thisspecials_reqs_path = thisshowdata.specials_reqs_path ?? ""
    if file.exists(thisspecials_reqs_path) then # this show has its own specials_reqs file to override the station's default
        thisspecials_reqs_file = file.contents(thisspecials_reqs_path)
        let json.parse ( thisspecials_reqs :
            [ 
                {
                    special_name: string,
                    per_hour_target: int?,
                    per_show_target: int?,
                    try_top_of_hour: bool?,
                    try_show_start: bool?
                }
            ] ) = thisspecials_reqs_file
        show_specials_reqs := list.append([(thisshowkey, thisspecials_reqs)], show_specials_reqs())
    end
    thisnonrepetition_reqs_path = thisshowdata.nonrepetition_reqs_path ?? ""
    if file.exists(thisnonrepetition_reqs_path) then # this show has its own nonrepetition_reqs file to override the station's default
        thisnonrepetition_reqs_file = file.contents(thisnonrepetition_reqs_path)
        let json.parse ( thisnonrepetition_reqs :
            [ 
                {
                    tag_name: string,
                    dont_repeat_within_last: string
                }
            ] ) = thisnonrepetition_reqs_file
        show_nonrepetition_reqs := list.append([(thisshowkey, thisnonrepetition_reqs)], show_nonrepetition_reqs())
    end
end

list.iter(get_show, show_list)



# LOAD list of relevant metadata tags that are used in any nonrepetition requirements, for usage tracking
relevant_nonrepetition_tags = ref([])

def include_all_tags_from_nonrep_requirements(this_nonrep_requirements) =
    def include_tag_from_req(this_nonrep_req) =
        this_tag = this_nonrep_req.tag_name
        if not list.exists(fun(x) -> x == this_tag, relevant_nonrepetition_tags()) then
            relevant_nonrepetition_tags := list.add(this_tag, relevant_nonrepetition_tags())
        end
    end
    list.iter(include_tag_from_req, this_nonrep_requirements)
end
include_all_tags_from_nonrep_requirements(station_nonrepetition_reqs())
def include_all_tags_from_show_nonrep_requirements(this_show_nonrep_req) =
    this_reqs = snd(this_show_nonrep_req)
    include_all_tags_from_nonrep_requirements(this_reqs)
end
list.iter(include_all_tags_from_show_nonrep_requirements, show_nonrepetition_reqs())
# log("Relevant tags for nonrepetition rules:\n" ^ string(relevant_nonrepetition_tags()))

    


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

# Create a single blank source that we can use everywhere else, rather than constantly spinning out new blank sources
silence = blank()

# Create current_output_source. Changing source contents of this will change what is broadcast, using the dynamic broadcast_source
current_output_source = ref(silence)

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

# list of readable recent tracks to dump to log or push out on http endpoint
recent_tracks = ref ([])
recent_tracks_md_structs = ref ([])
new_tracklog = ref ("")
now_playing_metadata = ref([])
now_playing_filtered_md_struct = ref({})


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

cover_manager = file.cover.manager(
  id          = "radio",
  default     = "/station/default_cover.png",
  mime_types  = [
    ("image/gif",  "gif"),
    ("image/jpg",  "jpg"),
    ("image/jpeg", "jpg"),
    ("image/png",  "png"),
    ("image/webp", "webp")
  ]
)

def logtrack(this_metadata) =
    if (station_tracklog_path != "") then
        artist = get_metadata_value("artist", this_metadata)
        album = get_metadata_value("album", this_metadata)
        title = get_metadata_value("title", this_metadata)
        year = get_metadata_value("year", this_metadata)
        filename = get_metadata_value("filename", this_metadata)
        if (title == "") then
            log ("PLAYING: file without metadata")
        else # we have a real thing playing, rather than a blank voiceover or something - log it as appropriate
            newline="#{artist} - #{album} - #{title}"
            log("PLAYING: " ^ newline ^ " (" ^ filename ^ ")") 
            # update tracking
            now_playing_metadata := this_metadata
            now_playing_filtered_md_struct := {
                title  = title,
                artist = artist,
                album  = album,
                year = year
            }
            recent_tracks_md_structs := list.add(now_playing_filtered_md_struct(), recent_tracks_md_structs())
            if (list.length(recent_tracks_md_structs()) > station_tracklog_length) then
                recent_tracks_md_structs := list.slice(offset=0, length=station_tracklog_length, recent_tracks_md_structs())
            end
            # update cover manager
            cover_manager.set(this_metadata)
            # update log
            if (station_tracklog_path != "") then
                recent_tracks := list.add(newline, recent_tracks())
                if (list.length(recent_tracks()) > station_tracklog_length) then
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

def get_hour_at(this_time) = 
    time.local(this_time).hour
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

current_scheduled_show_name = ref ("")
current_scheduled_show_hour = ref (0)
current_scheduled_show_time = ref (0.0)
next_scheduled_show_name = ref ("")
next_scheduled_show_hour = ref (0)
next_scheduled_show_time = ref (0.0)

current_show_name = ref ("") # name of actual broadcasting show (independent of schedule - if there even is one)
current_show_source = ref (silence) # the current show playlist source that can be monitored or controlled
current_voice = ref ("") # name of current voice to use for synthesized DJ statements
current_specials_reqs = ref([])
current_nonrepetition_reqs = ref([])

pause_playback = ref (false)

track_endtime = ref (false)

timed_command_queue = ref ([]) # [([commandname, arg], exec_unixtime), ...]
trackend_command_queue = ref ([]) # [([commandname, arg], exec_delay_after_trackend), ...]
pre_trackend_command_queue = ref ([]) # [([commandname, arg], exec_time_before_trackend), ...]

# keep track of specials plays what specials requirements are overdue
specials_req_overdue_states = ref([]) # [ ("Best Of", false), (...) ]
overdue_special_names = ref([]) # [ "Best Of", "90s Jams", ... ]
specials_hour = ref(time.local().hour)
specials_plays_this_hour = ref([]) # [ ("Best Of", 3), (...) ] - resets each hour
specials_show_name = ref("")
specials_plays_this_show = ref([]) # [ ("Best Of", 3), (...) ] - resets when a new show has started
specials_plays_last_show = ref([]) # [ ("Best Of", 3), (...) ] - updated when a new show has started, with the previous show's specials
specials_day = ref(time.local().day)
specials_plays_today = ref([]) # [ ("Best Of", 3), (...) ] - resets when a new day has started
specials_plays_yesterday = ref([]) # [ ("Best Of", 3), (...) ] - updated when a new day has started, with the previous day's specials
specials_plays_continuous = ref([]) # [ ("Best Of", 3), (...) ] - never resets
specials_plays_continuous_by_show = ref([]) # [ ("Hiphop", [ ("Best Of", 3), (...) ] ), (...) ] - never resets

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

# keep track of the last track we logged the specials last played state for
last_current_track_logged = ref("")

# big function to see what specials state we'll be in, considering the currently-playing track
# intended to be called just after a track has started playing, avoiding redundant tallying if called more than once during a track
def update_specials_and_last_played_state()
    # get the playing track
    current_track_metadata = current_show_source().last_metadata() ?? []
    current_track_remaining = current_show_source().remaining()
    current_track_filename = current_track_metadata["filename"]
    # log("Updating specials status with:  " ^ string(current_track_filename) ^ " with remaining time " ^ string(current_track_remaining))

    track_ends_in_new_hour = ref(false)
    new_show_just_started = ref(false)

    def increment_specials_plays(this_special_name)
        this_hour_playcount = list.assoc(default=0, this_special_name, specials_plays_this_hour())
        specials_plays_this_hour := list.add((this_special_name, this_hour_playcount + 1), list.assoc.remove(this_special_name, specials_plays_this_hour()))
        this_show_playcount = list.assoc(default=0, this_special_name, specials_plays_this_show())
        specials_plays_this_show := list.add((this_special_name, this_show_playcount + 1), list.assoc.remove(this_special_name, specials_plays_this_show()))
        today_playcount = list.assoc(default=0, this_special_name, specials_plays_today())
        specials_plays_today := list.add((this_special_name, today_playcount + 1), list.assoc.remove(this_special_name, specials_plays_today()))
        continuous_playcount = list.assoc(default=0, this_special_name, specials_plays_continuous())
        specials_plays_continuous := list.add((this_special_name, continuous_playcount + 1), list.assoc.remove(this_special_name, specials_plays_continuous()))
        specials_plays_continuous_by_this_show = list.assoc(default=[], current_show_name(), specials_plays_continuous_by_show())
        continuous_by_this_show_playcount = list.assoc(default=0, this_special_name, specials_plays_continuous_by_this_show)
        updated_specials_plays_continuous_by_this_show = list.add((this_special_name, continuous_by_this_show_playcount + 1), list.assoc.remove(this_special_name, specials_plays_continuous_by_this_show))
        specials_plays_continuous_by_show := list.add((current_show_name(), updated_specials_plays_continuous_by_this_show), list.assoc.remove(current_show_name(), specials_plays_continuous_by_show()))
    end

    # if it is a new hour/day/show now, clear specials tracking for the past and update current times so we register this track's specials correctly
    now_time = time()
    now_hour = time.local(now_time).hour
    now_day = time.local(now_time).day
    if  now_hour != specials_hour() then
        log("Resetting specials play counts for a new hour.")
        specials_plays_this_hour := [] # reset for new hour
        specials_hour := now_hour
    end
    if now_day != specials_day() then
        log("Resetting specials play count for a new day.\nTotal specials plays today: " ^ string(specials_plays_today()) ^ "\nSpecials plays since launch: " ^ string(specials_plays_continuous()))
        specials_plays_yesterday := specials_plays_today()
        specials_plays_today := []
        specials_day := now_day
    end
    if specials_show_name() != current_show_name() then
        log("Resetting specials play counts for a new show.")
        specials_plays_last_show := specials_plays_this_show()
        specials_plays_this_show := [] # reset for new show
        specials_plays_this_hour := [] # also reset the hour tracking - if a show is manually changed mid-hour, previous plays this hour don't really matter
        specials_show_name := current_show_name()
        new_show_just_started := true # in this case, we're probably picking the first track of the new show and we want to run the update below even if we've already checked the playing track
    else
        new_show_just_started := false
    end

    if ( (last_current_track_logged() != current_track_filename) or new_show_just_started() ) then # otherwise nothing further to do

        # update state of specials and repetitions, only if we haven't done so for the playing track
        if last_current_track_logged() != current_track_filename then # only do this once per track switch

            last_current_track_logged := current_track_filename

            # find out if track will end in a new hour of specials or not
            time_at_track_end = time() + current_track_remaining
            hour_of_track_end = time.local(time_at_track_end).hour
            if specials_hour() != hour_of_track_end then
                track_ends_in_new_hour := true
            else
                track_ends_in_new_hour := false
            end

            # get the specials the playing track matches
            track_special_names = classify_track(current_track_metadata)

            # increment specials play counts with the the track_special_names, for the *current* time
            list.iter(increment_specials_plays, track_special_names)
            log("Updated specials play count for the " ^ string(specials_hour()) ^ ":00 hour with track " ^ current_track_filename ^ "\n    " ^ string(specials_plays_this_hour()))

            # update last_plays_cache based on current_track's metadata
            # log("Updating last play times with: " ^ current_track_filename)
            def get_updated_last_plays_for_each_required_tag_name(this_tag_name)
                this_last_plays = list.assoc(default=[], this_tag_name, last_plays_cache())

                tag_of_current_track = list.assoc(default="", this_tag_name, current_track_metadata)
                updated_this_last_plays = list.add((tag_of_current_track, time()), list.assoc.remove(tag_of_current_track, this_last_plays))
                (this_tag_name, updated_this_last_plays)
            end
            last_plays_cache := list.map(get_updated_last_plays_for_each_required_tag_name, relevant_nonrepetition_tags())
        end

        # now update specials_req_overdue_states for time at the expected END of current track (re-run this if a new show has started, changing the requirements)
        
        # iterator to figure out the overdue status of a given special requirement, at the *end* of the current track
        def get_special_state(this_special_reqs)
            # load this special's requirements
            this_special_name = this_special_reqs.special_name # "Best Of"
            this_per_hour_target = this_special_reqs.per_hour_target ?? 0
            this_per_show_target = this_special_reqs.per_show_target ?? 0
            this_try_top_of_hour = this_special_reqs.try_top_of_hour ?? false
            this_try_show_start = this_special_reqs.try_show_start ?? false

            this_special_overdue_state = ref(false)
            
            # TODO: add more options like perhaps try_show_end, per_day_target?
            if this_try_show_start and new_show_just_started() then
                # other targets don't matter - it is the start of a new show so show_start requirement makes this special overdue this once
                log("Trying to meet the new show's one-time show_start requirement for: " ^ this_special_name)
                this_special_overdue_state := true
            elsif this_try_top_of_hour and new_show_just_started() then
                # no show_start requirement set, but if there's a try_top_of_hour and the show just started, go ahead and use it (probably first of hour)
                log("Trying to meet the new show's one-time top_of_hour requirement for: " ^ this_special_name)
                this_special_overdue_state := true
            elsif this_try_top_of_hour and track_ends_in_new_hour() then
                # other targets don't matter - it will be top of the hour so top_of_hour requirement makes this special overdue this once
                log("Trying to meet one-time top_of_hour requirement for: " ^ this_special_name)
                this_special_overdue_state := true
            else
                if this_per_hour_target > 0 then # let's see about the per-hour target
                    per_hour_req_period = 3600.0 / float_of_int(this_per_hour_target)
                    expected_time_since_hour = get_time_since_last_hour_at(time() + current_track_remaining) # at end of current track
                    target_plays_by_now_this_hour = int_of_float( floor( (expected_time_since_hour + (per_hour_req_period / 2.0)) / per_hour_req_period ) )
                        # important math... for example:
                        # target of 1 play per hour makes it overdue at 30 minute mark
                        # target of 3 plays per hour makes it overdue at 10, 30, and 50 minute marks
                    actual_plays_this_hour = ref(0)
                    if (track_ends_in_new_hour()) then # play count will reset in the hour about to start
                        actual_plays_this_hour := 0
                    else # current hour's play count is valid to use
                        actual_plays_this_hour := list.assoc(default=0, this_special_name, specials_plays_this_hour())
                    end
                    if target_plays_by_now_this_hour > actual_plays_this_hour() then
                        # we're behind - make this overdue
                        this_special_overdue_state := true
                    end
                end
                if this_per_show_target > 0 then # let's see about the per-show target
                    show_length = next_scheduled_show_time() - current_scheduled_show_time()
                    per_show_req_period = show_length / float_of_int(this_per_show_target)
                    expected_time_since_show_start = time() + current_track_remaining - current_scheduled_show_time()
                    target_plays_by_now_this_show = int_of_float( floor( (expected_time_since_show_start + (per_show_req_period / 2.0)) / per_show_req_period ) )
                    # similar math as above for per-hour... for example, given a 4-hour show:
                    # target of 1 play per show makes it overdue at 2 hour mark
                    # target of 3 plays per show makes it overdue at 40, 120, and 200 minute marks
                    actual_plays_this_show = list.assoc(default=0, this_special_name, specials_plays_this_show()) # unlike hourly logic, don't assume show will actually change - change_show will take care of things if it does
                    if target_plays_by_now_this_show > actual_plays_this_show then
                        # we're behind - make this overdue
                        this_special_overdue_state := true
                    end
                end
            end 

            # return the status of the special
            (this_special_name, this_special_overdue_state())
        end

        new_specials_overdue_states = list.map(get_special_state, current_specials_reqs())
        specials_req_overdue_states := new_specials_overdue_states
    end

end


# Keep track of some things *between calls* to is_request_approved, so we can be smarter when churning through request rejections
number_request_checks = ref(0)
time_request_check_start = ref(0.0)

# Called as source's check_next - decide if the next request should be played or not based on specials and repetition rules
# TODO - Can this be made even more efficient, to incur less latency?
def is_request_approved(req) =

    # Find out what the proposed request to play next is and consider its suitability
    next_request_filename = request.uri(req)
    next_request_metadata = ref([]) # don't get it until we know it's a valid file

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
            elsif this_dont_repeat_within_last == "30 minutes" then
                within_time := 1800.0
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
        # NOTE - This pause is annoying, but a better solution requires keeping track of metadata ourselves in a way that seems maybe even more error prone
        thread.pause(0.1) # pause for a moment to make sure metadata of the newly-playing track is available on last_metadata

        time_request_check_start := time() # start the clock on checks
        update_specials_and_last_played_state() # since we're just starting to look for a next track, check that specials are updated for the newly-playing track
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
            all_repetition_rules_satisfied = list.for_all(is_nonrepetition_req_satisfied, current_nonrepetition_reqs())
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
    command_time = now + exec_delay
    command_pair = [(command, command_time)] # timed queue uses absolute times for execution
    timed_command_queue := list.append(timed_command_queue(), command_pair)
    # now sort it by time (least first) so we can just check the head of the list in the command loop
    timed_command_queue := list.sort(sort_command_queue_by_time_ascending, timed_command_queue())
    # log("timed command queue now: " ^ string(timed_command_queue()))
end

def trackend_enqueue(command, exec_delay) =
    command_pair = [(command, exec_delay)] # trackend queue uses a delay, all of which can be turned into fixed timed_enqueue requests at track end
    trackend_command_queue := list.append(trackend_command_queue(), command_pair)
    # log("trackend command queue now: " ^ string(trackend_command_queue()))
end

def pre_trackend_enqueue(command, exec_delay) =
    command_pair = [(command, exec_delay)]
    pre_trackend_command_queue := list.append(pre_trackend_command_queue(), command_pair)
    # now sort it by pre-trackend delay (largest first) so we can just check the head of the list in the command loop
    pre_trackend_command_queue := list.sort(sort_command_queue_by_time_descending, pre_trackend_command_queue())
    # log("pre-trackend command queue now: " ^ string(pre_trackend_command_queue()))
end

# Command-queueable functions


def set_pause_playback(arg) =
    if (arg == "true") then
        pause_playback := true
    elsif (arg == "false") then
        pause_playback := false
    else
        log("Bad arg to set_pause_playback")
    end
end

# a source that will be immediately smooth_add'ed into whatever is playing, whenever there is a request (like an announcement)
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
    playover_source.push(request.create(temporary=true, "synth:shape=sine,frequency=0.0,duration=3"))
    playover_source.push(request.create(temporary=true, "file:" ^ file_path))
    playover_source.push(request.create(temporary=true, "synth:shape=sine,frequency=0.0,duration=1"))
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


# a source that will play at the end of the current track, regardless of what the playlist is doing
request_injection_source = request.queue(id="playover_source") # removed audio_to_stereo at v2.0


def enqueue_silence (duration_seconds) =
    request_injection_source.push(request.create(temporary=true, "synth:shape=sine,frequency=0.0,duration=" ^ string(duration_seconds)))
end

def enqueue_track (filename) = 
    if (filename == "") then
        log("Unable to enqueue track - no filename provided")
    elsif (not file.exists(stationconfig_filename)) then
        log("Unable to enqueue track - file does not exist: " ^ filename)
    else
        request_injection_source.push(request.create("file:" ^ filename))
    end
end


def rewind () = 
    current_track_metadata = current_show_source().last_metadata() ?? []
    if (current_track_metadata != []) then
        current_track_filename = current_track_metadata["filename"]
        request_injection_source.push(request.create(temporary=true, "synth:shape=sine,frequency=0.0,duration=2"))
        request_injection_source.push(request.create(current_track_filename))
        thread.pause(0.1) # to provide a moment for the requests to actually get into the queue before the skip
        source.skip(current_show_source())
    else
        log("Unable to rewind current track - no metadata present")
    end
end


def skip () =
    source.skip(current_show_source()) 
    log("Skipping to next track in playlist!")
end


# Show management functions (plus change_show queueable command)




def handle_track_end (this_metadata) =
    update_specials_and_last_played_state() # to be safe, attempt a specials update based on the now-playing track in case this isn't a normal next-track-in-playlist-queue track that is_request_approved would pick up
    track_endtime := true # tell the command_loop to do track end things
    logtrack(this_metadata)
end


# keep each show's sources stored so they only have to be created once
show_sources = ref ([]) # the playlist sources themselves, to be assigned to current_show_source
show_output_sources = ref ([]) # sources with all of the additional hooks to be assigned to current_output_source



def change_show(this_show_name) =
    if (list.assoc(default="error", this_show_name, show_paths()) != "error") then
        log("  --- New show starting: " ^ this_show_name ^ " ------------------------------------")
        
        # TODO maybe use noise() or sine() instead of blank() to prevent players from disconnecting (supposedly)
        # First, disconnect the current source from the dynamic source before doing some prep for the new show
        current_output_source := silence

        # Get the playlist-based source used for control
        if (list.assoc.mem(this_show_name, show_sources())) then
            current_show_source := list.assoc(this_show_name, show_sources())
            # skip so the show doesn't start partway through a track, won't be audible because we haven't made it active yet
            source.skip(current_show_source())
        else
            show_path = list.assoc(default=".", this_show_name, show_paths())

            # The check_next handler kicks off checking if the potentially-next track meets specified requirements
            show_source = fallback(id="injectable_scheduled_show_playlist", track_sensitive=true,
                    [request_injection_source,
                    playlist(id="scheduled_show_playlist", check_next=is_request_approved, register_server_commands=false, show_path)]
                )
            show_source.on_track(synchronous=false, handle_track_end)

            # save it for next time
            show_sources := list.append([(this_show_name, show_source)], show_sources())

            current_show_source := show_source  
        end

        # Set the source used by the dynamic broadcast source
        if (list.assoc.mem(this_show_name, show_output_sources())) then
            current_output_source := list.assoc(this_show_name, show_output_sources())
        else
            # Create the new source for broadcast
            # NOTE: you can wrap this in a crossfade(), which works, but it seems to make on_track handling not possible
            #    so if we want to do crossfading, we'll have to really change up some logic.
            # ALSO NOTE: there used to be a track_sensitive pause here too, but this was a bad idea because switching to
            #    blank meant that a track change would never happen again for that source, making it impossible to change
            #    back to that show.
            show_source_with_switches = 
                switch(id="pause_handler", track_sensitive=false, [ ({pause_playback() == true}, silence), ({true},
                    current_show_source()
                ) ] )
            output_source = smooth_add(duration=1.5, p=0.1, special=playover_source, normal=show_source_with_switches)

            # save it for next time
            show_output_sources := list.append([(this_show_name, output_source)], show_output_sources())

            current_output_source := output_source
        end

        current_show_name := this_show_name
        current_show_longname = list.assoc(default="", this_show_name, show_longnames())
        set_voice("normal")
        if (station_currentshow_path != "") then
            ignore(
                file.write(
                        data=current_show_longname,
                        append=false,
                        station_currentshow_path
                    )
            )
        end
        this_show_specials_reqs = list.assoc(default=[], current_show_name(), show_specials_reqs())
        if this_show_specials_reqs != [] then
            log("   Using this show's own specials requirements:\n" ^ "   " ^ string(this_show_specials_reqs))
            current_specials_reqs := this_show_specials_reqs
        else
            log("   Using station-default specials requirements:\n" ^ "   " ^ string(station_specials_reqs()))
            current_specials_reqs := station_specials_reqs()
        end
        this_show_nonrepetition_reqs = list.assoc(default=[], current_show_name(), show_nonrepetition_reqs())
        if this_show_nonrepetition_reqs != [] then
            log("   Using this show's own nonrepetition requirements:\n" ^ "   " ^ string(this_show_nonrepetition_reqs))
            current_nonrepetition_reqs := this_show_nonrepetition_reqs
        else
            log("   Using station-default nonrepetition requirements:\n" ^ "   " ^ string(station_nonrepetition_reqs()))
            current_nonrepetition_reqs := station_nonrepetition_reqs()
        end
    else
        log("No playlist path specified for requested show: " ^ this_show_name)
    end

    # make sure we start playing, regardless of if the show actually switched or not
    set_pause_playback("false")

end

# Command queue execution functions

# commands are of format: ["command_name", "command_argument"]
def execute_a_command(command) =
    command_name = list.hd(default="", command)
    command_arg = list.nth(default="", command, 1)
    log("PROCESSING DJ COMMAND: " ^ command_name ^ " - with argument: " ^ command_arg)
    if (command_name == "change_show") then
        change_show(command_arg)
    elsif (command_name == "set_pause_playback") then
        set_pause_playback(command_arg)
    elsif (command_name == "say") then
        say(command_arg)
    elsif (command_name == "set_voice") then
        set_voice(command_arg)
    elsif (command_name == "skip") then
        skip()
    elsif (command_name == "rewind") then
        rewind()
    elsif (command_name == "enqueue_silence") then
        enqueue_silence(int_of_string(command_arg))
    elsif (command_name == "enqueue_track") then
        enqueue_track(command_arg)
    else
        log("   \"#{command_name}\" is not a supported command!")
    end
    #TODO moar commands
end

# execute any timed commands that are due right now
def process_timed_command_queue() =
    now = time()
    remaining_queue = ref([])
    def iter_command(this_command_pair) =
        this_command = fst(this_command_pair)
        this_command_time = snd(this_command_pair)
        if (this_command_time <= now) then
            # do it now!
            execute_a_command(this_command)
        else
            remaining_queue := list.append(remaining_queue(), [this_command_pair])
        end
    end
    list.iter(iter_command, timed_command_queue())
    timed_command_queue := remaining_queue()
end

# execute any pre-trackend commands that are due right now
def process_pre_trackend_command_queue() =
    track_remaining_time = source.remaining(current_show_source())
    remaining_queue = ref([])
    def iter_command(this_command_pair) =
        this_command = fst(this_command_pair)
        this_command_time = snd(this_command_pair)
        if (track_remaining_time <= this_command_time) then
            # do it now!
            execute_a_command(this_command)
        else
            remaining_queue := list.append(remaining_queue(), [this_command_pair])
        end
    end
    list.iter(iter_command, pre_trackend_command_queue())
    pre_trackend_command_queue := remaining_queue()
end

# clear out the pre-trackend and trackend queues
def process_trackend_command_queue() =
    def execute_pretrackend_command(this_command_pair) =
        this_command = fst(this_command_pair)
        # do it now!
        execute_a_command(this_command)
    end
    def handle_trackend_command (this_command_pair) =
        this_command = fst(this_command_pair)
        this_command_delay = snd(this_command_pair)
        if (this_command_delay <= 0.0) then
            # do it now!
            execute_a_command(this_command)
        else
            # inject commands with non-zero delay into timed queue
            timed_enqueue(this_command, this_command_delay + 0.0)
        end
    end

    # first, do all of the outstanding pre-trackend commands that need to just happen now
    num_pre_trackend_commands = list.length(pre_trackend_command_queue())
    if (num_pre_trackend_commands > 0) then
        log(string(num_pre_trackend_commands) ^ " pre-trackend DJ commands present in queue at track's end. Running these first.")
        list.iter(execute_pretrackend_command, pre_trackend_command_queue())
        pre_trackend_command_queue := []
    end
    # then, for all trackend commands, either execute immediately or convert to timed commands
    if (list.length(trackend_command_queue()) > 0) then
        list.iter(handle_trackend_command, trackend_command_queue())
        trackend_command_queue := []
    end
end

# loop that executes commands out of queues at the proper time

def command_loop() =
    now = time()

    # check trackend_command_queue
    if (track_endtime()) then
        track_endtime := false # reset to start waiting for next trackend
        process_trackend_command_queue()
    else # only check the pre-trackend queue if it's not a track endtime (since that will clear that queue anyway)
        # check pre_trackend_command_queue
        track_remaining_time = source.remaining(current_show_source())
        next_pre_trackend_time = snd(list.hd(default=(["", ""], -1.0), pre_trackend_command_queue()))
        if (track_remaining_time <= next_pre_trackend_time) then
            process_pre_trackend_command_queue()
        end
    end

    # check timed_command_queue (which will now also contain any trackend commands to do at this moment)
    next_timed_command_time = snd(list.hd(default=(["", ""], 0.0), timed_command_queue()))
    if (now >= next_timed_command_time and next_timed_command_time != 0.0) then
        process_timed_command_queue()
    end
    0.2
end

# kick off recurring command_loop processing
thread.run.recurrent(delay=0.2, command_loop)


# Single external receiver of new command requests to add to the queue
def request_command(command, exec_delay, timing_type) = 
    # before adding any new commands, run the command_loop manually to make sure existing commands are handled properly
    # particularly trackend handling - previously there was a race condition issue when command_loop lagged new commands added to queue
    ignore(command_loop())
    if (timing_type == "timed") then
        log("Timed command received:         " ^ string(command) ^ " with execution set to " ^ string(exec_delay) ^ " seconds from now")
        timed_enqueue(command, exec_delay)
    elsif (timing_type == "trackend") then
        log("Trackend command received:      " ^ string(command) ^ " with execution delay: " ^ string(exec_delay) ^ " after end of this track")
        trackend_enqueue(command, exec_delay)
    elsif (timing_type == "pre-trackend") then
        log("Pre-trackend command received:  " ^ string(command) ^ " with execution time: " ^ string(exec_delay) ^ " before end of this track")
        pre_trackend_enqueue(command, exec_delay)
    else
        log("Command ignored: Timing type " ^ string(timing_type) ^ " for " ^ string(command) ^ " command not recognized")
    end
end

def clear_command_queue(timing_type) = 
    if (timing_type == "timed") then
        log("Clearing timed command queue")
        timed_command_queue := []
    elsif (timing_type == "trackend") then
        log("Clearing trackend command queue")
        trackend_command_queue := []
    elsif (timing_type == "pre-trackend") then
        log("Clearing pre-trackend command queue")
        pre_trackend_command_queue := []
    elsif (timing_type == "all") then
        timed_command_queue := []
        trackend_command_queue := []
        pre_trackend_command_queue := []
    else
        log("Queue clear request ignored: Timing type " ^ string(timing_type) ^ "not recognized")
    end
end



# SERVER FUNCTIONS

# Commands for auto DJ queue

# common handler for different variations of DJ command requests
def request_command_from_string(input_string, request_type) = 
    command_name = ref ("")
    command_arg = ref ("")
    command_time = ref (0.0)

    trimmed_input = string.trim(input_string)
    input_list = string.split(separator=" ", trimmed_input)
    input_list_length = list.length(input_list)
    input_length = string.length(trimmed_input)

    if (input_list_length < 1) then
        "No DJ command provided"
    else
        command_name := list.nth(default="", input_list, 0)
        command_name_length = string.length(command_name())
        if (request_type == "now") then
            command_arg := string.sub(trimmed_input, start=command_name_length + 1, length=input_length - command_name_length - 1)
            request_command([command_name(), command_arg()], 0.0, "timed")
            "Done"
        elsif (request_type == "trackend") then
            command_arg := string.sub(trimmed_input, start=command_name_length + 1, length=input_length - command_name_length - 1)
            request_command([command_name(), command_arg()], 0.0, "trackend")
            "Done"           
        else
            last_input = list.nth(default="", input_list, input_list_length-1)
            last_input_as_float = float_of_string(default=0.0, last_input)
            command_time := last_input_as_float
            command_time_length = string.length(last_input)
            if (request_type == "delayed") then
                if (command_time() < 0.0) then
                    "Cannot delay a command into the past"
                else
                    command_arg := string.sub(trimmed_input, start=command_name_length + 1, length=input_length - command_name_length - command_time_length - 2)
                    request_command([command_name(), command_arg()], command_time(), "timed")
                    "Done"
                end
            elsif (request_type == "trackend_delayed") then
                if (command_time() < 0.0) then
                    command_arg := string.sub(trimmed_input, start=command_name_length + 1, length=input_length - command_name_length - command_time_length - 2)
                    request_command([command_name(), command_arg()], -(command_time()), "pre-trackend")
                    "Done"                    
                else
                    command_arg := string.sub(trimmed_input, start=command_name_length + 1, length=input_length - command_name_length - command_time_length - 2)
                    request_command([command_name(), command_arg()], command_time(), "trackend")
                    "Done"
                end             
            else
                "Invalid request type provided"
            end
        end
    end
end


def dj_now_handler(input_string) = 
    request_command_from_string(input_string, "now")
end

def dj_trackend_handler(input_string) =
    request_command_from_string(input_string, "trackend")
end

def dj_delayed_handler(input_string) =
    request_command_from_string(input_string, "delayed")
end

def dj_trackend_delayed_handler(input_string) =
    request_command_from_string(input_string, "trackend_delayed")
end

def dj_get_queue(input_string) = 
    timed_queue = string(timed_command_queue())
    pre_trackend_queue = string(pre_trackend_command_queue())
    trackend_queue = string(trackend_command_queue())

    if input_string == "" or input_string == "all" then
        "timed queue - commands to execute at a specific time:\n" ^
        timed_queue ^ "\n" ^
        "pre-trackend queue - commands to execute at a delay before the end of the track:\n" ^
        pre_trackend_queue ^ "\n" ^
        "trackend queue - commands to execute at a delay after the end of the track:\n" ^
        trackend_queue
    elsif input_string == "timed" then
        timed_queue
    elsif input_string == "pre-trackend" then
        pre_trackend_queue
    elsif input_string == "trackend" then
        trackend_queue
    else
        "Invalid argument provided"
    end    
end

def dj_clear_queue(input_string) = 
    if (input_string == "timed" or input_string == "trackend" or input_string == "pre-trackend" or input_string == "all") then
        clear_command_queue(input_string)
        "Done"
    else
        "No or invalid queue identifier provided"
    end
end


dj_command_list =   "  Supported commands:\n" ^
                    "      change_show [show name]\n" ^
                    "      set_pause_playback [true/false]\n" ^
                    "      say [statement]\n" ^
                    "      set_voice [voice name]\n" ^
                    "      skip\n" ^
                    "      rewind\n" ^
                    "      enqueue_silence [silence time in seconds]\n" ^
                    "      enqueue_track [server file path to track]\n"

server.register(namespace="dj",
    usage="now <command> [<argument>]",
    description="Inserts a command into the DJ queue to be run right away\n" ^ dj_command_list,
    "now",
    dj_now_handler)

server.register(namespace="dj",
    usage="trackend <command> [<argument>]",
    description="Inserts a command into the DJ queue to be run at current track's end\n" ^ dj_command_list,
    "trackend",
    dj_trackend_handler)

server.register(namespace="dj",
    usage="now <command> [<argument>] [<time>]",
    description="Inserts a command into the DJ queue to be run after an optional delay time (s) from now\n" ^ dj_command_list,
    "delayed",
    dj_delayed_handler)

server.register(namespace="dj",
    usage="trackend_delayed <command> [<argument>] [<time>]",
    description="Inserts a command into the DJ queue to be run at an optional delay time (s) from track's end\n" ^ dj_command_list,
    "trackend_delayed",
    dj_trackend_delayed_handler)

server.register(namespace="dj",
    usage="get_queue [<timed|pre-trackend|trackend|all>]",
    description="Returns the contents of a current command queue, or all of them by default\n",
    "get_queue",
    dj_get_queue)

server.register(namespace="dj",
    usage="clear_queue <timed|pre-trackend|trackend|all>",
    description="Clears the specified command queue (or all of them)\n",
    "clear_queue",
    dj_clear_queue)


# Commands for station control board

def station_get_specials(input_string) = 
    trimmed_input = string.trim(input_string)
    if trimmed_input == "this_hour" then
        json.stringify(specials_plays_this_hour())
    elsif trimmed_input == "this_show" then
        json.stringify(specials_plays_this_show()) 
    elsif trimmed_input == "last_show" then
        json.stringify(specials_plays_last_show()) 
    elsif trimmed_input == "today" then
        json.stringify(specials_plays_today())
    elsif trimmed_input == "yesterday" then
        json.stringify(specials_plays_yesterday())
    elsif trimmed_input == "continuous" then
        json.stringify(specials_plays_continuous())
    elsif trimmed_input == "continuous_by_show" then
        json.stringify(specials_plays_continuous_by_show())
    else
        "Invalid timeframe specified"
    end
end

server.register(namespace="station",
    usage="get_specials <this_hour|this_show|last_show|today|yesterday|continuous|continuous_by_show>",
    description="Returns a JSON array of the counts of specials that have played during the specified timeframe",
    "get_specials",
    station_get_specials)


# HTTP ENDPOINTS

def cover_handler(req) =
    ignore(req)
    cover_path = request.uri(cover_manager())
    mime       = list.assoc(default="image/jpeg", "cover_mime", now_playing_metadata())
    http.response(
        status_code    = 200,
        headers = [("Content-Type", mime),
                    ("Access-Control-Allow-Origin", "*")],
        data    = file.read(cover_path)
    )
end

def nowplaying_handler(req)
    ignore(req)
    http.response(
        status_code    = 200,
        headers = [("Content-Type", "application/json"),
                    ("Access-Control-Allow-Origin", "*")],
        data    = json.stringify(now_playing_filtered_md_struct())
    )
end

def recent_handler(req)
    ignore(req)
    http.response(
        status_code    = 200,
        headers = [("Content-Type", "application/json"),
                    ("Access-Control-Allow-Origin", "*")],
        data    = json.stringify(recent_tracks_md_structs())
    )
end

if (station_http_endpoints==true) then
    # TODO add other endpoints here
    harbor.http.register.simple(port=station_http_endpoints_port, method="GET", "/cover", cover_handler)
    harbor.http.register.simple(port=station_http_endpoints_port, method="GET", "/nowplaying", nowplaying_handler)
    harbor.http.register.simple(port=station_http_endpoints_port, method="GET", "/recent", recent_handler)
end


                
# --- AUTO DJ --------------------------------------------------------------------
# TODO probably should move relevant json importing stuff down here

# SET UP AUTOMATED DYNAMIC SOURCE CONTROL VIA SCHEDULE – AKA AUTO-DJ



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
        request_command(["change_show", current_scheduled_show_name()], 0.0, "timed")
        last_handled_hour_time := today_start_time + (float_of_int(this_hour) * 3600.0)
    end
    
    up_next_hour_time = last_handled_hour_time() + 3600.0

    # set up show signoffs, signons, and station IDs when it's time - at least a minute before the hour, but only if the current track will end after the hour
    if (now > up_next_hour_time - 60.0 and track_end_time >= up_next_hour_time) then # only one run per hour - get done whatever needs doing
        log(" *** AUTO-DJ: Time to prepare for the upcoming hour.")
        # check if the playing track will end no later than 10 minutes after the hour
        if (track_end_time < up_next_hour_time + (10.0 * 60.0)) then # do stuff at the trackend
            # TODO - maybe ideally don't mostly repeat this code in two places (below), but for now make sure to make changes in both places
            # NOTE ideally this should be an == without the 100.0s slop, but I don't trust my float times
            if (next_scheduled_show_time() < up_next_hour_time + 100.0 and next_scheduled_show_name() != current_scheduled_show_name()) then
                log (" *** AUTO-DJ: Coming up next... " ^ next_scheduled_show_name())
                current_signoff_announcement = list.assoc(default="", current_scheduled_show_name(), show_signoff_announcements())
                if (current_signoff_announcement != "") then
                    request_command(["say", current_signoff_announcement], 40.0, "pre-trackend")
                end
                request_command(["enqueue_silence", "2"], 0.0, "timed")
                request_command(["change_show", next_scheduled_show_name()], 1.0, "trackend")
                next_signon_announcement = list.assoc(default=station_id_announcement, next_scheduled_show_name(), show_signon_announcements())
                if (next_signon_announcement != "") then
                    request_command(["say", next_signon_announcement], 13.0, "trackend")
                end
            else # no scheduled show switch this hour, so see about doing a station ID
                if (station_id_announcement != "") then
                    log(" *** AUTO-DJ: Time for a station ID announcement.")
                    request_command(["say", station_id_announcement], 12.0, "pre-trackend")
                end
            end
        else # it's time to go but the current track ends 10 minutes after the hour, so just do it without waiting for track end.
            # NOTE mostly same as above
            if (next_scheduled_show_time() < up_next_hour_time + 100.0 and next_scheduled_show_name() != current_scheduled_show_name()) then
                log (" *** AUTO-DJ: Coming up next... " ^ next_scheduled_show_name())
                log (" *** AUTO-DJ: Current track ends more than 10 minutes after the hour. ")
                current_signoff_announcement = list.assoc(default="", current_scheduled_show_name(), show_signoff_announcements())
                if (current_signoff_announcement != "") then
                    request_command(["say", current_signoff_announcement], 0.0, "timed")
                end
                # TODO: what I really want here is a fade-out of the playing track before the new show starts, if that's possible. Do a playover of silence...?
                request_command(["change_show", next_scheduled_show_name()], 42.0, "timed")
                next_signon_announcement = list.assoc(default=station_id_announcement, next_scheduled_show_name(), show_signon_announcements())
                if (next_signon_announcement != "") then
                    request_command(["say", next_signon_announcement], 62.0, "timed")
                end
            else # no scheduled show switch this hour, so see about doing a station ID right around the hour
                if (station_id_announcement != "") then
                    log(" *** AUTO-DJ: Time for a station ID announcement.")
                    request_command(["say", station_id_announcement], 60.0, "timed")
                end
            end
        end
        last_handled_hour_time := up_next_hour_time # one way or the other, this hour is handled and this section won't run again
    end

    if (now >= next_scheduled_show_time()) then # always keep the latest schedule info correct for the next loop, regardless of other logic
        update_current_next_shows()
    end

    next_pulse()
end


# kick off automatic show management
# TODO: make initiating and halting the DJ control loop control board functions

log("STARTUP: initiating AUTO-DJ...")

thread.run.recurrent(delay=5.0, auto_dj_loop) # start it up!! # TODO make starting it up optional


