#!/Users/omm/.opam/default/bin/liquidsoap -v

set("log.file.path","/tmp/simpletest.log")

settings.server.telnet.set(true) # to create test commands - would be replaced by DJ bot logic

# set up input harbor for broadcast

harborstream = input.harbor("test-harbor", port=8050, password="fat")

final = mksafe(harborstream)

output.icecast(%mp3(bitrate=192),
  host = "localhost", port = 8000,
  password = "GUEvoN3gKVKc9vwW", mount = "basscadettest.mp3",
  name = "BASSCADETTEST", final)


# bootstrap killable output source

bootstrap_source = output.icecast(%wav,
  host = "localhost", port=8050,
  password = "fat", mount = "test-harbor", blank())

current_output_source = ref(bootstrap_source)
current_output_source_shutdown = ref(bootstrap_source.shutdown)


  

# function to switch input source

def switch_stream(path) =
  shut_this_down = !current_output_source_shutdown
  shut_this_down()

  newsource = mksafe(playlist(path))  
  out = output.icecast(%wav,
    host = "localhost", port=8050,
    password = "fat", mount = "test-harbor", newsource)
  current_output_source := out
  current_output_source_shutdown := out.shutdown
  "Switched to #{path} !"
end

# TELNET

  server.register(namespace="output",
                  description="Switch to new playlist as output to harbor input source.",
                  usage="switch <path>",
                  "switch",
                  switch_stream)


      