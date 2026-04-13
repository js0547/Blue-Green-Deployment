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

        stage('SonarQube Analysis') {
            steps {
                echo "🔍 Running SonarQube Code Analysis..."
                // Run SonarQube scanner for the backend via Maven
                sh "cd backend && mvn sonar:sonar || echo 'SonarQube analysis failed but continuing'"
            }
        }

        stage('OWASP Dependency-Check') {
            steps {
                echo "🛡️ Running OWASP Dependency-Check..."
                // Assuming dependency-check.sh is available in PATH on the EC2 instance
                sh "dependency-check.sh --project 'Healthcare-Portal' --scan ./backend || echo 'OWASP Dependency-Check failed but continuing'"
            }
        }

        stage('Build Docker Images') {
            steps {
                echo "📤 Building Images..."
                sh "aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
                
                // Build and Push Backend (shared tag for now)
                sh "docker build -t ${ECR_REGISTRY}/${BACKEND_IMAGE}:green ./backend"
                sh "docker tag ${ECR_REGISTRY}/${BACKEND_IMAGE}:green ${ECR_REGISTRY}/${BACKEND_IMAGE}:blue"
                
                // Build Frontend (Separate builds for Blue and Green themes)
                echo "🎨 Building BLUE frontend..."
                sh "docker build --build-arg VITE_APP_COLOR_THEME=blue --build-arg VITE_APP_VERSION=v1.0.0 -t ${ECR_REGISTRY}/${FRONTEND_IMAGE}:blue ./frontend"
                
                echo "🎨 Building GREEN frontend..."
                sh "docker build --build-arg VITE_APP_COLOR_THEME=green --build-arg VITE_APP_VERSION=v2.0.0 -t ${ECR_REGISTRY}/${FRONTEND_IMAGE}:green ./frontend"
            }
        }

        stage('Trivy Image Scan') {
            steps {
                echo "🔐 Running Trivy Image Scan..."
                sh "trivy image ${ECR_REGISTRY}/${BACKEND_IMAGE}:green || echo 'Trivy check returned vulnerabilities'"
                sh "trivy image ${ECR_REGISTRY}/${FRONTEND_IMAGE}:green || echo 'Trivy check returned vulnerabilities'"
            }
        }

        stage('Push to Amazon ECR') {
            steps {
                echo "📤 Pushing to ECR..."

                
                sh "docker push ${ECR_REGISTRY}/${BACKEND_IMAGE}:green"
                sh "docker push ${ECR_REGISTRY}/${FRONTEND_IMAGE}:green"
                sh "docker push ${ECR_REGISTRY}/${BACKEND_IMAGE}:blue"
                sh "docker push ${ECR_REGISTRY}/${FRONTEND_IMAGE}:blue"
            }
        }

        stage('Deploy to EKS') {
            steps {
                echo "🚀 Deploying to EKS..."
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
                botUser: true,
                tokenCredentialId: 'SLACK_TOKEN',
                channel: '#healthcare-alerts',
                message: "Healthcare Portal Build #${env.BUILD_NUMBER}: ${currentBuild.currentResult}"
            )
        }
    }
}
