#!/bin/bash

EKS_CLUSTER_ID='aws001-preprod-test-eks'

export VIRTUAL_CLUSTER_ID=$(aws emr-containers list-virtual-clusters --query "virtualClusters[?name=='${EKS_CLUSTER_ID}' && state=='RUNNING'].id" --output text)

# DELETE EMR VIRTUAL CLUSTER
if [[ $VIRTUAL_CLUSTER_ID != "" ]]; then
  echo "Found Cluster $EKS_CLUSTER_ID ; Deleting now..."
  aws emr-containers delete-virtual-cluster --id $VIRTUAL_CLUSTER_ID
else
  echo "Cluster is not running with this name $EKS_CLUSTER_ID"
fi
