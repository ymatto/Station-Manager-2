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

bootstrap_out = output.icecast(%wav,
  host = "localhost", port=8050,
  password = "fat", mount = "test-harbor", blank())

current_output_source = ref(bootstrap_out)
current_output_source_shutdown = ref(bootstrap_out.shutdown)


# function to switch input source

 def switch_stream(path) =
  log("DEBUG: Begin switch_stream using path: #{path}")
  log("DEBUG: SHUTTING IT DOWN BOSS")
  shut_this_down = !current_output_source_shutdown
  log("      Shutting down output source...")
  shut_this_down()
  log("      Output source shut down...")
  thread.pause(0.2) # HACK - wait just a moment to finish up the shutdown before going on... although this won't work until LS 2.2

  log("DEBUG: STARTING IT UP BOSS")
  newsource = mksafe(playlist(path))  
  log("      Creating new output...")
  out = output.icecast(%wav,
    host = "localhost", port=8050,
    password = "fat", mount = "test-harbor", newsource)
  current_output_source := out
  current_output_source_shutdown := out.shutdown
  log("      switch_stream done")
  "Switched to #{path} !"

 end


# telnet server commands

server.register(namespace="test",
    description="Switch to new playlist as output to harbor input source.",
    usage="switch <path>",
    "switch",
    switch_stream)
