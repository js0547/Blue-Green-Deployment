#  Blue-Green Deployment + Prometheus + Grafana + AWS

This repository contains the source code, infrastructure definitions, and deployment pipelines for a Healthcare Portal application. The architecture includes a Java Spring Boot backend, a React frontend, and a Kubernetes-based deployment model using a Blue-Green deployment strategy on AWS EKS.

## Project Structure

- backend: Java application managed by Maven.
- frontend: React application built with Vite.
- kubernetes: Kubernetes manifests for application deployments, MySQL database, and monitoring services.
- management-scripts: Shell scripts for AWS resource management and teardown.
- Jenkinsfile: CI/CD pipeline definition for automated testing, scanning, building, and deployment.

## Prerequisites

To run and deploy this project, install the following tools:
- Docker
- Java 17 and Maven
- Node.js and npm
- AWS CLI configured with appropriate credentials
- Kubernetes CLI (kubectl)
- Jenkins (for running the CI/CD pipeline)
- SonarQube (for code quality analysis)
- Trivy (for vulnerability scanning)

## Local Development

### Backend
1. Navigate to the backend directory:
   cd backend
2. Build the application using Maven:
   mvn clean package
3. Run the application locally:
   mvn spring-boot:run

### Frontend
1. Navigate to the frontend directory:
   cd frontend
2. Install dependencies:
   npm install
3. Start the development server:
   npm run dev

## CI/CD Pipeline Execution

The Jenkins pipeline automates the entire distribution process. Ensure Jenkins has the necessary AWS credentials and Slack tokens configured.

The pipeline performs the following steps in order:
1. Code Checkout: Retrieves the latest source code.
2. Build and Package: Compiles the backend Java code.
3. Code Quality Analysis: Runs SonarQube to verify code compliance parameters.
4. Vulnerability Scanning: Uses Trivy to scan the file system for dependency issues.
5. Docker Build: Creates distinct Docker images for the backend and the frontend (Blue and Green themes).
6. Image Scanning: Runs Trivy on the generated Docker images to detect vulnerabilities.
7. Image Push: Uploads the Docker images to Amazon Elastic Container Registry (ECR).
8. EKS Deployment: Applies Kubernetes manifests to the AWS EKS cluster.
9. Promotion Approval: Pauses for manual confirmation before routing production traffic.
10. Traffic Cutover: Updates the Kubernetes Service to route incoming requests to the new Green environment.

## Kubernetes Deployment Guide

If deploying manually without Jenkins, use these steps.

1. Update your kubeconfig to connect to your EKS cluster:
   aws eks update-kubeconfig --region eu-north-1 --name healthcare-prod-cluster

2. Deploy the database module:
   kubectl apply -f kubernetes/db/

3. Deploy the application environments:
   kubectl apply -f kubernetes/app/

4. Deploy the monitoring stack:
   kubectl apply -f kubernetes/monitoring/

5. To access the portal deployments locally, use port forwarding:
   kubectl port-forward service/healthcare-portal-service 8080:80

## Monitoring

The project uses Prometheus and Grafana for monitoring cluster and application health.

To access the dashboards:
1. Start a port forward for Grafana:
   kubectl port-forward svc/monitoring-stack-grafana 3000:80 -n default
   Open http://localhost:3000 in your browser. (The username and password can be extracted from the kubernetes secret monitoring-stack-grafana).

2. Start a port forward for Prometheus:
   kubectl port-forward svc/monitoring-stack-kube-prom-prometheus 9090:9090 -n default
   Open http://localhost:9090 in your browser.

## Clean Up

To remove AWS resources and stop incurring additional cloud costs, use the provided teardown script:
1. Navigate to the management-scripts directory:
   cd management-scripts
2. Make the script executable:
   chmod +x aws-teardown.sh
3. Execute the script:
   ./aws-teardown.sh
