log("TEST SCRIPT STARTUP...")


# SET UP SOURCES

# handlers for sources

# TODO - don't forget to break out of loops if nothing matches
def check(req) =
    log("Starting track check")
    request.resolve(req)
    req_filename = request.filename(req)
    log("Checking request: " ^ req_filename)
    if (string.sub(req_filename, start=0, length=1) == ".") then
        log("Skipping hidden file...")
        false
    else
        # metadata is keyed to the description (like "am_track_rating") in lowercase
        # not the id3 frame label (like "--TXXX")
        md = request.metadata(req)
        # log(string(md)) # take a look at everything
        log("Trying track: " ^ md["title"])
        am_track_rating = int_of_string(md["am_rating"])
        log ("Rating: " ^ string(am_track_rating))
        if (am_track_rating < 10) then
            log("THIS TRACK NOT GOOD ENOUGH")
            false
        else
            log("GOOD TRACK")
            true
        end
    end
end


# run the playlist, with check_next
playlist_source = playlist(id="playlist source", check_next=check, "music/funky/")

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
    description = "Testing Station Manager 2",
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
