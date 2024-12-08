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

        stage('Install Dependencies') {
           steps {
                sh '''
                  apt-get update
                  apt-get install -y crystal git libyaml-dev libssl-dev libgmp-dev
                  git clone https://github.com/crystal-lang/shards.git
                  cd shards
                  make CRYSTAL=/usr/bin/crystal
                  make install
            '''
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
