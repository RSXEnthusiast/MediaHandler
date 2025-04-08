#!/bin/bash

echo Checking for Zenity
if ! command -v zenity &> /dev/null; then
    echo "ZENITY NOT FOUND - Install zenity to continue."
    notify-send "ZENITY NOT FOUND" "Install zenity to continue."
    exit
fi

echo "Finding all mp4 files."
mapfile -d '' MEDIA_FILES < <(find .. -type f -iname "*.mp4" -print0)
TOTAL_FILES=${#MEDIA_FILES[@]}
echo "Found $TOTAL_FILES files."
PROCESSED=0
TOTAL_TIME=0

# TODO: FIX THIS | SEE README
echo "WARNING: Remaining Time is based on the average time taken for each video file and therefore won't be terribly accurate unless videos are a consistent length and format."

echo Initializing Zenity
PIPE=$(mktemp -u)
mkfifo "$PIPE"
exec 3<> "$PIPE"
rm "$PIPE"

( zenity --progress --title="MediaHandler | Processing Media" \
    --text="Processed $PROCESSED of $TOTAL_FILES files" --percentage=0 --cancel-label="Stop" <&3 ) &
ZENITY_PID=$!

update_progress() {
    PERCENT=$(( (PROCESSED * 100) / TOTAL_FILES ))

    if (( PROCESSED > 0 )); then
        AVG_TIME=$(bc <<< "scale=2; $TOTAL_TIME / $PROCESSED")
        REMAINING_FILES=$(( TOTAL_FILES - PROCESSED ))
        ETA_SECONDS=$(bc <<< "$AVG_TIME * $REMAINING_FILES")
        ETA_SECONDS=$(printf "%.0f" "$ETA_SECONDS")  # Round to nearest int

        HOURS=$((ETA_SECONDS / 3600))
        MINUTES=$(((ETA_SECONDS % 3600) / 60))
        SECONDS=$((ETA_SECONDS % 60))

        if (( HOURS > 0 )); then
            ETA=$(printf "%d:%02d:%02d" "$HOURS" "$MINUTES" "$SECONDS")
        else
            ETA=$(printf "%02d:%02d" "$MINUTES" "$SECONDS")
        fi
    else
        ETA="Calculating..."
    fi

    NOTIFICATION_STRING="Processing $INPUT_VIDEO\n\nProcessed $PROCESSED of $TOTAL_FILES files (Remaining: $ETA)"
    echo "# $NOTIFICATION_STRING" >&3
    echo "$PERCENT" >&3
}

update_progress

for INPUT_VIDEO in "${MEDIA_FILES[@]}"; do
    START_TIME=$(date +%s)

    echo "Processing: $INPUT_VIDEO"

    update_progress

    echo "Making sure this isn't a raw 360 file."
    if [[ "$INPUT_VIDEO" == *"/360 X4/Raw/"* ]]; then
        echo "Skipping (Raw 360 File): $INPUT_VIDEO"
    else
        echo "Handling Audio Transcoding, if needed."
        if ! ffprobe -i "$INPUT_VIDEO" -show_streams -select_streams a -loglevel error | grep -q "audio"; then
            echo "File has no audio. Skipping audio transcoding."
        elif ffprobe -i "$INPUT_VIDEO" -show_streams -select_streams a -loglevel error | grep -q "pcm_s16le"; then
            echo "File already has WAV audio. Skipping audio transcoding."
        else
            echo "Converting audio of $INPUT_VIDEO to WAV"
            TEMP_FILE="${INPUT_VIDEO%.*}_temp.mp4"

            ffmpeg -y -i "$INPUT_VIDEO" -map 0:v -map 0:a -c:v copy -c:a pcm_s16le -metadata:s:a:0 language=eng "$TEMP_FILE"

            echo "Overwriting the original file."
            mv "$TEMP_FILE" "$INPUT_VIDEO"
        fi

        PROXY_DIR="$(dirname "$INPUT_VIDEO")/Proxy"
        mkdir -p "$PROXY_DIR"
        NEW_FILENAME="$(basename "${INPUT_VIDEO%.*}.mov")"

        echo "Generating Proxy, if it doesn't already exist."
        if [ -f "$PROXY_DIR/$NEW_FILENAME" ]; then
            echo "Proxy already exists for $INPUT_VIDEO, skipping."
        else
            echo "Creating Proxy Media for Footage: $INPUT_VIDEO"
            ffmpeg -y -i "$INPUT_VIDEO" -c:v dnxhd -profile:v dnxhr_sq -vf scale=-1:720 -c:a copy -map_metadata 0 -copytb 1 "$PROXY_DIR/$NEW_FILENAME"
        fi
    fi

    END_TIME=$(date +%s)
    TIME_TAKEN=$((END_TIME - START_TIME))
    TOTAL_TIME=$((TOTAL_TIME + TIME_TAKEN))

    ((PROCESSED++))
    echo "Finished with: $INPUT_VIDEO"

    echo "Checking if zenity progress window was closed"
    if ! kill -0 "$ZENITY_PID" 2>/dev/null; then
        echo "Process cancelled during file $INPUT_VIDEO. Exiting."
        exec 3>&-
        exit 0
    else
        echo "Zenity window still active, continuing"
    fi
done

echo "All files processed! 🎉"
echo "# All MP4 files have been processed! 🎉" >&3
echo "100" >&3
