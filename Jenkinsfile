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
                    def shardsPath = sh(script: "which shards || true", returnStdout: true).trim()
                    if (!shardsPath) {
                        try {
                            sh '''
                                apt-get update
                                apt-get install -y curl gnupg
                                curl -fsSL https://dist.crystal-lang.org/apt/setup.sh | bash
                                apt-get update
                                apt-get install -y shards
                            '''
                        } catch (Exception e) {
                            echo "Failed to install shards via package manager, falling back to manual installation."
                            sh '''
                                wget https://github.com/crystal-lang/shards/releases/latest/download/shards-linux-x86_64
                                mv shards-linux-x86_64 /usr/local/bin/shards
                                chmod +x /usr/local/bin/shards
                            '''
                        }
                    } else {
                        echo "Shards already installed at ${shardsPath}"
                    }
                    sh 'ldd $(which shards)'
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                    apt-get update
                    apt-get install -y crystal shards || true
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
