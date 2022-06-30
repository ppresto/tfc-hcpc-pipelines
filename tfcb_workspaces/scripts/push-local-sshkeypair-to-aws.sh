#!/usr/bin/env bash

# Push local ssh key to 1 or every region in AWS using AWS CLI,
# and set SSH_KEY_NAME variable used by the ./addAdmin_workspace.sh

unique_num=$(shuf -i 0-1000 -n 1)

# Requirement:  
#
# Create or use an existing ssh key $HOME/.ssh/id_rsa.pub
# Set aws_keypair_name to the destination AWS keypair name that is unique.
aws_keypair_name="my-aws-keypair-${unique_num}"
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
