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
                    branches: [[name: '*/master']], // Ensure the branch is correct
                    userRemoteConfigs: [[
                        url: 'https://github.com/dcalixto/cry_paginator.git'
                    ]]
                ])
            }
        }
        
        stage('Check Dependencies') {
         steps {
             script {
                   def shardsPath = sh(script: "which shards || true", returnStdout: true).trim()
                    if (!shardsPath) {
                          sh '''
                            apt-get update
                            apt-get install -y curl gnupg
                            curl -fsSL https://dist.crystal-lang.org/apt/setup.sh | bash
                           apt-get install -y shards
                         '''
                    } else {
                           echo "Shards already installed at ${shardsPath}"
                    }
                          sh 'ldd $(which shards)'
           }
       }
  


        stage('Install Dependencies') {
            steps {
                sh '''
                    apt-get update
                    apt-get install -y crystal shards
                    shards install
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
