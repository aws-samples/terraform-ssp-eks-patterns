# EKS Cluster with Windows support

This default config deploys the following AWS resources.
 - Creates a new VPC, 3 AZs with private and public subnets
 - Creates necessary VPC endpoints for node groups in private subnets
 - Creates an Internet gateway and a NAT gateway in each public subnet
 - Creates an EKS cluster a managed node group of Linux spot worker nodes and a self-managed node group of Windows on-demand worker nodes

The following steps walk you through the deployment of this example.

# How to deploy

## Prerequisites:
Ensure that you have installed the following tools in your Mac or Windows Laptop before start working with this module and run `terraform plan` and `terraform apply`

1. [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
2. [kubectl](https://Kubernetes.io/docs/tasks/tools/)
3. [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

## Deployment steps

### Step1: Clone the repo using the command below

```shell script
git clone https://gitlab.aws.dev/vabonthu/terraform-aws-eks-accelerator-patterns.git
```

### Step2: Run terraform init

to initialize a working directory with configuration files

```shell script
cd examples/5-eks-cluster-with-windows-support
terraform init
```

### Step3: Run terraform plan

to verify the resources created by this execution

```shell script
export AWS_REGION="us-east-1"   # Select your own region
terraform plan
```

### Step4: Run terraform apply

to create resources

```shell script
terraform apply -auto-approve
```

## Configure kubectl and test cluster

EKS Cluster details can be extracted from terraform output or from AWS Console to get the name of cluster. This following command used to update the `kubeconfig` in your local machine where you run kubectl commands to interact with your EKS Cluster.

### Step5: Run update-kubeconfig command.

`~/.kube/config` file gets updated with EKS cluster context from the below command. Use the cluster's name available in the Terraform output as `eks_cluster_name`.

    $ aws eks --region us-east-1 update-kubeconfig --name <eks_cluster_name>

### Step6: (Optional) Deploy sample Windows and Linux workloads to verify support for both operating systems

```shell script
cd examples/5-eks-cluster-with-windows-support
# Sample Windows deployment
kubectl apply -f ./k8s/windows-iis-aspnet.yaml
# Wait for the Windows pod status to change to Running
watch -n 1 "kubectl get po -n windows"
# When the pod starts running, get the service endpoint
kubectl get svc aspnet -n windows -o json | jq -r '.status.loadBalancer.ingress[].hostname'
# Visit the endpoint given by the above command in your browser

# Sample Linux deployment
kubectl apply -f ./k8s/linux-nginx.yaml
```

# Cleanup

```shell script
cd examples/5-eks-cluster-with-windows-support
# If you deployed sample Windows & Linux workloads from Step6
kubectl delete svc,deploy -n windows --all
kubectl delete svc,deploy -n linux --all
# Destroy all resources
terraform destroy -auto-approve
```

# See also

* [Windows support considerations](https://docs.aws.amazon.com/eks/latest/userguide/windows-support.html)
