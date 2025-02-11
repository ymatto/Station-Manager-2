# Station Manager 2

## Introduction

**Station Manager 2** is a system using Liquidsoap that makes it easy to set up and operate fully automated netradio stations. Shows may be defined by folders of audio files, with shows scheduled to play at different times of day across the week.

The included `docker-compose.yml` and example json configuration files make it easy to start up an example station, including icecast broadcast, which can then be modified to suit.

The included Text-To-Speech `TTS_server.rb` script can also be optionally used to enable automated voice synthesis for your station's DJ. This script must be run separately from the core docker compose setup.


## Running Station Manager 2

Using the main `docker-compose.yml` and Station Manager 2 config to run in the background:
`docker compose up -d`

Single-running the main `docker-compose.yml` for easy debugging:
`docker compose up --abort-on-container-exit`

Single-running with the test yml for standalone test scripts:
`docker compose -f test-docker-compose.yml up --abort-on-container-exit`

To run the TTS server script with default config, run `TTS_server.rb` within its folder:


## What's Included

...


## Configuration

### Configuring the netradio station

... three different config json files ...


### Configuring the TTS server

Environment variables:
- `PORT` (defaults to 3000) for the port the server will listen for requests
- `ENDPOINT` (defaults to "/say") for the HTTP path for the endpoint for requests
- `OUTPUT_PATH` (defaults to "tmp/") for the resulting audio file

Configure the Station Manager netradio station to match these paramters for TTS requests.

If using TTS_server with a client calling from docker, make sure the OUTPUT_PATH is visible to the docker environment, and the path configured for the station is the docker-local path. For example, if a docker container maps the host's `~/stationmanager2` folder to `/sm2` within docker, TTS_server might use the default `tmp/` for `OUTPUT_PATH` (which might put it at `~/stationmanager2/TTS_server/tmp/`), but stationmanager's `tts_announcements_path` might need to be `/sm2/TTS_server/tmp/`.


## Roadmap

...