# Station Manager 2

## Introduction

**Station Manager 2** is a system using Liquidsoap that makes it easy to set up and operate fully automated netradio stations. Shows may be defined by folders of audio files, with shows scheduled to play at different times of day across the week.

The included `docker-compose.yml` and example json configuration files make it easy to start up an example station, including icecast broadcast, which can then be modified to suit.

The included `TTS_server.rb` script can also be optionally used to enable automated voice synthesis for your station's DJ. This script must be run separately from the core docker compose setup.


## Running Station Manager 2

Using the main `docker-compose.yml` and Station Manager 2 config to run in the background:
`docker compose up -d`

Single-running the main `docker-compose.yml` for easy debugging:
`docker compose up --abort-on-container-exit`

Single-running with the test yml for standalone test scripts:
`docker compose -f test-docker-compose.yml up --abort-on-container-exit`

To run the TTS server script with default config:
`TTS_server/TTS_server.rb`


## What's Included

...


## Configuration

...


## Roadmap
