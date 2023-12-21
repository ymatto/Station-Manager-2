#!/Users/omm/.opam/default/bin/liquidsoap -v

some_json = '{
    "port": 400,
    "name": "Radio",
    "enable": false}'


    
let json.parse results = some_json

station_port = null.get(default=0, results.port)
station_name = null.get(default="no name", results.name)
station_enable = null.get(default=false, results.enable)
station_description = null.get(default="no desc", results.description)  # null!

print("port:         #{station_port}")
print("name:         #{station_name}")
print("enable:       #{station_enable}")
print("description:  #{station_description}")