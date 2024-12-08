pipeline {
    agent any

  environment {
    DATABASE_URL = 'sqlite3://db.sqlite3'
    PATH = "/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:${env.PATH}"
    CRYSTAL_PATH = "/usr/share/crystal"
}


    stages {
        stage('Clone Repository') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/master']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/dcalixto/cry_paginator.git'
                    ]]
                ])
            }
        }

 stage('Check Dependencies') {
    steps {
        script {
            sh '''
                sudo apt-get update
                sudo apt-get install -y curl gnupg apt-transport-https
                curl -fsSL https://crystal-lang.org/install.sh | sudo bash
                sudo apt-get update
                sudo apt-get install -y crystal shards
            '''
        }
    }
}


        stage('Install Dependencies') {
            steps {
                sh 'shards install'
            }
        }

        stage('Run Tests') {
            steps {
                sh 'crystal spec'
            }
        }

        stage('Lint Code') {
            steps {
                sh 'crystal tool format --check'
            }
        }
    }

    post {
        always {
            cleanWs()
            archiveArtifacts artifacts: '**/log/*', allowEmptyArchive: true
        }
        success {
            echo 'Build succeeded!'
        }
        failure {
            echo 'Build failed!'
        }
    }
}
