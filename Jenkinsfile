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
                    sh 'bin/archive.sh "Multisig - Development Rinkeby"'
                    archiveArtifacts 'Build/Multisig - Development Rinkeby/xcodebuild-archive.log'
                    
                    sh 'bin/archive.sh "Multisig - Development Mainnet"'
                    archiveArtifacts 'Build/Multisig - Development Mainnet/xcodebuild-export.log'
                }
            }
        }
    }
}
