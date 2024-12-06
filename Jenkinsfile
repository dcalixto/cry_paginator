pipeline {
    agent {
        docker {
            image 'crystallang/crystal'
        }
    }

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

        stage('Static Analysis') {
            steps {
                sh 'ameba'
            }
        }
    }

    post {
        always {
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
