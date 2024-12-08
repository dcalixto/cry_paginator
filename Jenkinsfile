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
                    branches: [[name: '*/master']], // Changed from 'main' to 'master'
                    userRemoteConfigs: [[
                        url: 'https://github.com/dcalixto/cry_paginator.git'
                    ]]
                ])
            }
        }
       stage('Check Dependencies') {
           steps {
               sh 'ldd /usr/bin/shards'
           }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                    apt-get update
                    apt-get install -y crystal shards  
                    bash -c "/usr/bin/shards install"
                '''
           
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
