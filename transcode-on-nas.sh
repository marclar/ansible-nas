#!/bin/bash

# Remote transcoding script - runs transcode on NAS server
# Usage: ./transcode-on-nas.sh /path/to/filename.mkv
# This version SSHs to the NAS and runs the transcode there

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# NAS connection details
NAS_HOST="192.168.12.210"
NAS_USER="mk"

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Check if input file is provided
if [ $# -eq 0 ]; then
    print_status $RED "Error: No input file specified"
    print_status $YELLOW "Usage: $0 <file_path_on_nas>"
    print_status $YELLOW "Example: $0 /mnt/truenas-media/movies/movie.mkv"
    exit 1
fi

INPUT_FILE="$1"

print_status $BLUE "=== Remote Video Transcoding Script ==="
print_status $GREEN "NAS Server: $NAS_USER@$NAS_HOST"
print_status $GREEN "Input file: $INPUT_FILE"
echo ""

# Copy the transcoding script to NAS
print_status $BLUE "Setting up transcoding script on NAS..."
ssh $NAS_USER@$NAS_HOST << 'REMOTE_SCRIPT'
cat > /tmp/transcode-h264.sh << 'SCRIPT_CONTENT'
#!/bin/bash

# Check if input file is provided
if [ $# -eq 0 ]; then
    echo "Error: No input file specified"
    exit 1
fi

INPUT_FILE="$1"

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: File '$INPUT_FILE' not found"
    exit 1
fi

# Check if ffmpeg is available (try docker if not installed)
if ! command -v ffmpeg &> /dev/null; then
    # Try using ffmpeg from a docker container
    echo "ffmpeg not found locally, using Docker container..."
    FFMPEG_CMD="docker run --rm -v $(dirname "$INPUT_FILE"):$(dirname "$INPUT_FILE") linuxserver/ffmpeg"
else
    FFMPEG_CMD="ffmpeg"
fi

# Get directory and filename components
DIR=$(dirname "$INPUT_FILE")
BASENAME=$(basename "$INPUT_FILE")
FILENAME="${BASENAME%.*}"

# Output file
OUTPUT_FILE="${DIR}/${FILENAME}.h264.mkv"

# Check if output already exists
if [ -f "$OUTPUT_FILE" ]; then
    echo "Warning: Output file already exists: $OUTPUT_FILE"
    echo "Skipping to avoid overwrite"
    exit 1
fi

echo "Starting transcoding..."
echo "Input:  $INPUT_FILE"
echo "Output: $OUTPUT_FILE"
echo ""
echo "Settings:"
echo "  Video: H.264 (libx264)"
echo "  Preset: medium (balanced speed/quality)"
echo "  CRF: 20 (good quality, smaller file)"
echo "  Audio: Copy original"
echo ""
echo "This will take a while. Running with nice to avoid system overload..."

# Run with nice to lower priority and avoid overloading the system
nice -n 10 $FFMPEG_CMD -i "$INPUT_FILE" \
    -c:v libx264 \
    -preset medium \
    -crf 20 \
    -pix_fmt yuv420p \
    -movflags +faststart \
    -c:a copy \
    -c:s copy \
    -map 0 \
    -max_muxing_queue_size 9999 \
    -stats \
    -loglevel error \
    "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Transcoding completed!"
    echo "Output: $OUTPUT_FILE"
    ls -lh "$OUTPUT_FILE"
else
    echo "❌ Transcoding failed!"
    rm -f "$OUTPUT_FILE" 2>/dev/null
    exit 1
fi
SCRIPT_CONTENT

chmod +x /tmp/transcode-h264.sh
REMOTE_SCRIPT

# Run the transcoding on the NAS
print_status $YELLOW "Starting transcoding on NAS (this will take a while)..."
print_status $YELLOW "Note: Using 'nice' to avoid overloading the system"
echo ""

ssh $NAS_USER@$NAS_HOST "/tmp/transcode-h264.sh '$INPUT_FILE'"

if [ $? -eq 0 ]; then
    print_status $GREEN "✅ Transcoding completed successfully on NAS!"
    
    # Show the result
    OUTPUT_FILE="${INPUT_FILE%.*}.h264.mkv"
    print_status $BLUE "Output file: $OUTPUT_FILE"
    
    # Get file info
    ssh $NAS_USER@$NAS_HOST "ls -lh '$OUTPUT_FILE' 2>/dev/null"
else
    print_status $RED "❌ Transcoding failed"
fi

# Cleanup
ssh $NAS_USER@$NAS_HOST "rm -f /tmp/transcode-h264.sh"