# Station Manager 2

## Introduction

**Station Manager 2** is a system using [Liquidsoap](https://www.liquidsoap.info/) and [Icecast](https://icecast.org/) that makes it easy to set up and operate fully automated netradio stations. Shows may be defined by folders of audio files to be used as playlists, with shows scheduled to play at different times of day across the week.

The main logic of Station Manager 2 is the `StationManager2.liq` Liquidsoap script file, which runs your playlist-based shows and expects to be able to output to an Icecast server for broadcast.

The included `docker-compose.yml` makes it easy to start up an example station using dockerized Liquidsoap and Icecast with any additional installation (as long as you have [Docker](https://www.docker.com/)). It makes use of the included example json configuration files, and example `icecast.xml`  including Icecast broadcast, which can then be modified to suit. Docker-based operation is recommended, but Station Manager 2 can also be configured for use with locally-installed Liquidsoap and Icecast.

The included Text-To-Speech `TTS_server.rb` script can also be optionally used to enable automated voice synthesis for your station's DJ. This script must be run separately from the core docker compose setup.

> [!NOTE]
> Station Manager 2 is currently designed to work with **Liquidsoap v2.3.0** and **Icecast v2.4.4**



## Running Station Manager 2

Using the main `docker-compose.yml` and Station Manager 2 config to run in the background:
`docker compose up -d`

Single-running the main `docker-compose.yml` for easy debugging:
`docker compose up --abort-on-container-exit`

Single-running with the test yml for standalone test scripts:
`docker compose -f test-docker-compose.yml up --abort-on-container-exit`

To run the TTS server script with default config, run `TTS_server.rb` within its folder:



## Configuring Your Netradio Station

Station Manager is designed to let you act as the owner of a netradio station that runs like a traditional AM/FM broadcast station. You define the shows that will run on your station, the playlist of music those shows will play, "who" will DJ those shows, and the schedule of shows 24/7.

Station Manager expects you to configure your netradio station via 3 json files:
- `stationconfig.json` - The **station config** defines global parameters for the station and its icecast broadcast.
- `showconfig.json` - The **show config** defines parameters for each show your station will play.
- `showschedule.json` - The **show schedule** defines the schedule on which the various shows will play.

Different filenames can be used for all three files, letting you do things like configure multiple netradio stations in the same folder and run them with different instances of Station Manager. The filenames above are the defaults Station Manager will look for, but a different **station config** file can be specified as an argument to Station Manager, and that config file can in turn specify paths for **show config** and **show schedule**.

The included example config files set up a netradio station from the included pair of folders of music in the `music/` folder, and are a good place to start in customizing your own netradion station.

Here is a breakdown of the available parameters in the json config files.

### Station Config

The station config is a JSON dictionary with the following possible keys. Keys with default values may be omitted, but keys that are REQUIRED must be specified in the file to successfully create a station.

| Key | Type | Default | Description
| :--- | :---: | :---: | :------------------------
| showconfig_path         | String | `showconfig.json` | Path to the show config file to use
| showschedule_path       | String | `showschedule.json` | Path to the show schedule file to use
| playlists_root         | String | `music/` | Path to folder containing playlist folders to be identified by name for shows
| icecast_name            | String | (empty) | Name used in Icecast metadata
| icecast_description     | String | `A Station Manager 2 netradio station` | Description used in Icecast metadata
| icecast_genre           | String | (empty) | Genre used in Icecast metadata
| icecast_url             | String | (empty) | Station URL used in Icecast metadata. This may not end in the icecast_mount defined below if Icecast has been configured with an alias to the mount
| icecast_mount          | String | `radio.mp3` | Where the broadcast stream will be mounted at the Icecast host
| icecast_encoding        | String | `mp3_128k` | Audio format to use for Icecast broadcast to users. Must be one of: `mp3_320k`, `mp3_256k`, `mp3_192k`, `mp3_160k`, `mp3_128k`, `mp3_64k`, `vorbis_q3` (quality 3), `vorbis_q6` (quality 6)
| icecast_password       | String | **REQUIRED** | Password Icecast requires for input audio
| icecast_host           | String | `localhost` | Where station manager can find the Icecast host. If running dockerized, this will often be the mount name applied to the Icecast container
| icecast_port           | Number | 8000 | Port where Icecast communicates
| id_announcement        | String | (empty) | Text, or path to audio file within the station's `announcements_path`, used for hourly station IDs
| voice_type             | String | (empty) | The TTS handler used for announcements. If the voice_type is unsupported, announcements must be paths to prerecorded audio files rather than text to speak. Currently only `tts_server_macos` is supported, using the TTS_server script (see below)
| default_voice          | String | (empty) | Voice to specify to TTS handler, if the show has not specified one
| tts_server_endpoint    | String | `http:// host.docker.internal:3000 /say` | URL where you have configured the TTS_server script to listen, if a TTS handler has been specified for the voice_type
| log_path               | String | `logs/StationManager2.log` | Path to general running log from Liquidsoap. If set to empty, no log is written
| tracklog_path          | String | `logs/recent_tracks.log` | Path to a list of the most recently played tracks. If set to empty, no log is written
| currentshow_path       | String | `logs/current_show.log` | Path to a file listing the currently-playing show. If set ot empty, no long is written
| telnet_server          | Boolean | `false` | If set to `true`, enables a telnet server to send manual commands to the station
| telnet_server_port     | Number | 1234 | Port where the server listens
| telnet_server_timeout  | Number | 60 | Seconds that an inactive telnet connection remains alive. Set to a negative number to keep it open indefinitely
| telnet_server_netmask  | String | "0.0.0.0" | Netmask for allowed telnet server connections
| announcements_path     | String | `announcements/` | Path to folder containing pre-recorded announcement audio files that may be referenced by filename
| tts_announcements_path | String | `TTS_server/tmp/` | Path to folder where the TTS_server script is configured to write out audio files for use



### Show Config

The show config is a JSON dictionary containing a list of dictionary keys for each show.

Create a dictionary for each show and name it with the key you will use to refer to each show in the show schedule (for example `Hiphop`).

Each show dictionary in turn is defined by this list of keys. Keys with default values may be omitted, but keys that are REQUIRED must be specified in the file to successfully create a show.

| Key | Type | Default | Description
| :--- | :---: | :---: | :------------------------
| playlist_path         | String | **REQUIRED** | Path to this show's folder of music within the `playlist_root` in the station config
| show_longname         | String | (empty) | Currently only used when writing out a log to the `currentshow_path`
| show_description      | String | (empty) | Currently not used
| DJ_voice              | String | (empty) | TTS voice to use for announcements during this show. If empty, the station's `default_voice` will be used
| signon_announcement   | String | (empty) | Voiceover text to speak when the show begins, or path to audio within the station's `announcements_path`
| signoff_announcement  | String | (empty) | Voiceover text to speak just before the show ends, or path to audio within the station's `announcements_path`
| shuffle_mode          | String | `songs` | Method of shuffling songs within the playlist folder (currently only `songs` is supported)


### Show Schedule

The show schedule is a JSON array of show schedule entries. Each entry is a definition of a 24-hour day of programming, and can specify how that day is filled with shows, and when this particular profile of programming day is used (for example "on Mondays, Wednesdays, and Fridays").

Each show schedule entry is itself a dictionary with the following keys:

| Key | Type | Default | Description
| :--- | :---: | :---: | :------------------------
| type        | String | `everyday` | Type of schedule this schedule entry. Currentl options are `everyday` (`days` key not used) and `daysofweek` (`days` key required)
| days        | Arra of Strings | **REQUIRED** (for `daysofweek`) | For `type` of `daysofweek`, the days of the week on which this show schedule entry applies, eg. `["Monday", "Wednesday", "Friday"]`
| show_hours  | Array of Numbers | **REQUIRED** | The hours of the day at which shows should change, eg. `[6, 12, 20]` would indicate that there should be a show change at 6am, noon, and 8pm. If `0` isn't specified, whatever show was playing at the end of the previous day will continue playing until the first indicated time.
| show_names  | Array of Strings | **REQUIRED** | The names of the shows (by their key name in the show config) that should start at the times indicated in `show_hours`. **This array must be of the same length as `show_hours`**, with each time corresponding to each show name here.


## Configuring Icecast for Broadcast

The Station Manager script expects to stream audio to an Icecast server for broadcast. The Icecast server needs to be configured to match the icecast parameters defined above, including password and port of the listen-socket. Generally an fairly standard `icecast.xml` configuration file can be used. An example is provided that works with the included `docker-compose.yml` setup and may serve as a good basis for modification.

Of note, you can broadcast multilpe Station Manager netradio stations through your single Icecast server, as long as they each have their own `icecast_mount` (as specified in the station config).

For other options, see the [documentation for Icecast](https://icecast.org/docs/).



## Configuring the TTS Server (optional)

The TTS_server Ruby script gives your DJs an automatic voice, speaking various bits of text in a voice you choose. Currently it only runs on a MacOS host, using the Mac's built-in "say" command.

However, it should be easy to modify the script to add your own hanlder to the script for whatever TTS utility and host OS is most convenient for you. Essentially the script takes a request for speech from Station Manager and it must generate an audio file that it provides the path for back to Station Manager to play.

More documentation can be found in the `TTS_server` folder, but here are the basics:

TTS_server is configured via environment variables:
- `PORT` (defaults to 3000) for the port the server will listen for requests
- `ENDPOINT` (defaults to "/say") for the HTTP path for the endpoint for requests
- `OUTPUT_PATH` (defaults to "tmp/") for the resulting audio file

Configure the Station Manager netradio station to match these paramters for TTS requests.

If using TTS_server with a client calling from docker, make sure the OUTPUT_PATH is visible to the docker environment, and the path configured for the station is the docker-local path. For example, if a docker container maps the host's `~/stationmanager2` folder to `/sm2` within docker, TTS_server might use the default `tmp/` for `OUTPUT_PATH` (which might put it at `~/stationmanager2/TTS_server/tmp/`), but stationmanager's `tts_announcements_path` might need to be `/sm2/TTS_server/tmp/`.




## Roadmap

...