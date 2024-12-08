pipeline {
    agent any

    environment {
        DATABASE_URL = 'sqlite3://db.sqlite3'
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
                        apt-get update
                        apt-get install -y curl gnupg
                        curl -fsSL https://dist.crystal-lang.org/apt/setup.sh | bash
                        apt-get update
                        apt-get install -y crystal
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
