#!/bin/bash

shopt -s nullglob

for file in *.MP4; do
    base="${file%.*}"
    ext="${file##*.}"

    # Match pattern: 1 char, 1 char, 4 chars, 2 chars
    if [[ $base =~ ^(.)(.)(....)(..)$ ]]; then
        newbase="${BASH_REMATCH[1]}${BASH_REMATCH[4]}_${BASH_REMATCH[3]}_${BASH_REMATCH[2]}"
        newfile="${newbase}.${ext}"
        echo "Renaming '$file' -> '$newfile'"
        mv "$file" "$newfile"
    else
        echo "Skipping '$file' – doesn't match expected pattern"
    fi
done
