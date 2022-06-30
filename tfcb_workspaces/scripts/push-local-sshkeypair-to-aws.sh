#!/usr/bin/env bash

# Push local ssh key to 1 or every region in AWS using AWS CLI,
# and set SSH_KEY_NAME variable used by the ./addAdmin_workspace.sh

unique_num=$(shuf -i 0-1000 -n 1)

# Requirement:  
#
# Create or use an existing ssh key $HOME/.ssh/id_rsa.pub
# Provide the aws_keypair_name as input to the script.
# If nothing is provided the destination AWS keypair will be generated.

if [[ -z "${1}" ]]; then
  aws_keypair_name="my-aws-keypair-${unique_num}"
else
  aws_keypair_name="${1}"
fi
export SSH_KEY_NAME=${aws_keypair_name}

# Path to PUBLIC ssh key that you want pushed to AWS
publickeyfile="$HOME/.ssh/id_rsa.pub"

# set target region or by default all available regions will be used.
#regions="us-west-2"

# If regions is not set get all regions
if [[ -z $regions ]]; then
regions=$(aws ec2 describe-regions \
  --output text \
  --query 'Regions[*].RegionName')
fi

for region in $regions; do
  echo "INFO: $region - $aws_keypair_name"
  aws ec2 import-key-pair \
    --region "$region" \
    --key-name "$aws_keypair_name" \
    --public-key-material "fileb://$publickeyfile"
done
