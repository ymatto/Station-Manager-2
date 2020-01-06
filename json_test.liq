#!/Users/omm/.opam/default/bin/liquidsoap -v
# Log dir
set("log.file.path","/tmp/json_test.log")

%include "passwords.liq"

# config_file = file.contents("showconfig.json")

# station_config = of_json(default=[("error", [("no show", "found")])], config_file)

# this_show = station_config["Bump"]

# log(this_show["DJ_voice"])


testvar = [("key1", [("subkey1", "value1")]), ("key2", [("subkey2", "value2")])]
subtestvar = list.assoc("key1", testvar)

log (string_of(subtestvar))

radio = blank()

output.icecast(%mp3(bitrate=192),
  host = "localhost", port = 8868,
  password = icecastpassword, mount = "test.mp3",
  name = "TEST RADIO",
  description = "Testing something out",
  genre = "TEST",
  url = "",
  radio)
