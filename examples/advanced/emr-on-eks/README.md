# EKS Cluster with EMR on EKS Addon

This example deploys an EKS Cluster into a new VPC.

 - Creates a new sample VPC, 3 Private Subnets and 3 Public Subnets
 - Creates Internet gateway for Public Subnets and NAT Gateway for Private Subnets
 - Creates EKS Cluster Control plane with public endpoint (for demo reasons only) with one managed node group
 - Deploys Metrics server, Cluster Autoscaler and EMR on EKS Addon
