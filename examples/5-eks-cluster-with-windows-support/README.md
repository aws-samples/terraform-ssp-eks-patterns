# EKS Cluster with Windows Node group  and Linux Spot Node Group

The following steps walks you through the deployment of this example 

This default config deploys the following AWS resources.
 - Creates a new VPC, 3 AZs with private and public subnets
 - Creates necessary VPC endpoints for node groups in private subnets
 - Creates an Internet gateway and a NAT gateway in each public subnet
 - Creates an EKS cluster a managed node group of Linux spot worker nodes and a self-managed node group of Windows on-demand worker nodes
 

## Deploy sample Windows and Linux deployments to verify support for both operating systems

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
# If you deployed sample Windows & Linux deployed from Step6
kubectl delete svc,deploy -n windows --all
kubectl delete svc,deploy -n linux --all
# Destroy all resources
terraform destroy -auto-approve
```

# See also

* [Windows support considerations](https://docs.aws.amazon.com/eks/latest/userguide/windows-support.html)
