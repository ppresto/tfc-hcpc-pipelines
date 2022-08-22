#!/bin/bash

# Setup local AWS Env using doormat with se_demos_dev
#doormat --smoke-test || doormat -r && eval $(doormat aws -a se_demos_dev)
doormat login && eval $(doormat aws export -a se_demos_dev)

# get identity
aws sts get-caller-identity

# add EKS cluster to $HOME/.kube/config
aws eks --region us-west-2 update-kubeconfig --name presto-aws-eks
