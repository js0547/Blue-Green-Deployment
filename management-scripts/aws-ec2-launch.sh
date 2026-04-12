#!/bin/bash

# Variables
REGION="eu-north-1"
KEY_NAME="healthcare-key"
INSTANCE_TYPE="m7i-flex.large" # 8GB RAM / 2 vCPUs

# Dynamically fetch the latest Ubuntu 22.04 AMI ID for the region
AMI_ID=$(aws ssm get-parameters --names /aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id --region $REGION --query "Parameters[0].Value" --output text)
VPC_ID=$(aws ec2 describe-vpcs --query "Vpcs[0].VpcId" --output text --region $REGION)

echo "Using AMI $AMI_ID in region $REGION"

# 1. Create Key Pair and save it locally
aws ec2 create-key-pair \
    --key-name $KEY_NAME \
    --key-type rsa \
    --region $REGION \
    --query "KeyMaterial" \
    --output text > ${KEY_NAME}.pem

# Secure the key file
chmod 400 ${KEY_NAME}.pem
echo "Created key pair: ${KEY_NAME}.pem"

# 2. Create Security Group
SG_ID=$(aws ec2 create-security-group \
    --group-name HealthcareManagementSG \
    --description "Management Layer SG for Jenkins and SonarQube" \
    --vpc-id $VPC_ID \
    --query "GroupId" \
    --output text \
    --region $REGION)

echo "Created Security Group: $SG_ID"

# 3. Add Inbound Rules (Least Privilege)
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $REGION
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 8080 --cidr 0.0.0.0/0 --region $REGION # Jenkins
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 9000 --cidr 0.0.0.0/0 --region $REGION # SonarQube

# 4. Launch the EC2 Instance (Placed in eu-north-1b)
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $SG_ID \
    --placement AvailabilityZone=${REGION}b \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=HealthcareManagementServer}]' \
    --query "Instances[0].InstanceId" \
    --output text \
    --region $REGION)

echo "Launched Management EC2 Instance: $INSTANCE_ID"
