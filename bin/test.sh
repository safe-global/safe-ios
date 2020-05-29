#! /usr/bin/env bash

XCODE_SCHEME=$1
OUTPUT_DIR="Build/$XCODE_SCHEME"

mkdir -p "$OUTPUT_DIR"

bin/configure.sh

xcrun xcodebuild test \
    -workspace Multisig.xcworkspace \
    -scheme "$XCODE_SCHEME" \
    -destination "platform=iOS Simulator,name=iPhone 11 Pro" \
| tee "$OUTPUT_DIR/xcodebuild-test.log" | xcpretty -r junit && exit ${PIPESTATUS[0]}
