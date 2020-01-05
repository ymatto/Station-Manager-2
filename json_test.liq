#!/Users/omm/.opam/default/bin/liquidsoap -v
# Log dir
set("log.file.path","/tmp/json_test.log")

%include "passwords.liq"

config_file = file.contents("StationManager2_config.json")

# log(config_file)

station_config = of_json(default=[("error", [("no show", "found")])], config_file)

log(string_of(station_config))


radio = blank()

output.icecast(%mp3(bitrate=192),
  host = "localhost", port = 8868,
  password = icecastpassword, mount = "test.mp3",
  name = "TEST RADIO",
  description = "Testing something out",
  genre = "TEST",
  url = "",
  radio)
