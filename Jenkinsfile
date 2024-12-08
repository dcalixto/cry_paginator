pipeline {
    agent any
    
    environment {
        PATH = "/usr/bin:/usr/local/bin:${env.PATH}"
    }
    
    stages {
        stage('Clone') {
            steps {
                checkout scm
            }
        }
        
        stage('Setup') {
            steps {
                sh '''
                    sudo apt-get update
                    sudo apt-get install -y curl gnupg apt-transport-https
                    curl -fsSL https://crystal-lang.org/install.sh | sudo bash
                    sudo apt-get install -y crystal shards
                    crystal --version
                    shards --version
                '''
            }
        }
        
        stage('Dependencies') {
            steps {
                sh 'sudo shards install'
            }
        }
        
        stage('Test') {
            steps {
                sh 'crystal spec'
            }
        }
    }
}
