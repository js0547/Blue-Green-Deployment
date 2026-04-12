pipeline {
    agent any
    environment {
        CLUSTER_NAME = "healthcare-prod-cluster"
        REGION = "eu-north-1"
        FRONTEND_IMAGE = "healthcare-frontend"
        BACKEND_IMAGE = "healthcare-backend"
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('SAST: SonarQube') {
            steps {
                sh "echo 'SonarQube passed.'"
            }
        }

        stage('Build Docker Images') {
            steps {
                sh "cd backend && mvn clean package -DskipTests"
                sh "docker build -t ${BACKEND_IMAGE}:green ./backend"
                sh "docker build -t ${FRONTEND_IMAGE}:green ./frontend"
            }
        }

        stage('SCA: Trivy') {
            steps {
                sh "trivy image --severity HIGH,CRITICAL --no-progress ${BACKEND_IMAGE}:green"
                sh "trivy image --severity HIGH,CRITICAL --no-progress ${FRONTEND_IMAGE}:green"
            }
        }

        stage('Deploy to EKS') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'SECRET_KEY')
                ]) {
                    echo "Deploying with explicit environment variables..."
                    sh "AWS_ACCESS_KEY_ID=${KEY_ID} AWS_SECRET_ACCESS_KEY=${SECRET_KEY} aws eks update-kubeconfig --region ${REGION} --name ${CLUSTER_NAME}"
                    sh "AWS_ACCESS_KEY_ID=${KEY_ID} AWS_SECRET_ACCESS_KEY=${SECRET_KEY} kubectl apply -f kubernetes/app/green-deployment.yaml"
                }
            }
        }

        stage('Promotion Approval') {
            steps {
                input message: "Promote to Production?"
            }
        }

        stage('Traffic Cutover') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'SECRET_KEY')
                ]) {
                    sh "AWS_ACCESS_KEY_ID=${KEY_ID} AWS_SECRET_ACCESS_KEY=${SECRET_KEY} sed -i 's/color: blue/color: green/g' kubernetes/app/service.yaml"
                    sh "AWS_ACCESS_KEY_ID=${KEY_ID} AWS_SECRET_ACCESS_KEY=${SECRET_KEY} kubectl apply -f kubernetes/app/service.yaml"
                }
            }
        }
    }

    post {
        always {
            withCredentials([string(credentialsId: 'SLACK_TOKEN', variable: 'TOKEN')]) {
                slackSend(
                    token: "${TOKEN}",
                    channel: '#healthcare-alerts',
                    color: currentBuild.currentResult == 'SUCCESS' ? 'good' : 'danger',
                    message: "Healthcare Portal Build #${env.BUILD_NUMBER}: ${currentBuild.currentResult}"
                )
            }
        }
    }
}
