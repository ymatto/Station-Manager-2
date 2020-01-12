#!/Users/omm/.opam/default/bin/liquidsoap -v
# Log dir
set("log.file.path","/tmp/json_test.log")


#simulated output from config file
station_playlists_root = "/Users/omm/Radio Station/Music/"

config_file = file.contents("showconfig.json")
showconfig = of_json(default=[("error", [("no show found", "")])], config_file)

def get_show((showkey,showdata)) =

end

if list.mem_assoc("error", showconfig) == false then
  list.iter(get_show, showconfig)
end



log ("okay")

radio = blank()

output.dummy(radio)
