org               = "aws"     # Organization Name. Used to tag resources
tenant            = "aws001"  # AWS account name or unique id for tenant
environment       = "preprod" # Environment area eg., preprod or prod
zone              = "test"    # Environment with in one sub_tenant or business unit
terraform_version = "Terraform v1.0.1"


create_eks         = true
kubernetes_version = "1.21"

managed_node_groups = {
  #---------------------------------------------------------#
  # ON-DEMAND Worker Group - Worker Group - 1
  #---------------------------------------------------------#
  mg_4 = {
    # 1> Node Group configuration - Part1
    node_group_name        = "managed-ondemand" # Max 40 characters for node group name
    create_launch_template = true               # false will use the default launch template
    launch_template_os     = "amazonlinux2eks"  # amazonlinux2eks or bottlerocket
    public_ip              = false              # Use this to enable public IP for EC2 instances; only for public subnets used in launch templates ;
    pre_userdata           = <<-EOT
            yum install -y amazon-ssm-agent
            systemctl enable amazon-ssm-agent && systemctl start amazon-ssm-agent"
        EOT
    # 2> Node Group scaling configuration
    desired_size    = 3
    max_size        = 3
    min_size        = 3
    max_unavailable = 1 # or percentage = 20

    # 3> Node Group compute configuration
    ami_type       = "AL2_x86_64" # AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64, CUSTOM
    capacity_type  = "ON_DEMAND"  # ON_DEMAND or SPOT
    instance_types = ["m4.large"] # List of instances used only for SPOT type
    disk_size      = 50

    # 4> Node Group network configuration
    subnet_ids = module.aws_vpc.private_subnets # Define your private/public subnets list with comma seprated subnet_ids  = ['subnet1','subnet2','subnet3']

    k8s_taints = []

    k8s_labels = {
      Environment = "preprod"
      Zone        = "test"
      WorkerType  = "ON_DEMAND"
    }
    additional_tags = {
      ExtraTag    = "m5x-on-demand"
      Name        = "m5x-on-demand"
      subnet_type = "private"
    }

    create_worker_security_group = true

  },
  #---------------------------------------------------------#
  # SPOT Worker Group - Worker Group - 2
  #---------------------------------------------------------#
  /*
  spot_m5 = {
    # 1> Node Group configuration - Part1
    node_group_name        = "managed-spot-m5"
    create_launch_template = true              # false will use the default launch template
    launch_template_os        = "amazonlinux2eks" # amazonlinux2eks  or bottlerocket
    public_ip              = false             # Use this to enable public IP for EC2 instances; only for public subnets used in launch templates ;
    pre_userdata           = <<-EOT
               yum install -y amazon-ssm-agent
               systemctl enable amazon-ssm-agent && systemctl start amazon-ssm-agent"
           EOT
    # Node Group scaling configuration
    desired_size = 3
    max_size     = 3
    min_size     = 3
    # Node Group update configuration. Set the maximum number or percentage of unavailable nodes to be tolerated during the node group version update.
    max_unavailable = 1 # or percentage = 20
    # Node Group compute configuration
    ami_type       = "AL2_x86_64"
    capacity_type  = "SPOT"
    instance_types = ["t3.medium", "t3a.medium"]
    disk_size      = 50
    # Node Group network configuration
    subnet_ids  = []        # Define your private/public subnets list with comma seprated subnet_ids  = ['subnet1','subnet2','subnet3']
    k8s_taints = []
    k8s_labels = {
      Environment = "preprod"
      Zone        = "test"
      WorkerType  = "SPOT"
    }
    additional_tags = {
      ExtraTag    = "spot_nodes"
      Name        = "spot"
      subnet_type = "private"
    }
    create_worker_security_group = false
  },
  #---------------------------------------------------------#
  # BOTTLEROCKET - Worker Group - 3
  #---------------------------------------------------------#
  brkt_m5 = {
    node_group_name        = "managed-brkt-m5"
    create_launch_template = true           # false will use the default launch template
    launch_template_os        = "bottlerocket" # amazonlinux2eks  or bottlerocket
    public_ip              = false          # Use this to enable public IP for EC2 instances; only for public subnets used in launch templates ;
    pre_userdata           = ""
    desired_size    = 3
    max_size        = 3
    min_size        = 3
    max_unavailable = 1
    ami_type       = "CUSTOM"
    capacity_type  = "ON_DEMAND" # ON_DEMAND or SPOT
    instance_types = ["m5.large"]
    disk_size      = 50
    custom_ami_id  = "ami-044b114caf98ce8c5" # https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami-bottlerocket.html
    # Node Group network configuration
    subnet_ids  = []        # Define your private/public subnets list with comma seprated subnet_ids  = ['subnet1','subnet2','subnet3']
    k8s_taints = {}
    k8s_labels = {
      Environment = "preprod"
      Zone        = "test"
      OS          = "bottlerocket"
      WorkerType  = "ON_DEMAND_BOTTLEROCKET"
    }
    additional_tags = {
      ExtraTag = "bottlerocket"
      Name     = "bottlerocket"
    }
    #security_group ID
    create_worker_security_group = true
  }
    */
} # END OF MANAGED NODE GROUPS

self_managed_node_groups = {
  #---------------------------------------------------------#
  # ON-DEMAND Self Managed Worker Group - Worker Group - 1
  #---------------------------------------------------------#
  self_mg_4 = {
    node_group_name        = "self-managed-ondemand" # Name is used to create a dedicated IAM role for each node group and adds to AWS-AUTH config map
    create_launch_template = true
    launch_template_os     = "amazonlinux2eks"       # amazonlinux2eks  or bottlerocket or windows
    custom_ami_id          = "ami-0dfaa019a300f219c" # Bring your own custom AMI generated by Packer/ImageBuilder/Puppet etc.
    public_ip              = false                   # Enable only for public subnets
    pre_userdata           = <<-EOT
            yum install -y amazon-ssm-agent \
            systemctl enable amazon-ssm-agent && systemctl start amazon-ssm-agent \
        EOT

    disk_size     = 20
    instance_type = "m5.large"

    desired_size = 2
    max_size     = 10
    min_size     = 2

    capacity_type = "" # Optional Use this only for SPOT capacity as  capacity_type = "spot"

    k8s_labels = {
      Environment = "preprod"
      Zone        = "test"
      WorkerType  = "SELF_MANAGED_ON_DEMAND"
    }

    additional_tags = {
      ExtraTag    = "m5x-on-demand"
      Name        = "m5x-on-demand"
      subnet_type = "private"
    }


    subnet_ids = [] # Define your private/public subnets list with comma seprated subnet_ids  = ['subnet1','subnet2','subnet3']

    create_worker_security_group = false # Creates a dedicated sec group for this Node Group
  },
  /*
  spot_m5 = {
    # 1> Node Group configuration - Part1
    node_group_name = "self-managed-spot"
    create_launch_template = true
    launch_template_os = "amazonlinux2eks"       # amazonlinux2eks  or bottlerocket or windows
    custom_ami_id   = "ami-0dfaa019a300f219c" # Bring your own custom AMI generated by Packer/ImageBuilder/Puppet etc.
    public_ip       = false                   # Enable only for public subnets
    pre_userdata    = <<-EOT
            yum install -y amazon-ssm-agent \
            systemctl enable amazon-ssm-agent && systemctl start amazon-ssm-agent \
        EOT
    disk_size     = 20
    instance_type = "m5.large"
    desired_size = 2
    max_size     = 10
    min_size     = 2
    capacity_type = "spot"
    # Node Group network configuration
    subnet_ids  = []        # Define your private/public subnets list with comma seprated subnet_ids  = ['subnet1','subnet2','subnet3']
    k8s_taints = []
    k8s_labels = {
      Environment = "preprod"
      Zone        = "test"
      WorkerType  = "SPOT"
    }
    additional_tags = {
      ExtraTag    = "spot_nodes"
      Name        = "spot"
      subnet_type = "private"
    }
    create_worker_security_group = false
  },
  brkt_m5 = {
    node_group_name = "self-managed-brkt"
    create_launch_template = true
    launch_template_os = "bottlerocket"          # amazonlinux2eks  or bottlerocket or windows
    custom_ami_id   = "ami-044b114caf98ce8c5" # Bring your own custom AMI generated by Packer/ImageBuilder/Puppet etc.
    public_ip       = false                   # Use this to enable public IP for EC2 instances; only for public subnets used in launch templates ;
    pre_userdata    = ""
    desired_size    = 3
    max_size        = 3
    min_size        = 3
    max_unavailable = 1
    instance_types = "m5.large"
    disk_size      = 50
    subnet_ids  = []        # Define your private/public subnets list with comma seprated subnet_ids  = ['subnet1','subnet2','subnet3']
    k8s_taints = []
    k8s_labels = {
      Environment = "preprod"
      Zone        = "test"
      OS          = "bottlerocket"
      WorkerType  = "ON_DEMAND_BOTTLEROCKET"
    }
    additional_tags = {
      ExtraTag = "bottlerocket"
      Name     = "bottlerocket"
    }
    create_worker_security_group = true
  }
  #---------------------------------------------------------#
  # ON-DEMAND Self Managed Windows Worker Node Group
  #---------------------------------------------------------#
  windows_od = {
    node_group_name = "windows-ondemand"
    create_launch_template = true
    launch_template_os = "windows"          # amazonlinux2eks  or bottlerocket or windows
    # custom_ami_id   = "ami-xxxxxxxxxxxxxxxx" # Bring your own custom AMI. Default Windows AMI is the latest EKS Optimized Windows Server 2019 English Core AMI.
    public_ip = false # Enable only for public subnets
    disk_size     = 50
    instance_type = "m5n.large"
    desired_size = 2
    max_size     = 4
    min_size     = 2
    k8s_labels = {
      Environment = "preprod"
      Zone        = "test"
      WorkerType  = "WINDOWS_ON_DEMAND"
    }
    additional_tags = {
      ExtraTag    = "windows-on-demand"
      Name        = "windows-on-demand"
    }
    subnet_ids  = []        # Define your private/public subnets list with comma seprated subnet_ids  = ['subnet1','subnet2','subnet3']
    create_worker_security_group = false # Creates a dedicated sec group for this Node Group
  }
*/
} # END OF SELF MANAGED NODE GROUPS

fargate_profiles = {
  default = {
    fargate_profile_name = "default"
    fargate_profile_namespaces = [{
      namespace = "default"
      k8s_labels = {
        Environment = "preprod"
        Zone        = "test"
        env         = "fargate"
      }
    }]

    subnet_ids = [] # Provide list of private subnets

    additional_tags = {
      ExtraTag = "Fargate"
    }
  },
  /*
  multi = {
    fargate_profile_name = "multi-namespaces"
    fargate_profile_namespaces = [{
      namespace = "default"
      k8s_labels = {
        Environment = "preprod"
        Zone        = "test"
        OS          = "Fargate"
        WorkerType  = "FARGATE"
        Namespace   = "default"
      }
      },
      {
        namespace = "sales"
        k8s_labels = {
          Environment = "preprod"
          Zone        = "test"
          OS          = "Fargate"
          WorkerType  = "FARGATE"
          Namespace   = "default"
        }
    }]
    subnet_ids = [] # Provide list of private subnets
    additional_tags = {
      ExtraTag = "Fargate"
    }
  }, */
} # END OF FARGATE PROFILES

# K8S Addons

metrics_server_enable = true
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

cluster_autoscaler_enable = true

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

