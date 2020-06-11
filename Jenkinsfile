pipeline {
    agent any
    environment {
        // this enables ruby gem binaries, such as xcpretty
        PATH = "$HOME/.rbenv/bin:$HOME/.rbenv/shims:/usr/local/bin:/usr/local/sbin:$PATH"
        INFURA_KEY = credentials('INFURA_KEY')
        ENCRYPTION_KEY = credentials('ENCRYPTION_KEY')
    }
    stages {
        stage('Unit Test') {
            when {
                // Jenkins checks out PRs with a PR-XXX format
                expression { BRANCH_NAME ==~ /^PR-.*/ }
            }
            matrix {
                axes {
                    axis {
                        name "NETWORK"
                        values "Rinkeby", "Mainnet"
                    }
                    axis {
                        name "ENVIRONMENT"
                        values "Staging"
                    }
                }
                stages {
                    stage('Test') {
                        steps {
                            ansiColor('xterm') {
                                sh 'bin/test.sh "Multisig - Staging Rinkeby"'
                                junit 'Build/reports/junit.xml'
                                archiveArtifacts 'Build/*/xcodebuild-test.log'
                                archiveArtifacts 'Build/*/tests-bundle.xcresult.tgz'
                            }
                        }
                    }
                }
            }
        }
        stage('Upload to TestFlight') {
            when {
                expression { BRANCH_NAME ==~ /^master$/ }
            }
            matrix {
                axes {
                    axis {
                        name "NETWORK"
                        values "Rinkeby", "Mainnet"
                    }
                    axis {
                        name "ENVIRONMENT"
                        values "Staging"
                    }
                }
                stages {
                    stage('Archive') {
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
                                sh 'bin/archive.sh "Multisig - ${ENVIRONMENT} ${NETWORK}"'
                                archiveArtifacts 'Build/*/xcodebuild-*.log'
                            }
                        }
                    }
                }
            }
        }
    }
}
