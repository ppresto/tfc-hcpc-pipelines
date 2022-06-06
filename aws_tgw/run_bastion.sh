#!/bin/bash

BASTION_IP=52.12.100.194

# debug init creation
#ssh -A ubuntu@${BASTION_IP}  sudo cat /var/lib/cloud/instance/user-data.txt

echo "###  consul.hcl ###"
ssh -A ubuntu@${BASTION_IP} cat /etc/consul.d/consul.hcl
echo
echo "### client_acl.hcl ###"
ssh -A ubuntu@${BASTION_IP} cat/etc/consul.d/client_acl.hcl