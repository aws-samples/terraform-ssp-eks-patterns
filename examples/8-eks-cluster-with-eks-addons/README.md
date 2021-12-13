# EKS Cluster with EKS Managed Add-ons

This example deploys a new EKS Cluster into a new VPC with EKS managed Add-ons

 - Creates a new VPC, 3 Private Subnets and 3 Public Subnets
 - Creates an Internet gateway for the Public Subnets and a NAT Gateway for the Private Subnets
 - Creates an EKS Cluster Control plane with public endpoint with one managed node group
 - Creates EKS managed Addons (`vpc-cni`, `coredns`, `kube-proxy`, `aws-ebs-csi-driver`)
