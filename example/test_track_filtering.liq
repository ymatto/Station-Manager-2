# Testing out playlist filtering, to be implemented in SM2, based on:
#   • Metadata-based "specials" that may have requirements for when and how often they play
#   • Non-repetition requirements on tracks or certain metadata tags for various durations of time

log("TEST SCRIPT STARTUP...")


# GLOBALS --------------------------------------

# NOTE These 3 represent data that would be pulled in from the main stationconfig.json in the real SM2 script
#   These make heavy use of records mostly because that's what comes in from easy-to-read JSON config files

# This is your definition for specials to classify tracks with and filter on
#   name is your own name for the special, to be referred to in the station_specials_reqs
#   rules is a list of rules that must all be fulfilled for a track to be classified with this special
#       tag is the metadata tag to use for the rule
#       filter is one of a list that defines how to interpret and filter based on the tag:
#           is number equal to
#           is number no less than
#           is number no more than
#           is string
#           is string that includes
#           is timestamp in the last seconds
#           is year in the last years
#           is date in the last days (YYYY-MM-DD format)
#       value is what to measure the rule against
station_specials = [
    { name = "Best Of", rules = [
        { tag = "am_rating", filter = "is number no less than", value = "100" } ]
    },
    { name = "Last 30-day Adds", rules = [
        { tag = "am_date_added", filter = "is timestamp in the last seconds", value = "2592000" } ]
    }
]
# This is your definition for when or how often specials should ideally be played
#   special_name refers to one of the specials you defined in station_specials
#   per_hour_target, if set, is a target number of plays for the special within a given hour
#   try_top_of_hour, if set, tries to play the special as the first thing after an hour switch
# TODO ... also want to implement options for try_show_start and try_show_end
station_specials_reqs = [
    {
        special_name = "Best Of",
        per_hour_target = 3,
        try_top_of_hour = true
    },
    {
        special_name = "Last 30-day Adds",
        per_hour_target = 1,
        try_top_of_hour = false
    }
]
# This is your definition for what sorts of repetitions should be disallowed
#   tag_name sets a metadata tag to check for repetition ("filename" isn't technically an ID3 tag but can be treated like one here)
#   dont_repeat_within_last is one of a list of options for the period during which the tag should not be repeated:
#       track
#       15 minutes
#       hour
#       3 hours
#       12 hours
#       day
station_nonrepetition_reqs = [
    {
        tag_name = "filename", dont_repeat_within_last = "track"
    },
    {
        tag_name = "album", dont_repeat_within_last = "15 minutes"
    }
]


# NOTE already provided in SM2 - don't duplicate
current_show_source = ref (blank())

# keep track of what specials requirements are overdue
specials_req_overdue_states = ref([]) # [ ("Best Of", false), (...) ]
specials_req_plays_this_hour = ref([]) # [ ("Best Of", 3), (...) ]
specials_hour = ref(time.local().hour)

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


# UTILITY FUNCTIONS --------------------------------------


# NOTE - similar to an existing SM2 script function, but different for another purpose
def get_time_since_last_hour_at(this_time)
    sec = time.local(this_time).sec
    min = time.local(this_time).min
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


# SOURCE/TRACK PROCESSING FUNCTIONS --------------------------------------


# Return the list of this station's specials that the track in question matches
def classify_track(this_metadata)

    # Set the context for the track for handlers
    classifying_track_metadata = ref(this_metadata)

    # Iterator to see if each rule is met
    def check_rule(this_rule)
        # bunch of logic to check classifying_track_metadata against this_rule.tag/.filter/.value
        this_tag = this_rule.tag
        this_tag_value = list.assoc(default="", this_tag, classifying_track_metadata())
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
            null()
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
        specials_matched = list.filter_map(check_special, station_specials)
        # update the cache
        track_special_matches_cache := list.add((this_filename, specials_matched), track_special_matches_cache())
        # return the (now cached) results
        specials_matched
    end
end


# Keep track of some things *between calls* to is_request_approved, so we can be smarter when churning through request rejections
last_current_track_checked = ref("")
number_failed_request_checks = ref(0)

# Called as source's check_next - decide if the next request should be played or not based on specials and repetition rules
def is_request_approved(req) =

    # Find out what the proposed request to play next is and consider its suitability
    request.resolve(req)
    next_request_filename = request.filename(req)
    next_request_metadata = ref([]) # don't get it until we know it's a valid file

    def update_specials_and_last_played_state()
        # get the playing track (likely just started as the next playlist request)
        current_track_metadata = source.last_metadata(current_show_source()) ?? []
        current_track_remaining = source.remaining(current_show_source())
        current_track_filename = current_track_metadata["filename"]

        top_of_hour_play = ref(false)

        def increment_special_req_plays(this_special_name)
            this_playcount = list.assoc(default=0, this_special_name, specials_req_plays_this_hour())
            specials_req_plays_this_hour := list.add((this_special_name, this_playcount + 1), list.assoc.remove(this_special_name, specials_req_plays_this_hour()))
        end

        # update state of specials and repetitions, if we haven't done so for the playing track
        if last_current_track_checked() != current_track_filename then # only do this once per track switch
            log("Updating state of specials with: " ^ current_track_filename)
            last_current_track_checked := current_track_filename

            # if it will be a new hour at the end of this track, clear specials tracking for last hour
            # and reset current hour so we register this track's specials toward next hour
            time_at_track_end = time() + current_track_remaining
            hour_of_track_end = time.local(time_at_track_end).hour
            if specials_hour() != hour_of_track_end then
                log("Next track will start in a new hour of specials!")
                specials_req_overdue_states := []
                specials_req_plays_this_hour := []
                specials_hour := hour_of_track_end
                top_of_hour_play := true
            else
                top_of_hour_play := false
            end

            # get the specials the playing track matches
            track_special_names = classify_track(current_track_metadata)
            # increment specials_req_plays_this_hour with the the track_special_names
            list.iter(increment_special_req_plays, track_special_names)
            log("Latest specials plays this hour: " ^ string(specials_req_plays_this_hour()))

            # update specials_req_overdue_states **for time at the expected end of current track**

            def get_special_state(this_special_reqs)

                this_special_name = this_special_reqs.special_name # "Best Of"
                this_per_hour_target = this_special_reqs.per_hour_target ?? 0
                this_try_top_of_hour = this_special_reqs.try_top_of_hour ?? false
                this_special_overdue_state = ref(false)
                
                if this_try_top_of_hour and top_of_hour_play() then
                    this_special_overdue_state := true # per_hour_target doesn't matter - top_of_hour requirement makes this special immediately overdue
                elsif this_per_hour_target > 0 then
                    req_period = 3600.0 / float_of_int(this_per_hour_target)
                    expected_time_since_hour = get_time_since_last_hour_at(time() + current_track_remaining)
                    target_plays = int_of_float(floor( (expected_time_since_hour + (req_period / 2.0)) / req_period ) )
                        # for example, 3 plays per hour means that we should be adding target_play counts at 10, 30, and 50 minute marks
                    actual_plays = list.assoc(default=0, this_special_name, specials_req_plays_this_hour())
                    if target_plays > actual_plays then
                        # we're behind - make this overdue
                        this_special_overdue_state := true
                    end
                end

                (this_special_name, this_special_overdue_state())
            end

            new_specials_overdue_states = list.map(get_special_state, station_specials_reqs)
            specials_req_overdue_states := new_specials_overdue_states

            # Update last_plays_cache based on current_track's metadata
            log("Updating last play times with: " ^ current_track_filename)

            def get_updated_last_plays_for_each_required_tag_name(this_nonrepetition_req)
                this_tag_name = this_nonrepetition_req.tag_name
                this_last_plays = list.assoc(default=[], this_tag_name, last_plays_cache())

                tag_of_current_track = list.assoc(default="", this_tag_name, current_track_metadata)
                updated_this_last_plays = list.add((tag_of_current_track, time()), list.assoc.remove(tag_of_current_track, this_last_plays))
                (this_tag_name, updated_this_last_plays)
            end

            last_plays_cache := list.map(get_updated_last_plays_for_each_required_tag_name, station_nonrepetition_reqs)
        end
    end

    def return_special_name_if_overdue(this_special_req_overdue_state)
         let (special_name, state) = this_special_req_overdue_state
        # only return the req_name if its overdue state is true
        if state then
            special_name
        else
            null()
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
            playing_track_metadata = source.last_metadata(current_show_source()) ?? []
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

    # make sure specials state is correct before looking at anything else
    update_specials_and_last_played_state()

    log("CHECKING REQUEST: " ^ next_request_filename)

    if number_failed_request_checks() > 10 then # TODO work out the right number here.... no idea. At min need to prevent infinite loops if there is nothing.
        log("APPROVED - Too many failed expensive checks, so accepting track to move on!")
        number_failed_request_checks := 0
        true
    else
        # Reject if this is a dumb hidden file like .DS_store
        file_only_name = list.last(string.split(separator="/", next_request_filename))
        if (string.sub(file_only_name, start=0, length=1) == ".") then
            log("REJECTED - Hidden file - not a valid track!")
            false
        else
            next_request_metadata := request.metadata(req)
            # log(string(next_request_metadata())) # if you want to take a look at all metadata available

            # Reject if the track is a repetition that violates the stations rules
            
            number_failed_request_checks := number_failed_request_checks() + 1 # count it, now that the cheap check is done
            all_repetition_rules_satisfied = list.for_all(is_nonrepetition_req_satisfied, station_nonrepetition_reqs)
            if not all_repetition_rules_satisfied then
                log("REJECTED - Track violates repetition rule!")
                false
            else
                # Classify the track's specials and see if it meets any overdue specials requirements

                # classify the track no matter what, even if no speicials are overdue, to build up the cache if nothing else
                classified_track_special_names := classify_track(next_request_metadata())
                log("This track matches specials: " ^ string(classified_track_special_names()))

                # get list of the names of overdue requirements only
                overdue_special_names = list.filter_map(return_special_name_if_overdue, specials_req_overdue_states())
                log("Currently overdue specials: " ^ string(overdue_special_names))
                
                if list.length(overdue_special_names) > 0 and not list.exists(does_classified_track_include_special, overdue_special_names) then
                    # try again...
                    log("REJECTED - Track doesn't meet any of the currently overdue requirements!")
                    false
                else
                    # success!
                    log("APPROVED - Track is good to play based on current requirements!")
                    # reset the counter and approve this track to play next
                    number_failed_request_checks := 0
                    true
                end
            end
        end
    end
    # TODO Add show start/end options
end



# SET UP SOURCES --------------------------------------


# run the playlist, with check_next
playlist_source = playlist(id="playlist source", check_next=is_request_approved, register_server_commands=false, "music/funky/")

# only doing this "update" because it replciates how SM2 keeps track of changing sources
current_show_source := playlist_source

# set this to what you ultimately want going out to icecast
broadcast_source = playlist_source
    


# SET UP TEST BROADCAST --------------------------------------

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

    

# SET UP TEST TELNET SERVER --------------------------------------

settings.server.telnet.set(true)
settings.server.telnet.port.set(1234)
settings.server.telnet.bind_addr.set("0.0.0.0")
settings.server.timeout.set(-1.0) # negative value disables timeout


# SERVER COMMMAND HANDLERS --------------------------------------

def skip(input_string) =
    source.skip(broadcast_source)
    "Done."
end


server.register(namespace="test",
    usage="skip",
    description="Next track.",
    "skip",
    skip)

