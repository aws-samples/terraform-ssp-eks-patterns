#!/bin/bash

EKS_CLUSTER_ID='aws001-preprod-test-eks'        # Replace cluster id with your id
EMR_ON_EKS_NAMESPACE='emr-data-team-a'          # Replace namespace with your namespace
EMR_VIRTUAL_CLUSTER_NAME="$EKS_CLUSTER_ID-$EMR_ON_EKS_NAMESPACE"

export VIRTUAL_CLUSTER_ID=$(aws emr-containers list-virtual-clusters --query "virtualClusters[?name=='${EMR_VIRTUAL_CLUSTER_NAME}' && state=='RUNNING'].id" --output text)

# DELETE EMR VIRTUAL CLUSTER
if [[ $VIRTUAL_CLUSTER_ID != "" ]]; then
  echo "Found Cluster $EMR_VIRTUAL_CLUSTER_NAME ; Deleting now..."
  aws emr-containers delete-virtual-cluster --id $VIRTUAL_CLUSTER_ID
else
  echo "Cluster is not running with this name $EMR_VIRTUAL_CLUSTER_NAME"
fi
