// See help here:
// - https://www.jenkins.io/doc/book/pipeline/
// - https://www.jenkins.io/doc/book/pipeline/syntax/ 
// - https://www.jenkins.io/doc/pipeline/steps/
//
pipeline {
    agent any
    options {
        buildDiscarder(logRotator(numToKeepStr: '30'))
    }
    environment {
        CONFIG_KEY_STAGING = credentials('CONFIG_KEY_STAGING')
        CONFIG_KEY_PROD = credentials('CONFIG_KEY_PROD')

        CONFIG_FILE_STAGING = credentials('CONFIG_FILE_STAGING')
        CONFIG_FILE_PROD = credentials('CONFIG_FILE_PROD')
        
        ENCRYPTION_KEY = credentials('ENCRYPTION_KEY')
        
        CODECOV_TOKEN = credentials('CODECOV_TOKEN')
    }
    stages {
        stage('Unit Test') {
            when {
                allOf {
                    // Jenkins checks out PRs with a PR-XXX format
                    expression { BRANCH_NAME ==~ /^PR-.*/ }
                }
            }
            steps {
                ansiColor('xterm') {
                    // clean build dir
                    // (was useful when CoreData code generation didn't work properly for some reason)
                    sh "rm -rf Build"

                    sh 'rm -f Multisig/Cross-layer/Configuration/config.bundle/*.json'

                    sh 'cp -f \"${CONFIG_FILE_STAGING}\" \"Multisig/Cross-layer/Configuration/config.bundle/apis-staging.enc.json\"'
                    sh 'CONFIG_KEY_STAGING=\"${CONFIG_KEY_STAGING}\" bin/test.sh \"Multisig - Staging\"'
                    junit 'Build/reports/junit.xml'
                    archiveArtifacts 'Build/*/xcodebuild-test.log'
                    archiveArtifacts 'Build/*/tests-bundle.xcresult.tgz'
                }
            }
        }
        stage('Upload to TestFlight') {
            when {
                allOf {
                    expression { BRANCH_NAME ==~ /^(main|release\/.*)$/ }
                }
            }
            steps {
                ansiColor('xterm') {
                    // NOTE: on Xcode 11.5, the keychain is not accessible
                    // by the xcode, so the Jenkins's builds are failing when
                    // user is logged out.
                    // The https://stackoverflow.com/a/55699898 has a fix.
                    // After applying it, the first build has to be manually
                    // granted the access to the signing certificates via
                    // the machine's UI (remotely or directly), then
                    // the uploading to AppStoreConnect started to work.

                    sh 'rm -f Multisig/Cross-layer/Configuration/config.bundle/*.json'
                    sh 'cp -f \"${CONFIG_FILE_PROD}\" Multisig/Cross-layer/Configuration/config.bundle/apis-prod.enc.json'
                    sh 'CONFIG_KEY_PROD=\"${CONFIG_KEY_PROD}\" bin/archive.sh \"Multisig - Production\"'

                    sh 'rm -f Multisig/Cross-layer/Configuration/config.bundle/*.json'
                    sh 'cp -f \"${CONFIG_FILE_STAGING}\" Multisig/Cross-layer/Configuration/config.bundle/apis-staging.enc.json'
                    sh 'CONFIG_KEY_STAGING=\"${CONFIG_KEY_STAGING}\" bin/archive.sh \"Multisig - Staging\"'
                    archiveArtifacts 'Build/*/xcodebuild-*.log'
                }
            }
        }
    }
}
