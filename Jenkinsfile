pipeline {
    agent any
    
    stages {
        stage('Setup') {
            steps {
                sh '''
                  apt-get update
                  apt-get install -y curl gnupg apt-transport-https
                  curl -fsSL https://crystal-lang.org/install.sh | bash
                  apt-get install -y crystal
                  crystal --version
                  shards --version || echo "Shards is already bundled with Crystal."
               '''

            }
        }
        
        stage('Dependencies') {
            steps {
                sh 'shards install'
            }
        }
        
        stage('Test') {
            steps {
                sh 'crystal spec'
            }
        }
    }
}
