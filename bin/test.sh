#! /usr/bin/env bash

XCODE_SCHEME=$1
OUTPUT_DIR="Build/$XCODE_SCHEME"

mkdir -p "$OUTPUT_DIR"

# needed for code coverage
TEST_BUNDLE_PATH="$OUTPUT_DIR/tests-bundle.xcresult"
rm -rf "$TEST_BUNDLE_PATH"

bin/configure.sh

set -o pipefail && \
xcrun xcodebuild test \
    -project Multisig.xcodeproj \
    -scheme "$XCODE_SCHEME" \
    -destination "platform=iOS Simulator,name=iPhone 11 Pro" \
    -resultBundlePath "$TEST_BUNDLE_PATH" \
| tee "$OUTPUT_DIR/xcodebuild-test.log" | xcpretty -c -r junit

# print the total code  coverage
xcrun xccov view --report --only-targets "$TEST_BUNDLE_PATH"

# archive the test results
tar -czf "$TEST_BUNDLE_PATH".tgz "$TEST_BUNDLE_PATH"

# upload code coverage report
bash <(curl -s https://codecov.io/bash) -D Build
