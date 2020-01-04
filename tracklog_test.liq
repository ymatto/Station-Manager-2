#!/Users/omm/.opam/default/bin/liquidsoap -v
# Log dir
set("log.file.path","/tmp/tracklog_test.log")

%include "passwords.liq"

# Write tracklog
def logtrack(metadata) =
  ignore(
    file.write(
      data="#{metadata[\"artist\"]} - #{metadata[\"album\"]} - #{metadata[\"title\"]}\n",
      append=true,
      "tracklog_test.txt"
    )
  )
  log(source.id(radio))
end

# Music (shuffle mode is default)
playlist1 = playlist(id="Short Traxxz", "~/Radio Station/MusicTest/Short Tracks/")

radio = playlist1

radio = mksafe(
  crossfade(
    on_metadata(logtrack, radio
    )
  )
)

radio = on_metadata(logtrack, radio)

# Stream it out
output.icecast(%mp3(bitrate=192),
  host = "localhost", port = 8868,
  password = icecastpassword, mount = "test.mp3",
  name = "TEST RADIO",
  description = "Testing something out",
  genre = "TEST",
  url = "",
  radio)
