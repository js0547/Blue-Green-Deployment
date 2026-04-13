#!/bin/bash

# Configuration
REGION="eu-north-1"
CLUSTER_NAME="healthcare-prod-cluster"

echo "=== 1. Deleting Kubernetes LoadBalancers ==="
# Find all services of type LoadBalancer across all namespaces
LBS=$(kubectl get svc -A -o jsonpath='{range .items[?(@.spec.type=="LoadBalancer")]}{.metadata.namespace}/{.metadata.name} {end}')

if [ -z "$LBS" ]; then
  echo "No LoadBalancers found."
else
  for lb in $LBS; do
    NS=${lb%%/*}
    SVC=${lb##*/}
    echo "Deleting LoadBalancer service: $SVC in namespace $NS"
    kubectl delete svc -n $NS $SVC
  done
  
  echo "Waiting 30 seconds for AWS Load Balancer resources to be fully detached in the cloud..."
  sleep 30
fi

echo "=== 2. Deleting EKS Node Group ==="
echo "This step takes approx. 3-5 minutes. Please wait..."
aws eks delete-nodegroup --cluster-name $CLUSTER_NAME --nodegroup-name healthcare-prod-nodes --region $REGION
aws eks wait nodegroup-deleted --cluster-name $CLUSTER_NAME --nodegroup-name healthcare-prod-nodes --region $REGION
echo "EKS Node Group deleted."

echo "=== 3. Deleting EKS Cluster ==="
echo "This step takes approx. 5-10 minutes. Please wait..."
aws eks delete-cluster --name $CLUSTER_NAME --region $REGION
aws eks wait cluster-deleted --name $CLUSTER_NAME --region $REGION
echo "EKS Cluster deleted."

echo "=== 4. Deleting associated IAM Roles ==="
aws iam detach-role-policy --role-name HealthcareEKSClusterRole --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy 2>/dev/null
aws iam delete-role --role-name HealthcareEKSClusterRole 2>/dev/null

aws iam detach-role-policy --role-name HealthcareEKSNodeRole --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy 2>/dev/null
aws iam detach-role-policy --role-name HealthcareEKSNodeRole --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly 2>/dev/null
aws iam detach-role-policy --role-name HealthcareEKSNodeRole --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy 2>/dev/null
aws iam delete-role --role-name HealthcareEKSNodeRole 2>/dev/null
echo "IAM Roles deleted."

echo "=== 5. Disabling (Stopping) Management EC2 Instance ==="
# We stop the instance rather than terminating it to preserve Jenkins and SonarQube setup
INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=HealthcareManagementServer" "Name=instance-state-name,Values=running" \
    --query "Reservations[*].Instances[*].InstanceId" \
    --output text \
    --region $REGION)

if [ "$INSTANCE_ID" != "" ] && [ "$INSTANCE_ID" != "None" ]; then
    echo "Stopping EC2 instance: $INSTANCE_ID"
    aws ec2 stop-instances --instance-ids $INSTANCE_ID --region $REGION
    echo "EC2 instance successfully stopped to prevent billing. Data is retained."
else
    echo "Management EC2 instance not found or already stopped."
fi

echo "Teardown complete! Cloud components destroyed but your Management EC2 Server is preserved."
