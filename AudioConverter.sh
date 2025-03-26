#!/bin/bash

mapfile -d '' MEDIA_FILES < <(find .. -type f \( -iname "*.mp4" -o -iname "*.lrv" \) -print0)
TOTAL_FILES=${#MEDIA_FILES[@]}
PROCESSED=0
TOTAL_TIME=0

echo Checking for Zenity
if ! command -v zenity &> /dev/null; then
    notify-send "ZENITY NOT FOUND" "Install zenity to continue."
    exit
fi

echo "INFO: Remaining Time is based on the average time taken for each video file and therefore won't be terribly accurate unless videos are a consistent length and format."

echo Initializing Zenity
PIPE=$(mktemp -u)
mkfifo "$PIPE"
exec 3<> "$PIPE"
rm "$PIPE"

( zenity --progress --title="MP4 & LRV WAV Audio Track Adder" \
    --text="Processed $PROCESSED of $TOTAL_FILES files" --percentage=0 --cancel-label="Stop" <&3 ) &
ZENITY_PID=$!

update_progress() {
    PERCENT=$(( (PROCESSED * 100) / TOTAL_FILES ))

    if (( PROCESSED > 0 )); then
        AVG_TIME=$(bc <<< "scale=2; $TOTAL_TIME / $PROCESSED")
        REMAINING_FILES=$(( TOTAL_FILES - PROCESSED ))
        ETA_SECONDS=$(bc <<< "scale=0; $AVG_TIME * $REMAINING_FILES")
        ETA=$(date -ud "@$ETA_SECONDS" +'%M:%S')
    else
        ETA="Calculating..."
    fi

    NOTIFICATION_STRING="Processing $INPUT_VIDEO\nProcessed $PROCESSED of $TOTAL_FILES files (Remaining: $ETA)"
    echo "$NOTIFICATION_STRING"
    echo "# $NOTIFICATION_STRING" >&3
    echo "$PERCENT" >&3
}

# TODO: Make more universal:
# TODO: Instead of skipping the "/360 X4/Raw" directory, make it check for a insv file that matches the lrv file, and skip it if that's found.
    # I edit 360 footage in Resolve via KartaVR, not in Insta360 Studio, so I don't want the raw 360 videos to be modified.
# TODO: Instead of generating proxies for media with no audio and media in the 360 X4 folder (drone and stitched 360 footage in my case), do a search for a matching LRV file, then generate a proxy if not found.
for INPUT_VIDEO in "${MEDIA_FILES[@]}"; do
    echo "Processing: $INPUT_VIDEO"

    echo Checking if this is a raw 360 file
    if [[ "$INPUT_VIDEO" == *"/360 X4/Raw/"* ]]; then
        echo "Skipping (Raw 360 File): $INPUT_VIDEO"
        ((PROCESSED++))
        update_progress
        continue
    fi

    echo "Checking if the video already has audio in the correct format."
    if ffprobe -i "$INPUT_VIDEO" -show_streams -select_streams a -loglevel error | grep -q "pcm_s16le"; then
        echo "Skipping (WAV track already exists): $INPUT_VIDEO"
        ((PROCESSED++))
        update_progress
        continue
    fi

    echo Checking if the video has no audio
    if ! ffprobe -i "$INPUT_VIDEO" -show_streams -select_streams a -loglevel error | grep -q "audio"; then
        echo "Creating Proxy Media for Footage with no Audio: $INPUT_VIDEO"
        PROXY_DIR="$(dirname "$INPUT_VIDEO")/Proxies"
        mkdir -p "$PROXY_DIR"
        NEW_FILENAME="$(basename "${INPUT_VIDEO%.*}.mov")"
        if [ -f "$PROXY_DIR/$NEW_FILENAME" ]; then
            echo "Proxy already exists for $INPUT_VIDEO, skipping."
            ((PROCESSED++))
            update_progress
            continue
        fi

        START_TIME=$(date +%s)

        ffmpeg -y -i "$INPUT_VIDEO" -c:v dnxhr -profile:v dnxhr_sq -vf scale=-1:720,format=yuv422p -an "$PROXY_DIR/$NEW_FILENAME"

        END_TIME=$(date +%s)
        TIME_TAKEN=$((END_TIME - START_TIME))
        TOTAL_TIME=$((TOTAL_TIME + TIME_TAKEN))
        ((PROCESSED++))
        update_progress

        if ! kill -0 "$ZENITY_PID" 2>/dev/null; then
            echo "Process cancelled during file $INPUT_VIDEO. Exiting..."
            exec 3>&-
            exit 0
        fi
        continue
    fi

    echo Checking if this is an LRV file
    if [[ "$INPUT_VIDEO" == *.lrv ]]; then
        echo Handling LRV file
        PROXY_DIR="$(dirname "$INPUT_VIDEO")/Proxies"
        echo "Creating Proxy Directory if it Doesn't Exist: $PROXY_DIR"
        mkdir -p "$PROXY_DIR"
        NEW_FILENAME="$(basename "${INPUT_VIDEO%.*}.mov" | sed 's/LRV/VID/')"
        echo "Moving Proxy Media $INPUT_VIDEO to $PROXY_DIR/$NEW_FILENAME"
        mv "$INPUT_VIDEO" "$PROXY_DIR/$NEW_FILENAME"

        ((PROCESSED++))
        update_progress

        if ! kill -0 "$ZENITY_PID" 2>/dev/null; then
            echo "Process cancelled during file $INPUT_VIDEO. Exiting..."
            exec 3>&-
            exit 0
        fi
        continue
    fi
    TEMP_FILE="${INPUT_VIDEO%.*}_temp.mp4"
    START_TIME=$(date +%s)

    ffmpeg -y -i "$INPUT_VIDEO" -map 0:v -map 0:a -c:v copy -c:a pcm_s16le -metadata:s:a:0 language=eng "$TEMP_FILE"

    echo replacing the original file
    mv "$TEMP_FILE" "$INPUT_VIDEO"

    if [[ "$INPUT_VIDEO" == *"/360/"* ]]; then
        echo "Creating Proxy for 360 Video"
        PROXY_DIR="$(dirname "$INPUT_VIDEO")/Proxies"
        mkdir -p "$PROXY_DIR"
        NEW_FILENAME="$(basename "${INPUT_VIDEO%.*}.mov")"
        ffmpeg -y -i "$INPUT_VIDEO" -c:v dnxhr -profile:v dnxhr_sq -vf scale=-1:720,format=yuv422p -an "$PROXY_DIR/$NEW_FILENAME"
    fi

    END_TIME=$(date +%s)
    TIME_TAKEN=$((END_TIME - START_TIME))
    TOTAL_TIME=$((TOTAL_TIME + TIME_TAKEN))

    ((PROCESSED++))
    update_progress
    echo "Finished processing: $INPUT_VIDEO"

    if ! kill -0 "$ZENITY_PID" 2>/dev/null; then
        echo "Process cancelled during file $INPUT_VIDEO. Exiting..."
        exec 3>&-
        exit 0
    fi
done

echo "All files processed! 🎉"
echo "# All MP4 files have been processed! 🎉" >&3
echo "100" >&3
