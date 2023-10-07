pipeline {
    agent {
        label 'docker'
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
    }
}
