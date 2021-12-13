# EKS Cluster with Self-managed Node Group

This example deploys a new EKS Cluster with a self-managed node group into a new VPC.

 - Creates a new sample VPC, 3 Private Subnets and 3 Public Subnets
 - Creates an Internet gateway for the Public Subnets and a NAT Gateway for the Private Subnets
 - Creates an EKS Cluster Control plane with public endpoint with one self-managed node group
