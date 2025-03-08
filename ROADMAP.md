# Station Manager 2 Roadmap

Below is an unsorted, unfiltered, mostly-for-my-benefit listing of possible additions and improvements for Station Manager, as well as tracking of important changes for the next release.

## Completed for Next Release

### Breaking changes
(Nothing yet.)

### Additions and improvements
(Nothing yet.)


## Roadmap Items

### Broadcast/play/source options
- Check if there are any settings for the randomness applied to playlist playback
- Implement other schedule day types
  - "day-of-year?" for holidays and other special programming?
- Allow shows to ensure certain classes of songs play within in an hour
  - Things like "new music" or "5-star tracks" that you want to play with special frequency
  - Use folders for different sub-sortings but associated to one show?
  - Flags for how specials get mixed in... one-by-one periodically? Special new music hours?
  - Requires running a show based on a queue rather than a playlist???
- Add configurable live input using a harbor
- Look into HLS as an alternative to Icecast
- Interface to YouTube streaming?

### Telnet server
- Server commands to record notes about currently-playing track
  - move to different playlist, upgrade/downgrade rating, problem with file, etc.
- Look into the web interface for the server
  - [https://www.liquidsoap.info/doc-2.3.0/server.html#web-interface]
- Make sure there are a sufficient set of telnet commands to enable full external control
  - Allow turning off auto-DJ in config, and document
- `get_state`
- reeeeewiiiiiind
- Figure out how to hook an iPhone app or private webpage up to server commands for admin

### Configuration and logging
- Implement live config file reloading (with manual command, and ideally file-checking?)
- Make log formatting more consistent, and clear on the source.
  - Maybe do indenting based on how "deep" the error is coming from?

### DJ/voice options
- Up volume of voices in LS config
  - amplify function, if there's no way to do it at generation level? Maybe make it optionally configurable parameter?
- Add ability to announce track titles
  - Usage options: On request? Summary at the hour? When playing new or 5-star stuff?
- Maybe auto-announce tracks that are 5-star? (although I'm not sure it's int the metadata)
- Ability to have station ID include show like "You're listening to the Night Show on Big Radio."
- Other TTS utilities for TTS_server to call
  - ... there don't seem to be any standards, and options seem very OS-linked...
- Option to automatically pre-generate static announcements from config rather than live each time?

### Code and station quality
- Make sure playlists get reshuffled so that we don’t get the same sequences playing (especially for playlists around 24h long)
- Use reload_mode="watch" on playlist?
- Consider replacing a bunch of separate refs about a show with a single show ref with "methods"
  - LS book page 66
- Make autoDJ and its showschedule.json modular - station can be run with external logic without it
  - Use %ifdef to make autoDJ optional... I think?
- Some of the regular checking might be simpler using `thread.when`
  - LS book page 76
- Look into automatic level-setting (the LS book claims it's possible?)
- Consider some named arguments to functions for clarity, maybe some default values
  - LS book page 57+

