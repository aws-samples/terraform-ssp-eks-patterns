#!/bin/bash

EKS_CLUSTER_ID='aws001-preprod-test-eks'        # Replace cluster id with your id
EMR_ON_EKS_NAMESPACE='emr-data-team-b'          # Replace namespace with your namespace
EMR_VIRTUAL_CLUSTER_NAME="$EKS_CLUSTER_ID-$EMR_ON_EKS_NAMESPACE"

export VIRTUAL_CLUSTER_ID=$(aws emr-containers list-virtual-clusters --query "virtualClusters[?name=='${EMR_VIRTUAL_CLUSTER_NAME}' && state=='RUNNING'].id" --output text)

# CREATE EMR VIRTUAL CLUSTER
if [[ $VIRTUAL_CLUSTER_ID = "" ]]; then
  echo "Creating new EMR Virtual Cluster"

    aws emr-containers create-virtual-cluster \
      --name $EMR_VIRTUAL_CLUSTER_NAME \
      --container-provider '{
        "id": "'"$EKS_CLUSTER_ID"'",
        "type": "EKS",
        "info": {
          "eksInfo": {
              "namespace": "'"$EMR_ON_EKS_NAMESPACE"'"
          }
      }
  }'

else
  echo "Cluster is already up and running $EMR_VIRTUAL_CLUSTER_NAME"
fi

# CREATE CLOUDWATCH LOG GROUP FOR SPARK JOBS
aws logs create-log-group --log-group-name /emr-on-eks-logs/$EMR_VIRTUAL_CLUSTER_NAME/$EMR_ON_EKS_NAMESPACE

