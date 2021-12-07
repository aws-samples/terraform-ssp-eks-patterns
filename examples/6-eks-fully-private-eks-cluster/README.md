# Fully Private EKS Cluster with VPC deployment

This example deploys a fully private EKS Cluster into a new VPC.

 - Creates a new sample VPC, 3 Private Subnets
 - Creates necessary VPCEndpoints so that the Managed nodegroup is able to get the necessary containers like CNI et al and run them on the nodes.
 - Approriate tags at subnet and node level so that K8 components understand these tags
 - Security Groups for ensuring cluster access
 - THE EKS cluster endpoint is set to private but it is still publicly resolavble via DNS
 
