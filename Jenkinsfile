pipeline {
    agent any
    environment {
        CLUSTER_NAME = "healthcare-prod-cluster"
        REGION = "eu-north-1"
        AWS_ACCOUNT_ID = "010822067639"
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
        FRONTEND_IMAGE = "healthcare-frontend"
        BACKEND_IMAGE = "healthcare-backend"
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Build & Package') {
            steps {
                echo "🏗️ Compiling Java Backend..."
                sh "cd backend && mvn clean package -DskipTests"
            }
        }

        stage('Push to Amazon ECR') {
            steps {
                echo "📤 Authenticating and Pushing Images to ECR..."
                sh "aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
                
                // Build with full ECR tags
                sh "docker build -t ${ECR_REGISTRY}/${BACKEND_IMAGE}:green ./backend"
                sh "docker build -t ${ECR_REGISTRY}/${FRONTEND_IMAGE}:green ./frontend"
                
                // Push
                sh "docker push ${ECR_REGISTRY}/${BACKEND_IMAGE}:green"
                sh "docker push ${ECR_REGISTRY}/${FRONTEND_IMAGE}:green"
            }
        }

        stage('SCA: Trivy') {
            steps {
                sh "trivy image --severity HIGH,CRITICAL --no-progress ${ECR_REGISTRY}/${BACKEND_IMAGE}:green"
            }
        }

        stage('Deploy: Green Environment') {
            steps {
                echo "🚀 Deploying to EKS..."
                // Dynamically update the YAML with the new ECR path before applying
                sh "sed -i 's|${BACKEND_IMAGE}:green|${ECR_REGISTRY}/${BACKEND_IMAGE}:green|g' kubernetes/app/green-deployment.yaml"
                sh "sed -i 's|${FRONTEND_IMAGE}:green|${ECR_REGISTRY}/${FRONTEND_IMAGE}:green|g' kubernetes/app/green-deployment.yaml"
                
                sh "aws eks update-kubeconfig --region ${REGION} --name ${CLUSTER_NAME}"
                // Apply EVERYTHING in the folder (ConfigMaps + Deployment)
                sh "kubectl apply -f kubernetes/app/"
            }
        }

        stage('Promotion Approval') {
            steps {
                input message: "Promote Green to Production?"
            }
        }

        stage('Traffic Cutover') {
            steps {
                sh "sed -i 's/color: blue/color: green/g' kubernetes/app/service.yaml"
                sh "kubectl apply -f kubernetes/app/service.yaml"
            }
        }
    }

    post {
        always {
            slackSend(
                tokenCredentialId: 'SLACK_TOKEN',
                channel: '#healthcare-alerts',
                message: "Healthcare Portal Build #${env.BUILD_NUMBER}: ${currentBuild.currentResult}"
            )
        }
    }
}
