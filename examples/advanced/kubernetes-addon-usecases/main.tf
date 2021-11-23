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

terraform {
  required_version = ">= 1.0.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.60.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.3.0"
    }
  }
}

provider "aws" {
  region = data.aws_region.current.id
  alias  = "default"
}

terraform {
  backend "local" {
    path = "local_tf_state/terraform-main.tfstate"
  }
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

locals {
  tenant      = "aws001"  # AWS account name or unique id for tenant
  environment = "preprod" # Environment area eg., preprod or prod
  zone        = "test"    # Environment with in one sub_tenant or business unit

  kubernetes_version = "1.21"

  vpc_cidr     = "10.0.0.0/16"
  vpc_name     = join("-", [local.tenant, local.environment, local.zone, "vpc"])
  cluster_name = join("-", [local.tenant, local.environment, local.zone, "eks"])

  terraform_version = "Terraform v1.0.1"
}

module "aws_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "v3.2.0"

  name = local.vpc_name
  cidr = local.vpc_cidr
  azs  = data.aws_availability_zones.available.names

  public_subnets  = [for k, v in slice(data.aws_availability_zones.available.names, 0, 3) : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets = [for k, v in slice(data.aws_availability_zones.available.names, 0, 3) : cidrsubnet(local.vpc_cidr, 8, k + 10)]

  enable_nat_gateway   = true
  create_igw           = true
  enable_dns_hostnames = true
  single_nat_gateway   = true

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
  source            = "git@github.com:aws-samples/aws-eks-accelerator-for-terraform.git"
  tenant            = local.tenant
  environment       = local.environment
  zone              = local.zone
  terraform_version = local.terraform_version

  # EKS Cluster VPC and Subnet mandatory config
  vpc_id             = module.aws_vpc.vpc_id
  private_subnet_ids = module.aws_vpc.private_subnets

  # EKS CONTROL PLANE VARIABLES
  create_eks         = true
  kubernetes_version = local.kubernetes_version

  # EKS MANAGED NODE GROUPS
  enable_managed_nodegroups = true
  # default false
  managed_node_groups = {
    mg_4 = {
      node_group_name = "managed-ondemand"
      instance_types = [
      "m5.xlarge"]
      max_size   = "12"
      subnet_ids = module.aws_vpc.private_subnets
    }
  }
  #---------------------------------------
  # TRAEFIK INGRESS CONTROLLER HELM ADDON
  #---------------------------------------
  traefik_ingress_controller_enable = true

  # Optional Map value
  traefik_helm_chart = {
    name       = "traefik"                         # (Required) Release name.
    repository = "https://helm.traefik.io/traefik" # (Optional) Repository URL where to locate the requested chart.
    chart      = "traefik"                         # (Required) Chart name to be installed.
    version    = "10.0.0"                          # (Optional) Specify the exact chart version to install. If this is not specified, the latest version is installed.
    namespace  = "kube-system"                     # (Optional) The namespace to install the release into. Defaults to default
    timeout    = "1200"                            # (Optional)
    lint       = "true"                            # (Optional)
    # (Optional) Example to show how to override values using SET
    set = [{
      name  = "service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
      value = "nlb"
    }]
    # (Optional) Example to show how to pass metrics-server-values.yaml
    values = [templatefile("${path.module}/k8s_addons/traefik-values.yaml", {
      operating_system = "linux"
    })]
  }

  #---------------------------------------
  # METRICS SERVER HELM ADDON
  #---------------------------------------
  metrics_server_enable = true

  # Optional Map value
  metrics_server_helm_chart = {
    name       = "metrics-server"                                    # (Required) Release name.
    repository = "https://kubernetes-sigs.github.io/metrics-server/" # (Optional) Repository URL where to locate the requested chart.
    chart      = "metrics-server"                                    # (Required) Chart name to be installed.
    version    = "3.5.0"                                             # (Optional) Specify the exact chart version to install. If this is not specified, the latest version is installed.
    namespace  = "kube-system"                                       # (Optional) The namespace to install the release into. Defaults to default
    timeout    = "1200"                                              # (Optional)
    lint       = "true"                                              # (Optional)

    # (Optional) Example to show how to pass metrics-server-values.yaml
    values = [templatefile("${path.module}/k8s_addons/metrics-server-values.yaml", {
      operating_system = "linux"
    })]
  }

  #---------------------------------------
  # CLUSTER AUTOSCALER HELM ADDON
  #---------------------------------------
  cluster_autoscaler_enable = true

  # Optional Map value
  cluster_autoscaler_helm_chart = {
    name       = "cluster-autoscaler"                      # (Required) Release name.
    repository = "https://kubernetes.github.io/autoscaler" # (Optional) Repository URL where to locate the requested chart.
    chart      = "cluster-autoscaler"                      # (Required) Chart name to be installed.
    version    = "9.10.7"                                  # (Optional) Specify the exact chart version to install. If this is not specified, the latest version is installed.
    namespace  = "kube-system"                             # (Optional) The namespace to install the release into. Defaults to default
    timeout    = "1200"                                    # (Optional)
    lint       = "true"                                    # (Optional)

    # (Optional) Example to show how to pass metrics-server-values.yaml
    values = [templatefile("${path.module}/k8s_addons/cluster-autoscaler-vaues.yaml", {
      operating_system = "linux"
    })]
  }

  #---------------------------------------
  # AWS MANAGED PROMETHEUS ENABLE
  #---------------------------------------
  aws_managed_prometheus_enable         = true
  aws_managed_prometheus_workspace_name = "amp-workspace-${local.cluster_name}"
  # Optional

  #---------------------------------------
  # COMMUNITY PROMETHEUS ENABLE
  #---------------------------------------
  prometheus_enable = true

  # Optional Map value
  prometheus_helm_chart = {
    name       = "prometheus"                                         # (Required) Release name.
    repository = "https://prometheus-community.github.io/helm-charts" # (Optional) Repository URL where to locate the requested chart.
    chart      = "prometheus"                                         # (Required) Chart name to be installed.
    version    = "14.4.0"                                             # (Optional) Specify the exact chart version to install. If this is not specified, the latest version is installed.
    namespace  = "prometheus"                                         # (Optional) The namespace to install the release into. Defaults to default
    values = [templatefile("${path.module}/k8s_addons/prometheus-values.yaml", {
      operating_system = "linux"
    })]

  }

  #---------------------------------------
  # ENABLE NGINX
  #---------------------------------------
  nginx_ingress_controller_enable = false
  # Optional nginx_helm_chart
  nginx_helm_chart = {
    name       = "ingress-nginx"
    chart      = "ingress-nginx"
    repository = "https://kubernetes.github.io/ingress-nginx"
    version    = "3.33.0"
    namespace  = "kube-system"
    values     = [templatefile("${path.module}/k8s_addons/nginx_default_values.yaml", {})]
  }

  #---------------------------------------
  # ENABLE AGONES
  #---------------------------------------
  # NOTE: Agones requires a Node group in Public Subnets and enable Public IP
  agones_enable = false
  # Optional  agones_helm_chart
  agones_helm_chart = {
    name               = "agones"
    chart              = "agones"
    repository         = "https://agones.dev/chart/stable"
    version            = "1.15.0"
    namespace          = "kube-system"
    gameserver_minport = 7000 # required for sec group changes to worker nodes
    gameserver_maxport = 8000 # required for sec group changes to worker nodes
    values = [templatefile("${path.module}/k8s_addons/agones-values.yaml", {
      expose_udp            = true
      gameserver_namespaces = "{${join(",", ["default", "xbox-gameservers", "xbox-gameservers"])}}"
      gameserver_minport    = 7000
      gameserver_maxport    = 8000
    })]
  }

  #---------------------------------------
  # ENABLE AWS DISTRO OPEN TELEMETRY
  #---------------------------------------
  aws_open_telemetry_enable = false
  aws_open_telemetry_addon = {
    aws_open_telemetry_namespace                        = "aws-otel-eks"
    aws_open_telemetry_emitter_otel_resource_attributes = "service.namespace=AWSObservability,service.name=ADOTEmitService"
    aws_open_telemetry_emitter_name                     = "trace-emitter"
    aws_open_telemetry_emitter_image                    = "public.ecr.aws/g9c4k4i4/trace-emitter:1"
    aws_open_telemetry_collector_image                  = "public.ecr.aws/aws-observability/aws-otel-collector:latest"
    aws_open_telemetry_aws_region                       = "eu-west-1"
    aws_open_telemetry_emitter_oltp_endpoint            = "localhost:55680"
  }

  #---------------------------------------
  # AWS-FOR-FLUENTBIT HELM ADDON
  #---------------------------------------
  aws_for_fluentbit_enable = true

  aws_for_fluentbit_helm_chart = {
    name                                      = "aws-for-fluent-bit"
    chart                                     = "aws-for-fluent-bit"
    repository                                = "https://aws.github.io/eks-charts"
    version                                   = "0.1.0"
    namespace                                 = "logging"
    aws_for_fluent_bit_cw_log_group           = "/${local.cluster_name}/worker-fluentbit-logs" # Optional
    aws_for_fluentbit_cwlog_retention_in_days = 90
    create_namespace                          = true
    values = [templatefile("${path.module}/k8s_addons/aws-for-fluentbit-values.yaml", {
      region                          = data.aws_region.current.name,
      aws_for_fluent_bit_cw_log_group = "/${local.cluster_name}/worker-fluentbit-logs"
    })]
    set = [
      {
        name  = "nodeSelector.kubernetes\\.io/os"
        value = "linux"
      }
    ]
  }

  #---------------------------------------
  # ENABLE SPARK on K8S OPERATOR
  #---------------------------------------
  spark_on_k8s_operator_enable = true

  # Optional Map value
  spark_on_k8s_operator_helm_chart = {
    name             = "spark-operator"
    chart            = "spark-operator"
    repository       = "https://googlecloudplatform.github.io/spark-on-k8s-operator"
    version          = "1.1.6"
    namespace        = "spark-k8s-operator"
    timeout          = "1200"
    create_namespace = true
    values           = [templatefile("${path.module}/k8s_addons/spark-k8s-operator-values.yaml", {})]

  }

  #---------------------------------------
  # ENABLE EMR ON EKS
  #---------------------------------------
  enable_emr_on_eks = true

  emr_on_eks_teams = {
    data_team_a = {
      emr_on_eks_namespace     = "emr-data-team-a"
      emr_on_eks_iam_role_name = "emr-eks-data-team-a"
    }

    data_team_b = {
      emr_on_eks_namespace     = "emr-data-team-b"
      emr_on_eks_iam_role_name = "emr-eks-data-team-b"
    }
  }

  #---------------------------------------
  # FARGATE FLUENTBIT
  #---------------------------------------
  fargate_fluentbit_enable = true
  fargate_fluentbit_config = {
    output_conf  = <<EOF
[OUTPUT]
  Name cloudwatch_logs
  Match *
  region eu-west-1
  log_group_name /${local.cluster_name}/fargate-fluentbit-logs
  log_stream_prefix "fargate-logs-"
  auto_create_group true
    EOF
    filters_conf = <<EOF
[FILTER]
  Name parser
  Match *
  Key_Name log
  Parser regex
  Preserve_Key On
  Reserve_Data On
    EOF
    parsers_conf = <<EOF
[PARSER]
  Name regex
  Format regex
  Regex ^(?<time>[^ ]+) (?<stream>[^ ]+) (?<logtag>[^ ]+) (?<message>.+)$
  Time_Key time
  Time_Format %Y-%m-%dT%H:%M:%S.%L%z
  Time_Keep On
  Decode_Field_As json message
    EOF
  }

  #---------------------------------------
  # ENABLE ARGOCD
  #---------------------------------------
  argocd_enable = true
  # Optional Map value
  argocd_helm_chart = {
    name             = "argo-cd"
    chart            = "argo-cd"
    repository       = "https://argoproj.github.io/argo-helm"
    version          = "3.26.3"
    namespace        = "argocd"
    timeout          = "1200"
    create_namespace = true
    values           = [templatefile("${path.module}/k8s_addons/argocd-values.yaml", {})]
  }

  #---------------------------------------
  # KEDA ENABLE
  #---------------------------------------
  keda_enable = true

  # Optional Map value
  keda_helm_chart = {
    name       = "keda"                                         # (Required) Release name.
    repository = "https://kedacore.github.io/charts" # (Optional) Repository URL where to locate the requested chart.
    chart      = "keda"                                         # (Required) Chart name to be installed.
    version    = "2.4.0"                                             # (Optional) Specify the exact chart version to install. If this is not specified, the latest version is installed.
    namespace  = "keda"                                         # (Optional) The namespace to install the release into. Defaults to default
    values = [templatefile("${path.module}/k8s_addons/keda-values.yaml", {})]
  }

  #---------------------------------------
  # Vertical Pod Autoscaling
  #---------------------------------------
  vpa_enable = true

  vpa_helm_chart = {
    name       = "vpa"                                 # (Required) Release name.
    repository = "https://charts.fairwinds.com/stable" # (Optional) Repository URL where to locate the requested chart.
    chart      = "vpa"                                 # (Required) Chart name to be installed.
    version    = "0.5.0"                               # (Optional) Specify the exact chart version to install. If this is not specified, the latest version is installed.
    namespace  = "vpa-ns"                              # (Optional) The namespace to install the release into. Defaults to default
    values     = [templatefile("${path.module}/k8s_addons/vpa-values.yaml", {})]
  }

}
