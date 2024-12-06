pipeline {
    agent any

    environment {
        DATABASE_URL = 'sqlite3://db.sqlite3'
    }

    stages {
        stage('Clone Repository') {
            steps {
                sh '''
                echo "Cleaning workspace..."
                rm -rf *
                echo "Cloning repository..."
                git clone --branch master https://github.com/dcalixto/cry_paginator.git .
                echo "Workspace contents after cloning:"
                ls -la
                '''
            }
        }
        stage('Debug Workspace') {
            steps {
                sh '''
                    echo "Workspace contents:"
                    ls -la
                    echo "Current user:"
                    whoami
                    echo "Workspace permissions:"
                    stat $WORKSPACE
                '''
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                    docker run --rm -v "$WORKSPACE":/app -w /app crystallang/crystal /bin/sh -c "
                        ls -la
                        if [ -f shard.yml ]; then
                            echo 'shard.yml exists'
                            shards install
                        else
                            echo 'shard.yml missing'
                            exit 1
                        fi
                    "
                '''
            }
        }

        stage('Run Tests') {
            steps {
                sh 'docker run --rm -v "$WORKSPACE":/app -w /app crystallang/crystal crystal spec'
            }
        }

        stage('Lint Code') {
            steps {
                sh 'docker run --rm -v "$WORKSPACE":/app -w /app crystallang/crystal crystal tool format --check'
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: '**/log/*', allowEmptyArchive: true
        }
        failure {
            echo 'Build failed!'
        }
    }
}