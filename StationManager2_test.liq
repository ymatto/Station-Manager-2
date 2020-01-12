#!/Users/omm/.opam/default/bin/liquidsoap -v

%include "passwords.liq"  # sets variable: icecastpassword


# LOAD STATION CONFIG
# TODO: allow multiple configs within the config file for multiple output streams of the same station
config_file = file.contents("stationconfig.json")
station_config_strings = of_json(default=[("error", "no station config")], config_file)
station_config_ints = of_json(default=[("", 0)], config_file)

if station_config_strings["error"] == "no station config" then
  log("station config invalid")
end

# TODO: These should probably all use list.assoc to have specified defaults
station_name = station_config_strings["name"]
station_description = station_config_strings["description"]
# station_spoken_ID = station_config_strings["spoken_ID"]
station_log_path = station_config_strings["log_path"]
station_tracklog_path = station_config_strings["tracklog_path"]
station_currentshow_path = station_config_strings["currentshow_path"]
# station_output_encoding = station_config_strings["currentshow_encoding"]
# station_output_bitrate = list.assoc(default=192, "bitrate", station_config_ints)
# station_format = # ... TODO: er, has to be weird "format" type
station_host = station_config_strings["host"]
station_port = list.assoc(default=8000, "port", station_config_ints)
station_mount = station_config_strings["mount"]
station_genre = station_config_strings["genre"]
station_url = station_config_strings["url"]
# station_playlists_root = station_config_strings["playlists_root"]

# Log dir
set("log.file.path",station_log_path)



# LOAD SHOWS AND SCHEDULE
# TODO: If no file configured, should be smart enough to just pull list of
#       directories from station_playlists_path and use default settings


# Music (shuffle mode is default)
pl_afterparty = playlist(id="afterparty", "/Users/omm/Radio Station/Music/Afterparty")
pl_braindance = playlist(id="braindance", "/Users/omm/Radio Station/Music/Braindance")
pl_bump = playlist(id="bump", "/Users/omm/Radio Station/Music/Bump in the Trunk")
pl_beats = playlist(id="beats", "/Users/omm/Radio Station/Music/Instrumental Hip-Hop")
pl_headnod = playlist(id="headnod", "/Users/omm/Radio Station/Music/Laid Back Hip-Hop")
pl_nightmode = playlist(id="nightmode", "/Users/omm/Radio Station/Music/Late Night Electronic")
pl_groovestyle = playlist(id="groovestyle", "/Users/omm/Radio Station/Music/Stylish Background")

radio = mksafe(
          crossfade(
            switch(
              [
                ({ 0w and 0h-7h }, pl_afterparty),
                ({ 0w and 7h-20h }, pl_groovestyle),
                ({ 0w and 20h-24h }, pl_nightmode),
                ({ (1w or 3w) and 0h-7h }, pl_afterparty),
                ({ (1w or 3w) and 7h-10h }, pl_groovestyle),
                ({ (1w or 3w) and 10h-20h }, pl_braindance),
                ({ (1w or 3w) and 20h-24h }, pl_nightmode),
                ({ (2w or 4w) and 0h-7h }, pl_beats),
                ({ (2w or 4w) and 7h-11h }, pl_headnod),
                ({ (2w or 4w) and 11h-16h }, pl_bump),
                ({ (2w or 4w) and 16h-22h }, pl_headnod),
                ({ (2w or 4w) and 22h-24h }, pl_beats),
                ({ 5w and 0h-4h }, pl_afterparty),
                ({ 5w and 4h-10h }, pl_groovestyle),
                ({ 5w and 10h-20h }, pl_braindance),
                ({ 5w and 20h-24h }, pl_afterparty),
                ({ 6w and 0h-7h }, pl_afterparty),
                ({ 6w and 7h-12h }, pl_groovestyle),
                ({ 6w and 12h-20h }, pl_braindance),
                ({ 6w and 20h-24h }, pl_nightmode)
              ]
            )
          )
        )




# FUNCTION defs

currentshow = ref ""

# Write stuff whenever there's a new track
def logtrack(metadata) =
  ignore(
    file.write(
      data="#{metadata[\"artist\"]} - #{metadata[\"album\"]} - #{metadata[\"title\"]}\n",
      append=true,
      station_tracklog_path
    )
  )
  newshow = "#{metadata[\"source\"]}"
  oldshow = !currentshow
  if newshow != oldshow then
    currentshow := newshow
    ignore(
      file.write(
        data=newshow,
        append=false,
        station_currentshow_path
      )
    )
  end
end




# BUILD THE OUTPUT SOURCE

# Add some jingles
# radio = random(weights = [1, 4],[jingles, radio])

# Add fallback security
# If something goes wrong, we'll play this
# security = single("~/radio/sounds/default.ogg")
# radio = fallback(track_sensitive = false, [radio, security])

radio = on_metadata(logtrack,radio)

# Stream it out
output.icecast(%mp3(bitrate=192),
  host = station_host, port = station_port,
  password = icecastpassword, mount = station_mount,
  name = station_name,
  description = station_description,
  genre = station_genre,
  url = station_url,
  radio)
