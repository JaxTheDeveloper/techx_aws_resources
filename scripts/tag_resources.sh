#!/bin/bash

set -e

APPLICATION="Xbrain-w6-project"
OWNER="group1@gmail.com"
ENVIRONMENT="dev"
COSTCENTER="G1"
REGION="us-west-2"

echo "Starting resource tagging..."

########################################
# Lambda Functions
########################################

for fn in MarketUpdater AssetReader DataAggregationWorker AnomalyLoggingService
do
  echo "Tagging Lambda: $fn"

  ARN=$(aws lambda get-function \
    --function-name $fn \
    --region $REGION \
    --query 'Configuration.FunctionArn' \
    --output text)

  aws lambda tag-resource \
    --resource $ARN \
    --tags \
        "Application=$APPLICATION,Owner=$OWNER,Environment=$ENVIRONMENT,CostCenter=$COSTCENTER"
done

########################################
# RDS PostgreSQL
########################################

echo "Tagging RDS..."

RDS_ARN=$(aws rds describe-db-instances \
  --db-instance-identifier w6-db \
  --region $REGION \
  --query 'DBInstances[0].DBInstanceArn' \
  --output text)

aws rds add-tags-to-resource \
  --resource-name $RDS_ARN \
  --tags \
  	Key=Application,Value=$APPLICATION \
  	Key=Owner,Value=$OWNER \
  	Key=Environment,Value=$ENVIRONMENT \
  	Key=CostCenter,Value=$COSTCENTER

########################################
# EFS
########################################

echo "Tagging EFS..."

# EFS_ID=$(aws efs describe-file-systems \
#   --region $REGION \
#   --query 'FileSystems[0].FileSystemId' \
#   --output text)

# aws efs tag-resource \
#   --resource-id $EFS_ID \
#   --tags \
#     Key=Application,Value=$APPLICATION \
#     Key=Owner,Value=$OWNER \
#     Key=Environment,Value=$ENVIRONMENT \
#     Key=CostCenter,Value=$COSTCENTER

########################################
# API Gateway
########################################

echo "Tagging API Gateway..."

API_ID=$(aws apigateway get-rest-apis \
  --region $REGION \
  --query "items[?name=='W6_ApiGateway'].id" \
  --output text)

API_ARN="arn:aws:apigateway:${REGION}::/restapis/${API_ID}"

aws apigateway tag-resource \
  --resource-arn $API_ARN \
  --tags \
  	Application=$APPLICATION,Owner=$OWNER,Environment=$ENVIRONMENT,CostCenter=$COSTCENTER

########################################
# S3 Bucket
########################################

echo "Tagging S3..."

BUCKET_NAME="xbrain-w5-frontend"

aws s3api put-bucket-tagging \
  --bucket "$BUCKET_NAME" \
  --tagging "{
    \"TagSet\": [
      {
        \"Key\": \"Application\",
        \"Value\": \"$APPLICATION\"
      },
      {
        \"Key\": \"Owner\",
        \"Value\": \"$OWNER\"
      },
      {
        \"Key\": \"Environment\",
        \"Value\": \"$ENVIRONMENT\"
      },
      {
        \"Key\": \"CostCenter\",
        \"Value\": \"$COSTCENTER\"
      }
    ]
  }"

########################################
# NAT Gateway
########################################

echo "Tagging NAT Gateway..."

NAT_ID=$(aws ec2 describe-nat-gateways \
  --region $REGION \
  --query 'NatGateways[0].NatGatewayId' \
  --output text)

aws ec2 create-tags \
  --resources $NAT_ID \
  --tags \
  	Key=Application,Value=$APPLICATION \
  	Key=Owner,Value=$OWNER \
  	Key=Environment,Value=$ENVIRONMENT \
  	Key=CostCenter,Value=$COSTCENTER

########################################
# Network Firewall
########################################

echo "Tagging Network Firewall..."

FIREWALL_ARN=$(aws network-firewall list-firewalls \
  --region $REGION \
  --query 'Firewalls[0].FirewallArn' \
  --output text)

aws network-firewall tag-resource \
  --resource-arn $FIREWALL_ARN \
  --tags \
  	Key=Application,Value=$APPLICATION \
  	Key=Owner,Value=$OWNER \
  	Key=Environment,Value=$ENVIRONMENT \
  	Key=CostCenter,Value=$COSTCENTER

echo "All resources tagged successfully."