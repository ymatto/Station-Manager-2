#!/Users/omm/.opam/default/bin/liquidsoap -v
# Log dir
set("log.file.path","/tmp/basic-radio.log")

# Music
myplaylist = mksafe(playlist("~/Radio Station/Music/Independence Day/"))

# If something goes wrong, we'll play this
# security = single("~/radio/sounds/default.ogg")

# Start building the feed with music
radio = myplaylist

# Now add some jingles
# radio = random(weights = [1, 4],[jingles, radio])

# And finally the security
# radio = fallback(track_sensitive = false, [radio, security])

# Stream it out
output.icecast(%mp3,
  host = "localhost", port = 8868,
  password = "owlhousesourcekonnekt", mount = "sousa.mp3",
  radio)
