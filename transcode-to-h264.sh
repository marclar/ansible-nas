#!/bin/bash

# Transcode video file to H.264 for Plex compatibility
# Usage: ./transcode-to-h264.sh filename.mkv
# Output: filename.h264.mkv in the same directory

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    print_status $RED "Error: ffmpeg is not installed"
    print_status $YELLOW "Install with: brew install ffmpeg (Mac) or apt install ffmpeg (Linux)"
    exit 1
fi

# Check if input file is provided
if [ $# -eq 0 ]; then
    print_status $RED "Error: No input file specified"
    print_status $YELLOW "Usage: $0 <input_file>"
    print_status $YELLOW "Example: $0 movie.mkv"
    exit 1
fi

# Input file
INPUT_FILE="$1"

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    print_status $RED "Error: File '$INPUT_FILE' not found"
    exit 1
fi

# Get directory and filename components
DIR=$(dirname "$INPUT_FILE")
BASENAME=$(basename "$INPUT_FILE")
FILENAME="${BASENAME%.*}"
EXTENSION="${BASENAME##*.}"

# Output file
OUTPUT_FILE="${DIR}/${FILENAME}.h264.mkv"

# Check if output file already exists
if [ -f "$OUTPUT_FILE" ]; then
    print_status $YELLOW "Warning: Output file '$OUTPUT_FILE' already exists"
    read -p "Overwrite? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status $RED "Aborted"
        exit 1
    fi
fi

print_status $BLUE "=== Video Transcoding Script ==="
print_status $GREEN "Input:  $INPUT_FILE"
print_status $GREEN "Output: $OUTPUT_FILE"
echo ""

# Get input file info
print_status $BLUE "Analyzing input file..."
DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$INPUT_FILE" 2>/dev/null)
VIDEO_CODEC=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$INPUT_FILE" 2>/dev/null)
AUDIO_CODEC=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$INPUT_FILE" 2>/dev/null)
RESOLUTION=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$INPUT_FILE" 2>/dev/null)

print_status $YELLOW "File info:"
echo "  Duration: $(printf '%02d:%02d:%02d' $(echo "$DURATION/3600" | bc) $(echo "$DURATION%3600/60" | bc) $(echo "$DURATION%60" | bc) 2>/dev/null || echo "$DURATION seconds")"
echo "  Video codec: $VIDEO_CODEC"
echo "  Audio codec: $AUDIO_CODEC"
echo "  Resolution: $RESOLUTION"
echo ""

# Check if already H.264
if [ "$VIDEO_CODEC" = "h264" ]; then
    print_status $YELLOW "Warning: Video is already H.264 encoded"
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status $RED "Aborted"
        exit 1
    fi
fi

# Transcoding settings
print_status $BLUE "Transcoding settings:"
echo "  Video: H.264 (libx264)"
echo "  Preset: slow (better quality)"
echo "  CRF: 18 (visually lossless)"
echo "  Audio: Copy (no re-encoding)"
echo "  Subtitles: Copy all"
echo ""

# Start transcoding
print_status $GREEN "Starting transcoding..."
print_status $YELLOW "This may take a while depending on file size and CPU speed..."
echo ""

# FFmpeg command with progress
ffmpeg -i "$INPUT_FILE" \
    -c:v libx264 \
    -preset slow \
    -crf 18 \
    -pix_fmt yuv420p \
    -movflags +faststart \
    -c:a copy \
    -c:s copy \
    -map 0 \
    -max_muxing_queue_size 9999 \
    -stats \
    -loglevel error \
    "$OUTPUT_FILE"

# Check if transcoding was successful
if [ $? -eq 0 ]; then
    # Get output file size
    OUTPUT_SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
    INPUT_SIZE=$(ls -lh "$INPUT_FILE" | awk '{print $5}')
    
    print_status $GREEN ""
    print_status $GREEN "✅ Transcoding completed successfully!"
    print_status $BLUE "File sizes:"
    echo "  Input:  $INPUT_SIZE"
    echo "  Output: $OUTPUT_SIZE"
    print_status $GREEN "Output file: $OUTPUT_FILE"
    echo ""
    print_status $YELLOW "Note: The new file should play without transcoding on most Plex clients"
else
    print_status $RED "❌ Transcoding failed!"
    print_status $YELLOW "Check the error messages above for details"
    # Remove incomplete output file
    rm -f "$OUTPUT_FILE" 2>/dev/null
    exit 1
fi