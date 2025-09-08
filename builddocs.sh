#!/bin/bash

# Configuration
SCHEME="Curio-Docs"
OUTPUT_DIR="public"
TARGET_DOCC="Curio.doccarchive"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Build documentation
xcodebuild docbuild \
    -scheme "$SCHEME" \
    -destination "platform=macOS,arch=x86_64" \
    -derivedDataPath "$OUTPUT_DIR/.temp" \
    -quiet

# Find all .doccarchive directories
echo "Looking for documentation archives..."
find "$OUTPUT_DIR/.temp" -name "*.doccarchive" -type d | while read archive; do
    echo "Found: $(basename "$archive")"
    # If this is the one we want, copy it
    if [ "$(basename "$archive")" = "$TARGET_DOCC" ]; then
        echo "Found target documentation: $TARGET_DOCC"
        # Remove existing documentation if it exists
        rm -rf "$OUTPUT_DIR/$TARGET_DOCC"
        # Move the documentation
        mv "$archive" "$OUTPUT_DIR/"
        echo "Successfully moved documentation to $OUTPUT_DIR/$TARGET_DOCC"
    fi
done

# Verify the file was moved
if [ -d "$OUTPUT_DIR/$TARGET_DOCC" ]; then
    echo "Documentation generation successful"
else
    echo "Error: Failed to find or move $TARGET_DOCC"
    exit 1
fi

# Clean up temporary build directory
rm -rf "$OUTPUT_DIR/.temp"
