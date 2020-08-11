#!/bin/sh

# list of variables to set
# this is the cname entry - choose wisely
deploymentName=$1 # sample-test-1
databricksMasterAccountId=$2 # 111111-1111-1111-1111-1111111
u=$3 #email for the mws api
p=$4 # password for the mws api
awsRegion=$5 # us-east-1
isByoVpc=$6 # false
isByoCmk=$7 # false

# these can be whatever you want
workspaceName=$deploymentName
crossAccountIamRoleName="databricks-e2-"$deploymentName
crossAccountIamRoleNamePolicyName=$crossAccountIamRoleName"-policy"
credentialsName="creds-"$deploymentName
s3BucketName="databricks-e2-"$deploymentName
storageConfigName="storage-config-"$deploymentName

# helper strings file - this has a lot of the longs json strings that are customized based on the above configs
. includes/helperStrings.sh

# you need an iam role that you can create things (buckets and roles) first
crossAccountArn=$(aws iam create-role --role-name $crossAccountIamRoleName --assume-role-policy-document "$assumeRolePolicyDocument" | jq -r '.Role.Arn')

# TODO: if byovpc and cmk then use a different json file
aws iam put-role-policy --role-name $crossAccountIamRoleName --policy-name $crossAccountIamRoleNamePolicyName --policy-document "$iamPutRolePolicy"

# create a credentialsId
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
aws s3api create-bucket --bucket $s3BucketName --region $awsRegion
aws s3api put-bucket-policy --bucket $s3BucketName --policy "$putBucketPolicy"

# create a storage configuration
storageConfigurationId=$(curl -s -X POST -u "$u:$p" -H "Content-Type: application/json" \
    "https://accounts.cloud.databricks.com/api/2.0/accounts/$databricksMasterAccountId/storage-configurations" \
   -d '{
  "storage_configuration_name": "'$storageConfigName'",
  "root_bucket_info": {
    "bucket_name": "'$s3BucketName'"
  }
}' | jq -r '.storage_configuration_id')

# TODO: create vpc

# if byovpc then we have to do a couple of steps
if [ "$isByoVPC" = true ]; then
  # get configs for vpc from jensen
  echo "do something"
  networkId=null
fi
# TODO: create cmk
if [ "$isByoCMK" = true ]; then
    echo "do something"
fi

# start the actual deployment
if [ "$isByoVPC" = true ]; then
    curl -s -X POST -u "$u:$p" -H "Content-Type: application/json" \
    "https://accounts.cloud.databricks.com/api/2.0/accounts/$databricksMasterAccountId/workspaces" \
    -d '{
        "workspace_name": "'$workspaceName'",
        "deployment_name": "'$deploymentName'",
        "aws_region": "'$awsRegion'",
        "credentials_id": "'$credentialsId'",
        "storage_configuration_id": "'$storageConfigurationId'",
        "network_id": "'$networkId'",
        "is_no_public_ip_enabled": true
        }'
else
    curl -s -X POST -u "$u:$p" -H "Content-Type: application/json" \
    "https://accounts.cloud.databricks.com/api/2.0/accounts/$databricksMasterAccountId/workspaces" \
    -d '{
        "workspace_name": "'$workspaceName'",
        "deployment_name": "'$deploymentName'",
        "aws_region": "'$awsRegion'",
        "credentials_id": "'$credentialsId'",
        "storage_configuration_id": "'$storageConfigurationId'",
        "is_no_public_ip_enabled": false
        }'
fi

# workspace has been successfully created and is ready to go!

# echo Success. Wait 2 minutes and then go to: https://"$deploymentName".cloud.databricks.com and login!
# TODO: create first username/pw