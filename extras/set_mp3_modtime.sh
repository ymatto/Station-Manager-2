#!/bin/bash

# Set target directory, default is current directory
TARGET_DIR="${1:-.}"

# Check for eyeD3
if ! command -v eyeD3 &> /dev/null; then
    echo "eyeD3 not found. Please install it with: pip install eyeD3"
    exit 1
fi

# Loop through all mp3 files in the directory
for file in "$TARGET_DIR"/*.mp3; do
    [ -e "$file" ] || continue  # Skip if no .mp3 files

    # Get Unix modification time (in seconds) on a MacOS system
    mod_time=$(stat -f %m "$file")

    echo "Processing: $file (setting modification_time: $mod_time)"

    # Use eyeD3 to set the user-defined text frame
    eyeD3 --preserve-file-times --quiet --to-v2.4 --user-text-frame="modification_time:$mod_time" "$file"
done

echo "Done."
