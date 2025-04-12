#!/bin/bash

echo Checking for Zenity
if ! command -v zenity &> /dev/null; then
    echo "ZENITY NOT FOUND - Install zenity to continue."
    notify-send "ZENITY NOT FOUND" "Install zenity to continue."
    exit
fi

CURRENT_STAGE=0
NUM_STAGES=0
STAGE="Discovering MP4 Files..."

# Default values
TARGET_DIR=""
DO_WAV=false
DO_PROXIES=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--directory)
            TARGET_DIR="$2"
            shift 2
            ;;
        -w|--wav)
            DO_WAV=true
            ((NUM_STAGES))
            shift
            ;;
        -p|--proxies)
            DO_PROXIES=true
            ((NUM_STAGES))
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Usage: $0 --directory <path> [--wav] [--proxies]"
            exit 1
            ;;
    esac
done

if [[ -z "$TARGET_DIR" ]]; then
    echo "Error: --directory <path> is required."
    echo "Usage: $0 --directory <path> [--wav] [--proxies]"
    exit 1
fi

echo Initializing Zenity
PIPE=$(mktemp -u)
mkfifo "$PIPE"
exec 3<> "$PIPE"
rm "$PIPE"

( zenity --progress --title="MediaHandler | Processing Media" --text="$TARGET_DIR\n\nStage $CURRENT_STAGE of $NUM_STAGES: $STAGE" --percentage=0 --cancel-label="Stop" --width=800 <&3 ) &
ZENITY_PID=$!

echo "Finding all mp4 files in $TARGET_DIR."
mapfile -d '' MEDIA_FILES < <(find "$TARGET_DIR" -type f -iname "*.mp4" -print0)

# TODO: FIX THIS | SEE README
echo "WARNING: Remaining Time is based on the average time taken for each video file and therefore won't be terribly accurate unless videos are a consistent length and format."

reset_progress() {
    TOTAL_FILES=${#MEDIA_FILES[@]}
    PROCESSED=0
    TOTAL_TIME=0
}

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

    NOTIFICATION_STRING="$CURRENT_DIR\n\nStage $STAGE of $NUM_STAGES: $STAGE\n\nProcessing $INPUT_VIDEO\n\nProcessed $PROCESSED of $TOTAL_FILES files (Remaining: $ETA)"
    echo "# $NOTIFICATION_STRING" >&3
    echo "$PERCENT" >&3
}

transcode_to_wav() {
    for INPUT_VIDEO in "${MEDIA_FILES[@]}"; do
        START_TIME=$(date +%s)

        echo
        echo "Transcoding Audio for: $INPUT_VIDEO"

        update_progress

        PREPROCESSED="true"
        if ! ffprobe -i "$INPUT_VIDEO" -show_streams -select_streams a -loglevel error | grep -q "audio"; then
            echo "File has no audio. Skipping audio transcoding."
        elif ffprobe -i "$INPUT_VIDEO" -show_streams -select_streams a -loglevel error | grep -q "pcm_s16le"; then
            echo "File already has WAV audio. Skipping audio transcoding."
        else
            echo "Converting audio to WAV"
            TEMP_FILE="${INPUT_VIDEO%.*}_temp.mp4"

            ffmpeg -v quiet -stats -y -i "$INPUT_VIDEO" -map 0:v -map 0:a -c:v copy -c:a pcm_s16le -metadata:s:a:0 language=eng "$TEMP_FILE"

            echo "Overwriting the original file."
            mv "$TEMP_FILE" "$INPUT_VIDEO"

            PREPROCESSED="false"
            echo "Audio transcoded."
        fi

        if [[ "$PREPROCESSED" == "true" ]]; then
            ((TOTAL_FILES--))
        else
            END_TIME=$(date +%s)
            TIME_TAKEN=$((END_TIME - START_TIME))
            TOTAL_TIME=$((TOTAL_TIME + TIME_TAKEN))

            ((PROCESSED++))
        fi

        if ! kill -0 "$ZENITY_PID" 2>/dev/null; then
            echo "Process cancelled during audio transcoding of file $INPUT_VIDEO. Exiting."
            exec 3>&-
            exit 0
        fi
    done
}

generate_proxies() {
    for INPUT_VIDEO in "${MEDIA_FILES[@]}"; do
        START_TIME=$(date +%s)

        echo
        echo "Generating Proxy for: $INPUT_VIDEO"

        update_progress

        PREPROCESSED="true"

        PROXY_DIR="$(dirname "$INPUT_VIDEO")/Proxy"
        mkdir -p "$PROXY_DIR"
        NEW_FILENAME="$(basename "${INPUT_VIDEO%.*}.mov")"

        if [ -f "$PROXY_DIR/$NEW_FILENAME" ]; then
            echo "Proxy already exists, skipping generation."
        else
            echo "Creating Proxy Media"
            RESOLUTION="720"
            if [[ "$INPUT_VIDEO" == *"/360 X4/"* ]]; then
                RESOLUTION="1080"
            fi
            ffmpeg -v quiet -stats -y -i "$INPUT_VIDEO" -c:v dnxhd -profile:v dnxhr_lb -vf scale=-1:"$RESOLUTION" -c:a copy -map_metadata 0 -copytb 1 "$PROXY_DIR/$NEW_FILENAME"
            PREPROCESSED="false"
            echo "Proxy Generated."
        fi

        if [[ "$PREPROCESSED" == "true" ]]; then
            ((TOTAL_FILES--))
        else
            END_TIME=$(date +%s)
            TIME_TAKEN=$((END_TIME - START_TIME))
            TOTAL_TIME=$((TOTAL_TIME + TIME_TAKEN))

            ((PROCESSED++))
        fi

        if ! kill -0 "$ZENITY_PID" 2>/dev/null; then
            echo "Process cancelled during proxy generation for file $INPUT_VIDEO. Exiting."
            exec 3>&-
            exit 0
        fi
    done
}

reset_progress

STAGE="Transcoding AAC Audio to WAV"
((CURRENT_STAGE++))

if [[ "$DO_WAV" == true ]]; then
    transcode_to_wav
fi

STAGE="Generating Proxies"
((CURRENT_STAGE++))

if [[ "$DO_PROXIES" == true ]]; then
    generate_proxies
fi

echo "All files processed! 🎉"
echo "# All MP4 files have been processed! 🎉" >&3
echo "100" >&3
