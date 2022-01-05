# enter your apple id, password, and phone number for logging in to the Dev Portal
export DOWNLOAD_DSYMS_USERNAME="<YOUR APPLE ID>"
export SPACESHIP_2FA_SMS_DEFAULT_PHONE_NUMBER="<YOUR 2FA PHONE>"

export DOWNLOAD_DSYMS_TEAM_ID="<TEAM ID>"
export DOWNLOAD_DSYMS_TEAM_NAME="<TEAM NAME>"

export FASTLANE_ITC_TEAM_ID=<ITC TEAM ID>
export FASTLANE_ITC_TEAM_NAME="<TEAM NAME>"

# change the app version 
export DOWNLOAD_DSYMS_VERSION=$1
# change the build number
export DOWNLOAD_DSYMS_BUILD_NUMBER=$2

export FL_UPLOAD_SYMBOLS_TO_CRASHLYTICS_BINARY_PATH="bin/upload-symbols"

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

export DOWNLOAD_DSYMS_APP_IDENTIFIER="io.gnosis.multisig.prod.mainnet"
export GOOGLE_SERVICES_INFO_PLIST_PATH="Multisig/Cross-layer/Analytics/Firebase/GoogleService-Info.Production.plist"

set -ex 

fastlane refresh_dsyms --verbose

export DOWNLOAD_DSYMS_APP_IDENTIFIER="io.gnosis.multisig.staging.mainnet"
export GOOGLE_SERVICES_INFO_PLIST_PATH="Multisig/Cross-layer/Analytics/Firebase/GoogleService-Info.Staging.plist"

fastlane refresh_dsyms --verbose
