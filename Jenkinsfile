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
                    branches: [[name: '*/main']], // Changed back to 'main' as it's the default branch
                    userRemoteConfigs: [[
                        url: 'https://github.com/dcalixto/cry_paginator.git'
                    ]]
                ])
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'curl -fsSL https://crystal-lang.org/install.sh | sudo bash' // Install Crystal if needed
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
            cleanWs() // Clean workspace after build
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
