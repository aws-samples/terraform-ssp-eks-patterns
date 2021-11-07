# EMR on EKS with AMP and AMG

This example deploys the following resources

 - Creates a new sample VPC, 3 Private Subnets and 3 Public Subnets
 - Creates Internet gateway for Public Subnets and NAT Gateway for Private Subnets
 - Creates EKS Cluster Control plane with public endpoint (for demo purpose only) with one managed node group
 - Deploys Metrics server, Cluster Autoscaler, Prometheus and EMR on EKS Addon
 - Creates Amazon managed Prometheus and configures Prometheus addon to remote write metrics to AMP

## Pre-requisties

### Step1: Login to AWS Account

Login to AWS Account with Adimistrator role privileges for this demo


### Step2: Install Terraform in CloudShell

- Open `CloudShell` service fromm the search bar

- Instal Terraform using the following commands
  
```sh
   sudo yum install -y yum-utils
   sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
   
   sudo yum -y install terraform
   
   terraform -help
   terraform version
   
   touch ~/.bashrc
   terraform -install-autocomplete
```

### Step3: Clone Github Repo

- Clone Terraform SSP EKS Patterns repo

```sh
git clone https://github.com/aws-samples/terraform-ssp-eks-patterns.git

```

- Change directory

```sh
cd terraform-ssp-eks-patterns/examples/advanced/emr-on-eks
```

### Step4: Install Terraform in CloudShell

- Run Terraform init to intialize the modules
  
```sh
terraform init
```

- Run Terraform plan to verify the resources created by this execution. 

```sh
export AWS_REGION="eu-west-1"   # Select your own region
terraform plan
```

- Run Terraform Apply to deploy the solution. 

```
terraform apply --auto-approve
```

### Step5: Verify the resources created by Terraform Apply

- Login to EKS Console to verify the cluster is up and running
- Verify the Prometheus Server K8s addon is running
- Verify the AMP workspace is created
- verify the AMG is configured
- Verify the EMR on EKS namespace and service account is crated

### Step6: Create EMR Virtual Cluster

- Execute the following command to deploy the EMR Virtual Cluster

```sh
#!/bin/bash

EKS_CLUSTER_ID='aws001-preprod-test-eks'
EMR_ON_EKS_NAMESPACE='emr-data-team-a'

export VIRTUAL_CLUSTER_ID=$(aws emr-containers list-virtual-clusters --query "virtualClusters[?name=='${EKS_CLUSTER_ID}' && state=='RUNNING'].id" --output text)

# CREATE EMR VIRTUAL CLUSTER
if [[ $VIRTUAL_CLUSTER_ID = "" ]]; then
  echo "Creating new EMR Virtual Cluster"

    aws emr-containers create-virtual-cluster \
      --name $EKS_CLUSTER_ID \
      --container-provider '{
        "id": "'"$EKS_CLUSTER_ID"'",
        "type": "EKS",
        "info": {
          "eksInfo": {
              "namespace": "'"$EMR_ON_EKS_NAMESPACE"'"
          }
      }
  }'
```

### Step7: Execute the Spark Job 

- Execute the Spark job with Prometheus metrcis configuraiton

```sh
#!/bin/bash

# INPUT VARIABLES 
EMR_ON_EKS_ROLE_ID="aws001-preprod-test-emr-eks-data-team-a"       # Replace EMR IAM role with your ID
EKS_CLUSTER_ID='aws001-preprod-test-eks'                           # Replace cluster id with your id
EMR_ON_EKS_NAMESPACE='emr-data-team-a'                             # Replace namespace with your namespace
JOB_NAME='pi'                                   

# FIND ROLE ARN and EMR VIRTUAL CLUSTER ID 
EMR_ROLE_ARN=$(aws iam get-role --role-name $EMR_ON_EKS_ROLE_ID --query Role.Arn --output text)
VIRTUAL_CLUSTER_ID=$(aws emr-containers list-virtual-clusters --query "virtualClusters[?name=='${EKS_CLUSTER_ID}' && state=='RUNNING'].id" --output text)

# Execute Spark job
if [[ $VIRTUAL_CLUSTER_ID != "" ]]; then
  echo "Found Cluster $EKS_CLUSTER_ID; Executing the Spark job now..."
  aws emr-containers start-job-run \
    --virtual-cluster-id $VIRTUAL_CLUSTER_ID \
    --name $JOB_NAME \
    --execution-role-arn $EMR_ROLE_ARN \
    --release-label emr-6.3.0-latest \
    --job-driver '{
      "sparkSubmitJobDriver": {
        "entryPoint": "local:///usr/lib/spark/examples/src/main/python/pi.py",
        "sparkSubmitParameters": "--conf spark.executor.instances=2 --conf spark.executor.memory=2G --conf spark.executor.cores=2 --conf spark.driver.cores=1"
      }
    }'
else
  echo "Cluster is not in running state $EKS_CLUSTER_ID"
fi

```

### Step7: Verify the Spark Job running in EKS Cluster

- Verify the Spark Job running in EKS Cluster


### Step8: Verify the Spark Metrics in Prometheus

- Use portforward open Prometheus WebUI and search for the Spark Metrics

### Step8: Amazon Managed Grafana config

- Login to Amazon managed Grafana and add AMP as a datasource
- Create a dashbaord using the community dashboard id
- Visualize the Spark job metrics

## Cleanup


## Conclusion
