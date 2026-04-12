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

        stage('Build & Scan') {
            steps {
                sh "cd backend && mvn clean package -DskipTests"
                sh "docker build -t ${BACKEND_IMAGE}:green ./backend"
                sh "docker build -t ${FRONTEND_IMAGE}:green ./frontend"
                sh "trivy image --severity HIGH,CRITICAL --no-progress ${BACKEND_IMAGE}:green"
            }
        }

        stage('Deploy to EKS') {
            steps {
                echo "Deploying to EKS using EC2 IAM Role permissions..."
                // No keys needed! The EC2 Instance Role handles authentication automatically.
                sh "aws eks update-kubeconfig --region ${REGION} --name ${CLUSTER_NAME}"
                sh "kubectl apply -f kubernetes/app/green-deployment.yaml"
            }
        }

        stage('Approve & Cutover') {
            steps {
                input message: "Promote to Production?"
                sh "sed -i 's/color: blue/color: green/g' kubernetes/app/service.yaml"
                sh "kubectl apply -f kubernetes/app/service.yaml"
            }
        }
    }

    post {
        always {
            // Slack still needs its token secret, but AWS is now handled by the Role
            withCredentials([string(credentialsId: 'SLACK_TOKEN', variable: 'TOKEN')]) {
                slackSend(
                    token: "${TOKEN}",
                    channel: '#healthcare-alerts',
                    message: "Healthcare Portal Status: ${currentBuild.currentResult}"
                )
            }
        }
    }
}
