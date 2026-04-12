#!/bin/bash
REGION="eu-north-1"
CLUSTER_NAME="healthcare-prod-cluster"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --region $REGION)

# Fetch all subnets in the default VPC (EKS requires at least 2 subnets in different AZs)
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text --region $REGION)
SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[*].SubnetId" --output text --region $REGION | tr '\t' ',')

echo "Creating IAM Role for EKS Cluster..."
aws iam create-role --role-name HealthcareEKSClusterRole --assume-role-policy-document file://management-scripts/cluster-trust-policy.json
aws iam attach-role-policy --role-name HealthcareEKSClusterRole --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy

echo "Creating IAM Role for EKS Worker Nodes..."
aws iam create-role --role-name HealthcareEKSNodeRole --assume-role-policy-document file://management-scripts/node-trust-policy.json
aws iam attach-role-policy --role-name HealthcareEKSNodeRole --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
aws iam attach-role-policy --role-name HealthcareEKSNodeRole --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
aws iam attach-role-policy --role-name HealthcareEKSNodeRole --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy

echo "Beginning EKS Cluster Creation (This takes 10-15 minutes)..."
aws eks create-cluster --name $CLUSTER_NAME \
  --role-arn arn:aws:iam::${ACCOUNT_ID}:role/HealthcareEKSClusterRole \
  --resources-vpc-config subnetIds=$SUBNET_IDS \
  --region $REGION

# The wait command ensures the script pauses until the control plane is fully provisioned
aws eks wait cluster-active --name $CLUSTER_NAME --region $REGION 
echo "EKS Cluster is ACTIVE. Provisioning Worker Nodes..."

aws eks create-nodegroup --cluster-name $CLUSTER_NAME \
  --nodegroup-name healthcare-prod-nodes \
  --node-role arn:aws:iam::${ACCOUNT_ID}:role/HealthcareEKSNodeRole \
  --subnets $SUBNET_IDS \
  --instance-types m7i-flex.large \
  --region $REGION

echo "EKS Bootstrapping Commands Submitted!"
