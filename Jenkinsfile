pipeline {
    agent any
    stages {
        stage('Distribute') {
            steps {
                ansiColor('xterm') {
                    sh 'xcrun agvtool new-version -all $BUILD_NUMBER'
                    sh 'xcrun xcodebuild archive -workspace Multisig.xcworkspace -scheme "Multisig - Development Rinkeby" -destination "generic/platform=iOS" -archivePath Build/Multisig.xcarchive -allowProvisioningUpdates'
                    sh 'xcrun xcodebuild -exportArchive -archivePath Build/Multisig.xcarchive -exportPath Build -exportOptionsPlist Multisig/ExportOptions.plist -allowProvisioningUpdates'
                }
            }
        }
    }
}
