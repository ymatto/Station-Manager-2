log("TEST SCRIPT STARTUP...")


# SET UP SOURCES

playlist_source = playlist(id="playlist source", "music/funky/")

playover_source = request.queue(id="playover_source")


# set this to what you ultimately want going out to icecast
# despite last documentation at v1.4.4 for smooth-add, thre is no "delay" parameter, just "duration"
broadcast_source = smooth_add(duration=1.5, p=0.1, special=playover_source, normal=playlist_source)
    


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

def say(input_string) =
    say_text = string.trim(input_string)

    log("Say request received: " ^ say_text)

    say_request = {
        tts_type="macos",
        voice="Daniel (Enhanced)",
        text=say_text,
        output_path="tmp/"
    }
    json_say_request = json.stringify(say_request)

    json_say_response = http.post(data=json_say_request, timeout=20.0, "http://host.docker.internal:3000/say")

    # parse JSON response
    let json.parse say_response = json_say_response
    result = say_response.result ?? "ERROR"
    data = say_response.data ?? "Bad response from TTS script"

    if (result == "SUCCESS") then
        # TODO probably should also check to see if there's a valid wav or something ideally.
        say_file_path = "/tmp/" ^ data

        # Queue up the speech along with some bookending silence
        playover_source.push(request.create("synth:shape=sine,frequency=0.0,duration=3"))
        playover_source.push(request.create("file:" ^ say_file_path))
        playover_source.push(request.create("synth:shape=sine,frequency=0.0,duration=1"))
        "Done."
    else
        error = data
        log(error)
        error
    end    
end


server.register(namespace="test",
    usage="say <thing to say>",
    description="Say a thing.",
    "say",
    say)

