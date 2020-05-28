pipeline {
    agent any
    environment {
        FASTLANE_USER = credentials('FASTLANE_USER')
        FASTLANE_PASSWORD = credentials('FASTLANE_PASSWORD')
        FASTLANE_ITC_TEAM_ID = credentials('FASTLANE_ITC_TEAM_ID')
        FASTLANE_TEAM_ID = credentials('FASTLANE_TEAM_ID')
        LC_ALL = "en_US.UTF-8"
        LANG = "en_US.UTF-8"
        CLICOLOR = "1"
        JAVA_HOME = "/usr/libexec/java_home"
        PATH = "$HOME/.rbenv/bin:$HOME/.rbenv/shims:/usr/local/bin:$PATH"
    }
    stages {
        stage('Deploy') {
            steps {
                ansiColor('xterm') {
                    sh 'echo "PATH=$PATH"'
                    sh 'rbenv versions'
                    sh 'rbenv which ruby'
                    sh 'ruby -v'
                    sh 'rbenv which bundle'
                    sh 'bundle install --jobs=3 --retry=3'
                    sh 'bundle exec fastlane development_rinkeby_beta'
                }
            }
        }
    }
}
