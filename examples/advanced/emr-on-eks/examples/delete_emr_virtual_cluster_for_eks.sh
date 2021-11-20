#!/bin/bash

EMR_VIRTUAL_CLUSTER_ID=$1 # Expects Input parameter to delete EMR Virtual cluster id

export VIRTUAL_CLUSTER_ID=$(aws emr-containers list-virtual-clusters --query "virtualClusters[?name=='${EMR_VIRTUAL_CLUSTER_ID}' && state=='RUNNING'].id" --output text)

# DELETE EMR VIRTUAL CLUSTER
if [[ $VIRTUAL_CLUSTER_ID != "" ]]; then
  echo "Found Cluster $EMR_VIRTUAL_CLUSTER_ID ; Deleting now..."
  aws emr-containers delete-virtual-cluster --id $VIRTUAL_CLUSTER_ID
else
  echo "Cluster is not running with this name $EMR_VIRTUAL_CLUSTER_ID"
fi
