#!/bin/sh

# user needs to have the following perms: AmazonEc2FullAccess, IAMFullAccess, AmazonS3FullAcccess, and need to give kms.*

# list of variables to set
# this is the cname entry - choose wisely
deploymentName=$1 # sample-test-1
databricksMasterAccountId=$2 # 111111-1111-1111-1111-1111111
u=$3 #email for the mws api
p=$4 # password for the mws api
awsRegion=$5 # us-east-1
isByoVpc=$6 # false
isByoCmk=$7 # false
awsAccountID=$8

# these can be whatever you want
workspaceName=$deploymentName
crossAccountIamRoleName="databricks-e2-"$deploymentName
crossAccountIamRoleNamePolicyName=$crossAccountIamRoleName"-policy"
credentialsName="creds-"$deploymentName
s3BucketName="databricks-e2-"$deploymentName
storageConfigName="storage-config-"$deploymentName
networkName="network-"$deploymentName
cmkAlias="databricks-e2-cmk-"$deploymentName

# helper strings file - this has a lot of the longs json strings that are customized based on the above configs
. helperStrings.sh

# you need an iam role that you can create things (buckets and roles) first
echo "Setting up the IAM role."
crossAccountArn=$(aws iam create-role --role-name $crossAccountIamRoleName --assume-role-policy-document "$assumeRolePolicyDocument" | jq -r '.Role.Arn')

# if byovpc then use a different policy
if [ "$isByoVpc" = true ]; then
  echo "Adding a byovpc policy to the role."
  aws iam put-role-policy --role-name $crossAccountIamRoleName --policy-name $crossAccountIamRoleNamePolicyName --policy-document "$iamPutRolePolicyByoVpc"
else
  echo "Adding a policy to the role."
  aws iam put-role-policy --role-name $crossAccountIamRoleName --policy-name $crossAccountIamRoleNamePolicyName --policy-document "$iamPutRolePolicy"
fi

# # create a credentialsId
echo "Creating the credentials within Databricks."
credentialsId=$(curl -s -X POST -u "$u:$p" -H "Content-Type: application/json" \
    "https://accounts.cloud.databricks.com/api/2.0/accounts/$databricksMasterAccountId/credentials" \
   -d '{
  "credentials_name": "'$credentialsName'",
  "aws_credentials": {
    "sts_role": {
      "role_arn": "'$crossAccountArn'"
    }
  }
}' | jq -r '.credentials_id')

# create an s3 bucket and policy
echo "Creating an S3 bucket."
aws s3api create-bucket --bucket $s3BucketName --region $awsRegion --create-bucket-configuration LocationConstraint=$awsRegion
echo "Adding a policy to the S3 bucket."
aws s3api put-bucket-policy --bucket $s3BucketName --policy "$putBucketPolicy"

# create a storage configuration
echo "Creating the storage configuration within Databricks."
storageConfigurationId=$(curl -s -X POST -u "$u:$p" -H "Content-Type: application/json" \
    "https://accounts.cloud.databricks.com/api/2.0/accounts/$databricksMasterAccountId/storage-configurations" \
   -d '{
  "storage_configuration_name": "'$storageConfigName'",
  "root_bucket_info": {
    "bucket_name": "'$s3BucketName'"
  }
}' | jq -r '.storage_configuration_id')

# get the existing VPC, subnets, and security groups configs and them pass it to the api
if [ "$isByoVpc" = true ]; then
  echo "Creating the network."
  # add NACL entry for outbound 3306 -- find name Network ACL
  aclId=$(aws ec2 describe-network-acls --filter "Name=tag:Name,Values=NetworkACL" | jq -r '.NetworkAcls[].Associations[0].NetworkAclId')
  aws ec2 create-network-acl-entry --network-acl-id $aclId --cidr-block 0.0.0.0/0 --egress --port-range From=3306,To=3306 --protocol tcp --rule-action allow --rule-number 993

  vpcId=$(aws ec2 describe-vpcs | jq -r '.Vpcs[].VpcId')
  subnet1=$(aws ec2 describe-subnets --filters "Name=tag:intuit:vpc:component:name,Values=PrivateSubnetAz1" | jq -r '.Subnets[].SubnetId')
  subnet2=$(aws ec2 describe-subnets --filters "Name=tag:intuit:vpc:component:name,Values=PrivateSubnetAz2" | jq -r '.Subnets[].SubnetId')
  securityGroupId=$(aws ec2 describe-security-groups --filters Name=group-name,Values=default | jq -r '.SecurityGroups[].GroupId')

  # create the STS vpc endpoint
  aws ec2 create-vpc-endpoint --vpc-id $vpcId --vpc-endpoint-type Interface --service-name com.amazonaws.us-west-2.sts --subnet-ids $subnet1 $subnet2 --security-group-ids $securityGroupId --policy-document "$stsPolicyDoc" --private-dns-enabled 

  # create the kinesis vpc endpoint
  aws ec2 create-vpc-endpoint --vpc-id $vpcId --vpc-endpoint-type Interface --service-name com.amazonaws.us-west-2.kinesis-streams --subnet-ids $subnet1 $subnet2 --security-group-ids $securityGroupId --policy-document "$stsPolicyDoc" --private-dns-enabled 

  networkId=$(curl -s -X POST -u "$u:$p" -H "Content-Type: application/json" \
    "https://accounts.cloud.databricks.com/api/2.0/accounts/$databricksMasterAccountId/networks" \
    -d '{
      "network_name": "'$networkName'",
      "vpc_id": "'$vpcId'",
      "subnet_ids": [
        "'$subnet1'",
        "'$subnet2'"
      ],
      "security_group_ids": [
        "'$securityGroupId'"
      ]
    }' | jq -r '.network_id')
 
fi

# create the CMK
if [ "$isByoCmk" = true ]; then
  echo "Creating a CMK key."
  keyMetadata=$(aws kms create-key --policy "$cmkPolicy" | jq -r '.KeyMetadata')
  keyArn=$(echo $keyMetadata | jq -r '.Arn')
  keyId=$(echo $keyMetadata | jq -r '.KeyId')

  echo "Creating a CMK alias."
  aws kms create-alias --alias-name alias/$cmkAlias --target-key-id $keyId

  # create the CMK entry in the databricks api
  echo "Creating the CMK entry in Databricks"
  databricksKeyId=$(curl -s -X POST -u "$u:$p" -H "Content-Type: application/json" \
  "https://accounts.cloud.databricks.com/api/2.0/accounts/$databricksMasterAccountId/customer-managed-keys" \
  -d '{
        "aws_key_info": {
          "key_arn": "'$keyArn'",
          "key_alias": "'$cmkAlias'",
          "key_region": "'$awsRegion'"
        }
      }' | jq -r '.customer_managed_key_id')
fi

# sleep for 10 seconds to allow the network creation to work
echo "Sleeping for 10 seconds to allow the the network to be created."
sleep 10

# start the actual deployment
echo "Starting the Databricks deployment."
if [ "$isByoVpc" = true ]; then
    workspaceId=$(curl -s -X POST -u "$u:$p" -H "Content-Type: application/json" \
    "https://accounts.cloud.databricks.com/api/2.0/accounts/$databricksMasterAccountId/workspaces" \
    -d '{
        "workspace_name": "'$workspaceName'",
        "deployment_name": "'$deploymentName'",
        "aws_region": "'$awsRegion'",
        "credentials_id": "'$credentialsId'",
        "storage_configuration_id": "'$storageConfigurationId'",
        "network_id": "'$networkId'",
        "is_no_public_ip_enabled": true,
        "customer_managed_key_id": "'$databricksKeyId'"
        }'| jq -r '.workspace_id')
else
    workspaceId=$(curl -s -X POST -u "$u:$p" -H "Content-Type: application/json" \
    "https://accounts.cloud.databricks.com/api/2.0/accounts/$databricksMasterAccountId/workspaces" \
    -d '{
        "workspace_name": "'$workspaceName'",
        "deployment_name": "'$deploymentName'",
        "aws_region": "'$awsRegion'",
        "credentials_id": "'$credentialsId'",
        "storage_configuration_id": "'$storageConfigurationId'",
        "is_no_public_ip_enabled": false
        }'| jq -r '.workspace_id')
fi

# check to see if the deployment is complete
echo Checking on the Databricks deployment status for workspace: $workspaceId - this should be completed within 3 minutes.
getWorkspaceStatus
while [ "$workspaceStatus" != "Workspace is running." ]
do  
  sleep 30
  getWorkspaceStatus
  echo "The workspace is still being setup... checking again in 30 seconds."
done

echo $workspaceStatus - Go to https://$deploymentName.cloud.databricks.com and login!

# # TODO: 
# ## did we want to create any initial instance profiles and choose an s3 bucket, etc?