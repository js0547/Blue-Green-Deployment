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
                sh "cd backend && mvn clean package -DskipTests"
            }
        }

        stage('Push to Amazon ECR') {
            steps {
                echo "📤 Building and Pushing to ECR..."
                sh "aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
                
                // Build and Push Both Tags (for Showcase)
                sh "docker build -t ${ECR_REGISTRY}/${BACKEND_IMAGE}:green ./backend"
                sh "docker build -t ${ECR_REGISTRY}/${FRONTEND_IMAGE}:green ./frontend"
                sh "docker tag ${ECR_REGISTRY}/${BACKEND_IMAGE}:green ${ECR_REGISTRY}/${BACKEND_IMAGE}:blue"
                sh "docker tag ${ECR_REGISTRY}/${FRONTEND_IMAGE}:green ${ECR_REGISTRY}/${FRONTEND_IMAGE}:blue"
                
                sh "docker push ${ECR_REGISTRY}/${BACKEND_IMAGE}:green"
                sh "docker push ${ECR_REGISTRY}/${FRONTEND_IMAGE}:green"
                sh "docker push ${ECR_REGISTRY}/${BACKEND_IMAGE}:blue"
                sh "docker push ${ECR_REGISTRY}/${FRONTEND_IMAGE}:blue"
            }
        }

        stage('Deploy to EKS') {
            steps {
                echo "🚀 Preparing Manifests with ECR URIs..."
                // Fix Green
                sh "sed -i 's|${BACKEND_IMAGE}:green|${ECR_REGISTRY}/${BACKEND_IMAGE}:green|g' kubernetes/app/green-deployment.yaml"
                sh "sed -i 's|${FRONTEND_IMAGE}:green|${ECR_REGISTRY}/${FRONTEND_IMAGE}:green|g' kubernetes/app/green-deployment.yaml"
                // Fix Blue
                sh "sed -i 's|${BACKEND_IMAGE}:blue|${ECR_REGISTRY}/${BACKEND_IMAGE}:blue|g' kubernetes/app/blue-deployment.yaml"
                sh "sed -i 's|${FRONTEND_IMAGE}:blue|${ECR_REGISTRY}/${FRONTEND_IMAGE}:blue|g' kubernetes/app/blue-deployment.yaml"
                
                sh "aws eks update-kubeconfig --region ${REGION} --name ${CLUSTER_NAME}"
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
