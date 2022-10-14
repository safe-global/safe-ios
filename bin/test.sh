#! /usr/bin/env bash
set -e +o pipefail

XCODE_SCHEME=$1
OUTPUT_DIR="Build/$XCODE_SCHEME"

mkdir -p "$OUTPUT_DIR"

# needed for code coverage
TEST_BUNDLE_PATH="$OUTPUT_DIR/tests-bundle.xcresult"
rm -rf "$TEST_BUNDLE_PATH"

bin/configure.sh

############
# uncomment when you need to delete the app from the simulator
# DEVICE="iPhone 11 Pro"
# APP_ID="io.gnosis.multisig.staging.mainnet"
# set +e && xcrun simctl boot "${DEVICE}" 2>/dev/null
# xcrun simctl uninstall "${DEVICE}" "${APP_ID}"
# set -e
############

set -o pipefail && \
xcrun xcodebuild test \
    -project Multisig.xcodeproj \
    -scheme "$XCODE_SCHEME" \
    -destination "platform=iOS Simulator,name=iPhone 14 Pro" \
    -resultBundlePath "$TEST_BUNDLE_PATH" \
| tee "$OUTPUT_DIR/xcodebuild-test.log" | xcpretty -c -r junit

# print the total code  coverage
xcrun xccov view --report --only-targets "$TEST_BUNDLE_PATH"

# archive the test results
tar -czf "$TEST_BUNDLE_PATH".tgz "$TEST_BUNDLE_PATH"

# upload code coverage report
bash bin/codecov.sh -D Build
