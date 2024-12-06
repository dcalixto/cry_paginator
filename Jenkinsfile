pipeline {
    agent any

    environment {
        DATABASE_URL = 'sqlite3://db.sqlite3'
    }

    stages {
        stage('Clone Repository') {
            steps {
                git url: 'https://github.com/dcalixto/cry_paginator.git',
                    branch: 'master'
            }
        }

        stage('Debug Workspace') {
            steps {
                sh 'pwd'
                sh 'ls -la'
                sh 'docker run --rm -v "$WORKSPACE":/app -w /app crystallang/crystal ls -la'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                    docker run --rm -v "$WORKSPACE":/app -w /app crystallang/crystal /bin/sh -c '
                        ls -la
                        test -f shard.yml && echo "shard.yml exists" || echo "shard.yml missing"
                        shards install
                    '
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