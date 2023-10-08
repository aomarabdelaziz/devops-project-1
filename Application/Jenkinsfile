pipeline {
    agent {
        label 'docker-agent'
    }
    tools {
        maven 'mvn-3.8.5'
    }
    stages {
        stage('Clean Stage') {
            steps {
                //git url: "https://github.com/aomarabdelaziz/regapp.git"
                sh 'mvn clean'
            }
        }
        stage('Install Stage') {
            steps {
                sh 'mvn install'
            }
        }
        stage('Building and Pushing Image') {
            steps {
                sh "docker build -t abdelazizomar/regapp:${BUILD_NUMBER} ."
                withCredentials([usernamePassword(credentialsId: 'docker-login', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                    sh "echo $PASS | docker login -u $USER --password-stdin"
                    sh "docker push abdelazizomar/regapp:${BUILD_NUMBER}"
                }
            }
        }
        stage('Deploy to k8s') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'bootstrap-server', keyFileVariable: 'keyfile', usernameVariable: 'USER')]) {
                    sh "ssh -o StrictHostKeyChecking=no -i $keyfile $USER@54.87.22.203 kubectl set image deployment/regapp regapp-container=abdelazizomar/regapp:${BUILD_NUMBER}"
                }
            }
        }
    }
}
