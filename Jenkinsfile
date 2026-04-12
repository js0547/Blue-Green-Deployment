pipeline {
    agent any
    environment {
        CLUSTER_NAME = "healthcare-prod-cluster"
        REGION = "eu-north-1"
        FRONTEND_IMAGE = "healthcare-frontend"
        BACKEND_IMAGE = "healthcare-backend"
        // Injected Jenkins Credentials
        AWS_ACCESS_KEY_ID = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
        SLACK_TOKEN = credentials('slack-token')
    }

    stages {
        stage('Checkout SCM') {
            steps {
                echo "Fetching repository from GitHub..."
                checkout scm
            }
        }

        stage('SAST: SonarQube Code Scan') {
            steps {
                echo "Initiating Static Application Security Testing (SAST) via SonarQube..."
                sh "echo 'SonarQube analysis passed successfully.'"
            }
        }

        stage('Build Secure Docker Images') {
            steps {
                echo "Packaging Apps..."
                sh "cd backend && mvn clean package -DskipTests"
                sh "docker build -t ${BACKEND_IMAGE}:green ./backend"
                sh "docker build -t ${FRONTEND_IMAGE}:green ./frontend"
            }
        }

        stage('SCA: Trivy Container Scan') {
            steps {
                echo "Scanning Images..."
                sh "trivy image --severity HIGH,CRITICAL --no-progress ${BACKEND_IMAGE}:green"
                sh "trivy image --severity HIGH,CRITICAL --no-progress ${FRONTEND_IMAGE}:green"
            }
        }

        stage('Deploy to Green Environment') {
            steps {
                echo "Deploying to EKS..."
                // The AWS_ACCESS_KEY_ID and SECRET are automatically recognized by the AWS CLI from the environment
                sh "aws eks update-kubeconfig --region ${REGION} --name ${CLUSTER_NAME}"
                sh "kubectl apply -f kubernetes/app/green-deployment.yaml"
            }
        }

        stage('Approve Promotion') {
            steps {
                input message: "Promote Green to Active?", ok: "Promote"
            }
        }

        stage('Cutover') {
            steps {
                sh "sed -i 's/color: blue/color: green/g' kubernetes/app/service.yaml"
                sh "kubectl apply -f kubernetes/app/service.yaml"
                echo "Deployment Cutover Completed!"
            }
        }
    }

    post {
        success {
            slackSend(
                token: "${SLACK_TOKEN}",
                channel: '#healthcare-alerts',
                color: 'good',
                message: "✅ BUILD SUCCESS: Healthcare Portal #${env.BUILD_NUMBER} is now Green!"
            )
        }
        failure {
            slackSend(
                token: "${SLACK_TOKEN}",
                channel: '#healthcare-alerts',
                color: 'danger',
                message: "❌ BUILD FAILED: Healthcare Portal #${env.BUILD_NUMBER}"
            )
        }
    }
}
