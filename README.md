# Station Manager 2

**For documentation on configuration and usage**, [see the wiki right here on GitHub](https://github.com/ymatto/Station-Manager-2/wiki).
You can find the Station Manager homepage at [stationmanager.tech](https://stationmanager.tech)

## Introduction

**Station Manager 2** is a system using [Liquidsoap](https://www.liquidsoap.info/) and [Icecast](https://icecast.org/) that makes it easy to set up and operate fully automated netradio stations. Like a traditional radio station, your netradio station can include multiple "shows", which play different tracks out of folders of music you provide. Shows can be scheduled to play at different times of day, across the week. An automated DJ reads your show schedule and handles the details for you, including spoken announcements if you want. Or you can tell the DJ what to do manually via telnet server.

The main logic of Station Manager 2 is the `StationManager2.liq` Liquidsoap script file, which runs your playlist-based shows and expects to output to an Icecast server for broadcast to the world.

Station Manager 2 works best when run using dockerized Liquidsoap and Icecast, although it is not required.

Also included is a simple TTS_server script that enables use of Text-To-Speech for automated on-air announcements.


## Wait, but...

Where did Station Manager 1 go?

[Why'd you ask me that question?](https://www.youtube.com/watch?v=izY_6X2JRwI)

(There was actually an original Station Manager. It was written in Applescript to control iTunes and it was *perfect in every way*.)