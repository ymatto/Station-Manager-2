## SM2 Extras

Bits and bobs that might help with your Station Manager 2 netradio station.

### `Radio Show Sync.app` applescript for MacOS

If you're on MacOS, using Apple Music to manage your music library, this might be handy for you.

It is an applecript that automatically syncs the tracks from a set of playlists from Apple Music out to a corresponding set of folders at a drive location you specify. If your chosen folder location is the place where your SM2 station is configured for, then it provides a nice way to manage your netradio station's music library in Apple Music, syncing as necessary to update the SM2 station's music.

During each sync run, it will add/remove tracks from the external folders as necessary. It also automatically applies a set of ID3 metadata tags to each exported track. The reason is that Apple Music stores a variety of metadata, such as ratings, outside of standard ID3 tags on the files themselves. So this script makes that data from Apple Music available via custom ID3 tags that can be used with SM2's filtering features. ID3 tags the script applies are:

* `am_date_added` - unix timestamp at which the track was added to Apple Music
* `am_modification_date` - unix timestamp at which the track was last modified in Apple Music
* `am_favorited` - true/false if the track has been favorited in Apple Music
* `am_album_favorited` - true/false if the track's album has been favorited in Apple Music
* `am_rating` - 0-100 translation of Apple Music's 5-star rating on the track
* `am_rating_kind` - "user" or "computed", the kind of the track rating
* `am_album_rating` - 0-100 translation of Apple Music's 5-star rating on the track's album
* `am_album_rating_kind` - "user" or "computed", the kind of the album rating

To use the metadata features, you'll need to install the utility "eyeD3", which is available via Homebrew.

To configure the applescript, open it in Script Editor and change the stuff under EDIT USER SETTINGS HERE.

You can either run the script in place, or it can be handy to put it in Apple Music's script folder, making it available as a menu item. This folder is typcically located at `~/Library/Music/Scripts/`


### `set_mp3_modtime.sh` shell script

This is a simple example shell script for using the `eyeD3` commandline ID3 tagging tool. It takes a folder, and to each mp3 file in the folder it reads the unix modification time and applies it in a custom "modification_time" ID3 tag, which might be useful with SM2 filtering.

If of course requires installation of the `eyeD3` utility to work.