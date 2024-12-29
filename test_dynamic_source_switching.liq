#!/Users/omm/.opam/default/bin/liquidsoap -v

settings.server.telnet.set(true) # to create test commands - would be replaced by DJ bot logic
settings.server.timeout.set(120.0)
settings.server.telnet.port.set(1234)
settings.server.telnet.bind_addr.set("0.0.0.0")

current_source = ref(blank())

def set_source() = 
    current_source()
end

dynamic_source = source.dynamic(set_source)

output.icecast(
    %mp3(bitrate=192),
    host = "icecast", port = 8000,
    password = "icecast_secret", mount = "sm2_test.mp3",
    name = "STATION MANAGER 2 TEST",
    mksafe(dynamic_source)
)

# function to switch input source

def switch_stream(path) =
    current_source := playlist(path)
    "switched to: " ^ path
end


# telnet server commands

server.register(namespace="test",
    description="Switch to new playlist as output to harbor input source.",
    usage="switch <path>",
    "switch",
    switch_stream)
  