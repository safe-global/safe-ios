pipeline {
    agent any
    environment {
        // this enables ruby gem binaries, such as xcpretty
        PATH = "$HOME/.rbenv/bin:$HOME/.rbenv/shims:/usr/local/bin:/usr/local/sbin:$PATH"
    }
    stages {
        stage('Unit Test') {
            when {
                // Jenkins checks out PRs with a PR-XXX format
                expression { BRANCH_NAME ==~ /^(gh|PR)-.*/ }
            }
            steps {
                ansiColor('xterm') {
                    sh 'bin/test.sh "Multisig - Development Rinkeby"'
                    junit 'Build/reports/junit.xml'
                    archiveArtifacts 'Build/Multisig - Development Rinkeby/xcodebuild-test.log'
                    archiveArtifacts 'Build/Multisig - Development Rinkeby/tests-bundle.xcresult.tgz'
                }
            }
        }
        stage('Archive') {
            when {
                expression { BRANCH_NAME ==~ /^master$/ }
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
                    // the uploadgin to AppStoreConnect started to work.

                    sh 'bin/archive.sh "Multisig - Development Rinkeby"'
                    archiveArtifacts 'Build/Multisig - Development Rinkeby/xcodebuild-archive.log'
                    
                    sh 'bin/archive.sh "Multisig - Development Mainnet"'
                    archiveArtifacts 'Build/Multisig - Development Mainnet/xcodebuild-export.log'
                }
            }
        }
    }
}
