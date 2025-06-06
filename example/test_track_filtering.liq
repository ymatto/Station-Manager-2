log("TEST SCRIPT STARTUP...")


# GLOBALS

station_specials = [
    { name = "Best Of", rules = [
        { tag = "am_rating", filter = "is number no less than", value = "80" } ]
    },
    { name = "Last 30-day Adds", rules = [
        { tag = "am_date_added", filter = "is timestamp in the last seconds", value = "2592000" } ]
    }
]
station_specials_reqs = [
    { special_name = "Best Of", requirements = {
        per_hour_target = 6,
        try_top_of_hour = true
    } },
    { special_name = "Last 30-day Adds", requirements = {
        per_hour_target = 3,
        try_top_of_hour = false
    } }
]

# keep track of what specials requirements are overdue
specials_req_overdue_state = ref([]) # keyed same as the station_specials_reqs... [ {special_name = "Best Of", overdue = false}, {...} ]

# keep a cache of the specials each track matches to avoid repeated complicated analysis of metadata
track_specials_cache = ref([]) # [ ( "/path/to/file.mp3", [("special1", true), ("special2", false)] ), (...) ]

# keep track of when various types of things played for repetition filtering
last_played_tracks = ref([])
last_played_artists = ref([])
last_played_genres = ref([])
last_played_albums = ref([])


# SET UP SOURCES

# Set the context for the track to look at
next_req_filename = ref("")
next_req_metadata = ref([])
next_req_specials = ref([])

# TODO - Note that this function is already in main SM2 script - don't duplicate.
def get_time_since_last_hour() =
    sec = time.local().sec
    min = time.local().min
    float_of_int(sec + (min * 60))      
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

# Iterator to see if each rule is met
def check_rule(this_rule)
    # bunch of logic to check next_req_metadata against this_rule.tag/filter/value
    this_tag = this_rule.tag
    this_tag_value = list.assoc(default="", this_tag, next_req_metadata())
    this_filter = this_rule.filter
    this_value = this_rule.value
    if ( this_tag == "" or this_value == "" ) then
        # rule is incompletely defined... I guess we consider it "met"
        log("WARNING: Missing special tag or value")
        true
    elsif this_filter == "is number equal to" then
        this_tag_value_float = float_of_string(this_tag_value)    
        this_value_float = float_of_string(this_value)
        this_tag_value_float == this_value_float
    elsif this_filter == "is number no less than" then
        this_tag_value_float = float_of_string(this_tag_value)    
        this_value_float = float_of_string(this_value)
        this_tag_value_float >= this_value_float
    elsif this_filter == "is number no more than" then
        this_tag_value_float = float_of_string(this_tag_value)    
        this_value_float = float_of_string(this_value)
        this_tag_value_float <= this_value_float
    elsif this_filter == "is string" then
        this_tag_value == this_value
    elsif this_filter == "is string that includes" then
        string.contains(substring=this_value, this_tag_value)
    elsif this_filter == "is timestamp in the last seconds" then
        this_tag_value_time = float_of_string(this_tag_value)    
        this_value_time = float_of_string(this_value)
        (time() - this_tag_value_time) <= this_value_time
    elsif this_filter == "is year in the last years" then
        this_tag_value_year = int_of_string(this_tag_value)    
        this_value_year = int_of_string(this_value)
        (time.local().year - this_tag_value_year) <= this_value_year
    elsif this_filter == "is date in the last days" then # YYYY-MM-DD
        this_tag_value_time = time_from_YMD(this_tag_value)
        this_value_time = time_from_YMD(this_value)
        if this_tag_value_time == 0.0 or this_value_time == 0.0 then
            log("Invalid YYYY-MM-DD format used in special or ID3 tag")
            true
        else
            (time() - this_tag_value_time) <= this_value_time
        end
    else
        # again, if it's a bogus filter, then I guess consider it "met"
        log("WARNING: Unsupported special rule requirement filter encountered")
        true
    end
end

# Iterator to determine which specials a track fits
def check_special(this_special)
    # iterate through rules, make sure they're all true for this special
    if list.for_all(check_rule, this_special.rules) then # false if *any* of the check_rule calls are false
        (this_special.name, true)
    else
        (this_special.name, false)
    end
end

# Return the list of this station's specials that the track in question matches, and cache the result
def classify_next_track()
    cached_specials_matched = list.assoc(default=[("",false)], next_req_filename(), track_specials_cache())
    if cached_specials_matched != [("",false)] then # already classified
        # return the cached results
        cached_specials_matched
    else
        # iterate through station_specials to see which match this file, adding to specials
        specials_matched = list.map(check_special, station_specials)
        track_specials_cache := list.add((next_req_filename(), specials_matched), track_specials_cache())
        # return the (now cached) results
        specials_matched
    end
end

def check_special_req_overdue(special_req)
    special_req.overdue
end

def check_track_can_satisfy(overdue_req)
    req_name = overdue_req.special_name
    list.assoc(default=false, req_name, next_req_specials())
end

# Decide if the next request should be played or not based on specials and repetition rules
# TODO - don't forget to break out of loops if nothing matches
def request_approved(req) =
    request.resolve(req)
    next_req_filename := request.filename(req)

    log("Checking request: " ^ next_req_filename())
    file_only_name = list.last(string.split(separator="/", next_req_filename()))
    if (string.sub(file_only_name, start=0, length=1) == ".") then
        log("Skipping hidden file...")
        false
    # TODO check repetition rules before getting into specials rules
    else # check track against need for specials
        next_req_metadata := request.metadata(req)
        # classify the track no matter what, even if no speicials are overdue, to build up the cache if nothing else
        next_req_specials := classify_next_track()
        # log(string(md)) # take a look at all metadata available
        log("Evaluating track: " ^ list.assoc(default="no title", "title", next_req_metadata()))
        overdue_reqs = list.filter(check_special_req_overdue, specials_req_overdue_state())
        if list.length(overdue_reqs) > 0 then
            # if track can satisfy an overdue req... approved, else reject
            if list.exists(check_track_can_satisfy, overdue_reqs) then
                log("TRACK SATISFIES OVERDUE REQ - good to go")
                true
            else
                log("TRACK DOES NOT SATISFY OVERDUE REQS - reject")
                false
            end
        else # nothing overdue - track is good to go
            log("NOTHING OVERDUE - next track good to go")
            true
        end
    end
end

# Do stuff when new track starts actually playing
def check_track_starting(metadata)
    log("NEW TRACK PLAYING: " ^ metadata["title"] ^ " by " ^ metadata["artist"])
    this_filename = metadata["filename"]
    # need to classify track... maybe I should just have classify_track(filename) rather than classify_next_track() ?

    # TODO
    # Update specials overdue status
    # .......


    time_since_hour = get_time_since_last_hour()
    # interate through station_specials_reqs....
    # or should I be more clever and just pre-schedule a time by when I expect a special to have played?
    # ... eesh... need to keep track of how many times a special has played within an hour.....

    # TODO add checks for try_top_of_hour, try_show_start, and try_show_end...

end

# run the playlist, with check_next
playlist_source = playlist(id="playlist source", check_next=request_approved, register_server_commands=false, "music/funky/")
playlist_source.on_metadata(check_track_starting)

# set this to what you ultimately want going out to icecast
broadcast_source = playlist_source
    


# SET UP TEST BROADCAST

output.icecast(
    id="broadcast_output",
    %mp3,
    host = "icecast", port = 8000,
    password = "icecast_secret",
    mount = "sm2_test.mp3",
    name = "Station Manager 2 TEST",
    description = "Testing Stuff for Station Manager 2",
    genre = "testing",
    url = "http://localhost:8000/sm2_test",
    mksafe(broadcast_source)
    )

    

# SET UP TEST TELNET SERVER

settings.server.telnet.set(true)
settings.server.telnet.port.set(1234)
settings.server.telnet.bind_addr.set("0.0.0.0")
settings.server.timeout.set(-1.0) # negative value disables timeout


# SERVER COMMMAND HANDLERS

def skip(input_string) =
    source.skip(broadcast_source)
    "Done."
end


server.register(namespace="test",
    usage="skip",
    description="Next track.",
    "skip",
    skip)
