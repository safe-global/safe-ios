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
    triggers {
        cron('@midnight')
    }
    environment {
        // this enables ruby gem binaries, such as xcpretty
        PATH = "$HOME/.rbenv/bin:$HOME/.rbenv/shims:/usr/local/bin:/usr/local/sbin:$PATH"
        // to enable utf-8 in logs output
        LC_CTYPE = "en_US.UTF-8"
        INFURA_STAGING_KEY = credentials('INFURA_STAGING_KEY')
        INFURA_PROD_KEY = credentials('INFURA_PROD_KEY')
        INTERCOM_STAGING_API_KEY = credentials('INTERCOM_STAGING_API_KEY')
        INTERCOM_PROD_API_KEY = credentials('INTERCOM_PROD_API_KEY')
        INTERCOM_STAGING_APP_ID = credentials('INTERCOM_STAGING_APP_ID')
        INTERCOM_PROD_APP_ID = credentials('INTERCOM_PROD_APP_ID')
        ENCRYPTION_KEY = credentials('ENCRYPTION_KEY')
        CODECOV_TOKEN = credentials('CODECOV_TOKEN')
        WALLETCONNECT_PROJECT_ID_STAGING = credentials('WALLETCONNECT_PROJECT_ID_STAGING')
        WALLETCONNECT_PROJECT_ID_PROD = credentials('WALLETCONNECT_PROJECT_ID_PROD')
	WEB3AUTH_GOOGLE_CLIENT_ID = credentials('WEB3AUTH_GOOGLE_CLIENT_ID')
	WEB3AUTH_GOOGLE_VERIFIER = credentials('WEB3AUTH_GOOGLE_VERIFIER')
	WEB3AUTH_REDIRECT_SCHEME = credentials('WEB3AUTH_REDIRECT_SCHEME')
    }
    parameters {
        string(name: 'SSL_ENFORCE_PINNING', defaultValue: '1', description: 'Enforce SSL Pinning? (0 = NO/1 = YES)')
    }
    stages {
        stage('Unit Test') {
            when {
                allOf {
                    // Jenkins checks out PRs with a PR-XXX format
                    expression { BRANCH_NAME ==~ /^PR-.*/ }
                    not {
                        triggeredBy 'TimerTrigger'
                    }
                }
            }
            steps {
                ansiColor('xterm') {
                    // clean build dir
                    // (was useful when CoreData code generation didn't work properly for some reason)
                    sh "rm -rf Build"

                    // new param for uikit enabled - alternative
                    sh 'INFURA_KEY=\"${INFURA_STAGING_KEY}\" SSL_ENFORCE_PINNING=\"${SSL_ENFORCE_PINNING}\" bin/test.sh \"Multisig - Staging\"'
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
                    not {
                        triggeredBy 'TimerTrigger'
                    }
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

                    // new param for uikit enabled
                    sh 'INFURA_KEY=\"${INFURA_PROD_KEY}\" SSL_ENFORCE_PINNING=\"${SSL_ENFORCE_PINNING}\" WALLETCONNECT_PROJECT_ID=\"${WALLETCONNECT_PROJECT_ID_PROD}\" WEB3AUTH_GOOGLE_CLIENT_ID=\"${WEB3AUTH_GOOGLE_CLIENT_ID}\" WEB3AUTH_GOOGLE_VERIFIER=\"${WEB3AUTH_GOOGLE_VERIFIER}\" INTERCOM_APP_ID=\"${INTERCOM_PROD_APP_ID}\" INTERCOM_API_KEY=\"${INTERCOM_PROD_API_KEY}\" bin/archive.sh \"Multisig - Production\"'
                    sh 'INFURA_KEY=\"${INFURA_STAGING_KEY}\" SSL_ENFORCE_PINNING=\"${SSL_ENFORCE_PINNING}\" WALLETCONNECT_PROJECT_ID=\"${WALLETCONNECT_PROJECT_ID_STAGING}\" WEB3AUTH_GOOGLE_CLIENT_ID=\"${WEB3AUTH_GOOGLE_CLIENT_ID}\" WEB3AUTH_GOOGLE_VERIFIER=\"{WEB3AUTH_GOOGLE_VERIFIER}\" INTERCOM_APP_ID=\"${INTERCOM_STAGING_APP_ID}\" INTERCOM_API_KEY=\"${INTERCOM_STAGING_API_KEY}\" bin/archive.sh \"Multisig - Staging\"'
                    archiveArtifacts 'Build/*/xcodebuild-*.log'
                }
            }
        }
        stage('All Tests') {
            when {
                allOf {
                    expression { BRANCH_NAME ==~ /^(main)$/ }
                    triggeredBy 'TimerTrigger'
                }
            }
            steps {
                ansiColor('xterm') {
                    // clean build dir
                    // (was useful when CoreData code generation didn't work properly for some reason)
                    sh "rm -rf Build"

                    // new param for uikit enabled - alternative
                    sh 'INFURA_KEY=\"${INFURA_STAGING_KEY}\" SSL_ENFORCE_PINNING=\"${SSL_ENFORCE_PINNING}\" bin/test.sh \"All Tests\"'
                    junit 'Build/reports/junit.xml'
                    archiveArtifacts 'Build/*/xcodebuild-test.log'
                    archiveArtifacts 'Build/*/tests-bundle.xcresult.tgz'
                }
            }
        }
    }
}
