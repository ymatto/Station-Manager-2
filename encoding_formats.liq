
encoding_formats = [
    ("mp3_320k", %mp3(bitrate=320, stereo=true)),
    ("mp3_256k", %mp3(bitrate=256, stereo=true)),
    ("mp3_192k", %mp3(bitrate=192, stereo=true)),
    ("mp3_160k", %mp3(bitrate=160, stereo=true)),
    ("mp3_128k", %mp3(bitrate=128, stereo=true)),
    ("mp3_64k", %mp3(bitrate=64, stereo=true)),
    ("vorbis_q3", %vorbis(quality=0.3, channels=2)),
    ("vorbis_q6", %vorbis(quality=0.6, channels=2))
]
