/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: MIT-0
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this
 * software and associated documentation files (the "Software"), to deal in the Software
 * without restriction, including without limitation the rights to use, copy, modify,
 * merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
 * PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

locals {
  tenant      = var.tenant
  environment = var.environment
  zone        = var.zone

  kubernetes_version = var.kubernetes_version

  vpc_cidr     = "10.0.0.0/16"
  vpc_name     = join("-", [local.tenant, local.environment, local.zone, "vpc"])
  cluster_name = join("-", [local.tenant, local.environment, local.zone, "eks"])

  terraform_version = var.terraform_version
}

module "aws_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "v3.2.0"

  name = local.vpc_name
  cidr = local.vpc_cidr
  azs  = data.aws_availability_zones.available.names

  public_subnets       = [for k, v in slice(data.aws_availability_zones.available.names, 0, 3) : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets      = [for k, v in slice(data.aws_availability_zones.available.names, 0, 3) : cidrsubnet(local.vpc_cidr, 8, k + 10)]
  enable_nat_gateway   = true
  create_igw           = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }

}
#---------------------------------------------------------------
# Example to consume aws-eks-accelerator-for-terraform module
#---------------------------------------------------------------
module "aws-eks-accelerator-for-terraform" {
  source = "git@github.com:aws-samples/aws-eks-accelerator-for-terraform.git"

  tenant            = local.tenant
  environment       = local.environment
  zone              = local.zone
  terraform_version = local.terraform_version

  # EKS Cluster VPC and Subnet mandatory config
  vpc_id             = module.aws_vpc.vpc_id
  private_subnet_ids = module.aws_vpc.private_subnets

  # EKS CONTROL PLANE VARIABLES
  create_eks         = var.create_eks
  kubernetes_version = local.kubernetes_version

  #---------------------------------------------------------#
  # EKS WORKER NODE GROUPS
  #---------------------------------------------------------#
  enable_managed_nodegroups = var.enable_self_managed_nodegroups
  managed_node_groups = var.managed_node_groups

  #---------------------------------------------------------#
  # EKS SELF MANAGED WORKER NODE GROUPS
  #---------------------------------------------------------#

  enable_windows_support                    = var.enable_windows_support
  windows_vpc_resource_controller_image_tag = "v0.2.7" # enable_windows_support= true
  windows_vpc_admission_webhook_image_tag   = "v0.2.7" # enable_windows_support= true

  enable_self_managed_nodegroups = var.enable_self_managed_nodegroups
  self_managed_node_groups = var.self_managed_node_groups

  #---------------------------------------------------------#
  # FARGATE PROFILES
  #---------------------------------------------------------#
  enable_fargate = var.enable_fargate
  fargate_profiles = var.fargate_profiles

  #---------------------------------------
  # METRICS SERVER HELM ADDON
  #---------------------------------------
  metrics_server_enable = var.metrics_server_enable
  metrics_server_helm_chart = var.metrics_server_helm_chart

  #---------------------------------------
  # CLUSTER AUTOSCALER HELM ADDON
  #---------------------------------------
  cluster_autoscaler_enable = var.cluster_autoscaler_helm_chart
  cluster_autoscaler_helm_chart = var.cluster_autoscaler_helm_chart

  #---------------------------------------
  # TRAEFIK INGRESS CONTROLLER HELM ADDON
  #---------------------------------------
  traefik_ingress_controller_enable = var.traefik_ingress_controller_enable
  traefik_helm_chart =var.traefik_helm_chart
}
