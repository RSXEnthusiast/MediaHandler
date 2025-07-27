#!/bin/bash

echo Moving Files
find . -mindepth 2 -type f -iname "*.jpg" -exec bash -c '
  for file; do
    echo "Moving: $file"
    mv "$file" .
  done
' bash {} +

echo Removing Empty Directories
find -type d -empty -delete

shopt -s nullglob nocaseglob

echo Renaming Files
files=( *.jpg )

if [ ${#files[@]} -eq 0 ]; then
  echo "No JPG files found."
  exit 0
fi

counter=1
for f in "${files[@]}"; do
  new_name="Nightlapse${counter}.jpg"
  echo "Renaming '$f' -> '$new_name'"
  mv -- "$f" "$new_name"
  ((counter++))
done

echo Creating Nightlapse
ffmpeg -framerate 30 -i Nightlapse%d.JPG -c:v hevc_nvenc -preset slow -qp 0 -pix_fmt nv12 Nightlapse.mp4
