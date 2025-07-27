#!/bin/bash

# Number of Fridays to generate
weeks=10

# Camera source subdirectories
camera_sources=(
  "360 X4/[Raw]"
  "360 X4/WorldLocked"
  "360 X4/CameraLocked"
  "Ace Pro"
  "Akaso Broken"
  "Akaso Timelapse"
  "Drone"
  "GoPro"
)

# Function to get the next Friday from today
get_next_friday() {
  date -d "next Friday" +%Y-%m-%d
}

# Get next Friday date
start_date=$(get_next_friday)

# Loop through weeks
for ((i=0; i<weeks; i++)); do
  # Calculate current Friday
  current_date=$(date -d "$start_date +$((7 * i)) days" +%y-%m-%d)
  folder_prefix="${current_date} Upload -"

  # Check for existing folder with matching prefix
  existing_folder=$(find . -maxdepth 1 -type d -name "${folder_prefix}*" | head -n 1)

  if [[ -n "$existing_folder" ]]; then
    echo "⚠️  Skipping: Folder already exists that starts with '$folder_prefix'"
    continue
  fi

  folder_name="${folder_prefix}"
  echo "Creating: $folder_name"
  mkdir -p "$folder_name/Thumbs"

  raw_path="$folder_name/Raw Footage"
  mkdir -p "$raw_path"

  # Create camera source subdirectories
  for cam in "${camera_sources[@]}"; do
    mkdir -p "$raw_path/$cam"
  done
done

echo "✅ All folders and subdirectories created successfully!"
