pipeline {
    agent any
    environment {
        FASTLANE_USER = credentials('FASTLANE_USER')
        FASTLANE_PASSWORD = credentials('FASTLANE_PASSWORD')
        FASTLANE_ITC_TEAM_ID = credentials('FASTLANE_ITC_TEAM_ID')
        FASTLANE_TEAM_ID = credentials('FASTLANE_TEAM_ID')
    }
    stages {
        stage('Deploy') {
            steps {
                ansiColor('xterm') {
                    sh 'echo $PATH'
                    sh 'which ruby'
                    sh 'ruby -v'
                    sh 'bundle install --jobs=3 --retry=3'
                    sh 'bundle exec fastlane development_rinkeby_beta'
                }
            }
        }
    }
}
