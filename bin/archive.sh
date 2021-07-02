#! /usr/bin/env bash
set -e +o pipefail

XCODE_SCHEME=$1
OUTPUT_DIR="Build/$XCODE_SCHEME"
ARCHIVE_PATH="$OUTPUT_DIR/Multisig.xcarchive"

mkdir -p "$OUTPUT_DIR"

bin/configure.sh

xcrun agvtool new-version -all $BUILD_NUMBER

set -o pipefail && \
xcrun xcodebuild archive \
    -project Multisig.xcodeproj \
    -scheme "$XCODE_SCHEME" \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates \
| tee "$OUTPUT_DIR/xcodebuild-archive.log" | xcpretty -c

set -o pipefail && \
xcrun xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath Build \
    -exportOptionsPlist Multisig/ExportOptions.plist \
    -allowProvisioningUpdates \
| tee "$OUTPUT_DIR/xcodebuild-export.log" | xcpretty -c
