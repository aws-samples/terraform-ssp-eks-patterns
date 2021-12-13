# Fully Private EKS Cluster with VPC deployment


This example deploys a fully private EKS Cluster into a new VPC.

 - Creates a new VPC, 3 Private Subnets and 3 Public Subnets
 - Creates Internet gateway for Public Subnets and NAT Gateway for Private Subnets
 - Creates EKS Cluster Control plane with public endpoint with one managed node group
