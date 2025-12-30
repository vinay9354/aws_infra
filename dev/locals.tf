# -----------------------------
# Common Locals
# -----------------------------
locals {
  vpc_cidr_block = module.vpc.vpc_cidr_block
}

# -------------------------
# Security Group locals
# -------------------------
locals {
  # Define ALL security groups here
  security_groups = {
    vinay-dev-infra-nat-sg = {
      description = "nat instance security group"
      tags = {
        Usecase = "NatInstanceSG"
      }
      ingress_rules = [
        {
          description              = "allow all inbound from vpc cidr"
          from_port                = 0
          to_port                  = 0
          protocol                 = "-1"
          cidr_blocks              = [local.vpc_cidr_block]
          ipv6_cidr_blocks         = []
          prefix_list_ids          = []
          source_security_group_id = null
          self                     = false
        }
      ]

      # Optional – override default module egress if you want
      egress_rules = [
        {
          description              = "Allow all outbound"
          from_port                = 0
          to_port                  = 0
          protocol                 = "-1"
          cidr_blocks              = ["0.0.0.0/0"]
          ipv6_cidr_blocks         = ["::/0"]
          prefix_list_ids          = []
          source_security_group_id = null
          self                     = false
        }
      ]
    }

    vinay-aws-infra-codebuild-sg = {
      description = "Security group for CodeBuild projects"
      tags = {
        Usecase = "CodeBuildSG"
      }

      egress_rules = [
        {
          description              = "Allow all outbound"
          from_port                = 0
          to_port                  = 0
          protocol                 = "-1"
          cidr_blocks              = ["0.0.0.0/0"]
          ipv6_cidr_blocks         = ["::/0"]
          prefix_list_ids          = []
          source_security_group_id = null
          self                     = false
        }
      ]
    }
  }
}

# -------------------------
# Ec2 Instance locals
# -------------------------
locals {
  # Define EC2 instances for this environment.
  # Each map key is an instance identifier; pick keys that make sense for your environment.
  # Subnet ids are taken from the subnet modules created in this workspace (keys must match those used in var.public_subnets/var.private_subnets).
  # Security groups reference the security_group module created above.
  #
  # NOTE: Replace the placeholder AMI IDs ("ami-REPLACE_ME") with real AMI IDs for your region,
  # or update the map to reference a data lookup that returns a valid AMI.
  ec2_instances = {
    vinay-dev-infra-nat-instance = {
      ami_id                      = data.aws_ssm_parameter.al2023_ami.value # <-- Replace with a valid AMI for ap-south-1
      instance_type               = "t3a.micro"
      create_key_pair             = true
      create_iam_role             = true
      subnet_id                   = module.public_subnets["ec2-1"].subnet_id
      associate_public_ip_address = true
      cpu_credits                 = "standard"
      security_group_ids          = [module.security_group["vinay-dev-infra-nat-sg"].security_group_id]
      source_dest_check           = false
      root_block_device = {
        volume_type           = "gp3"
        volume_size           = 8
        iops                  = 3000
        throughput            = 125
        delete_on_termination = true
      }
      tags = {
        Autostop = "true"
      }
    }

  }
}

# -------------------------
# IAM Policy locals
# -------------------------
locals {
  iam_policies = {
    ec2-start-stop-policy = {
      description = "Allow start and stop of EC2 instances"
      policy = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Sid" : "ec2access",
            "Effect" : "Allow",
            "Action" : [
              "ec2:StartInstances",
              "ec2:StopInstances",
              "ec2:DescribeInstanceStatus"
            ],
            "Resource" : "*"
          }
        ]
      })
      tags = {
        Purpose = "ec2-start-stop-policy"
      }
    }
  }
}

# -------------------------
# IAM Role locals
# -------------------------
locals {
  iam_roles = {
    "ec2-ssm-scheduler-role" = {
      description = "Role for EC2 scheduler to start/stop instances"
      assume_role_policy = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Sid" : "",
            "Effect" : "Allow",
            "Principal" : {
              "Service" : [
                "ssm.amazonaws.com"
              ]
            },
            "Action" : "sts:AssumeRole"
          }
        ]
      })
      policy_arns = [
        module.iam_policies["ec2-start-stop-policy"].arn
      ]
      create_instance_profile = false
      tags = {
        Purpose = "Scheduler"
      }
    }
    vinay-infra-codebuild-role = {
      description = "Role for CodeBuild to access VPC resources"
      assume_role_policy = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Sid" : "",
            "Effect" : "Allow",
            "Principal" : {
              "Service" : [
                "codebuild.amazonaws.com"
              ]
            },
            "Action" : "sts:AssumeRole"
          }
        ]
      })
      policy_arns = [
        "arn:aws:iam::aws:policy/AdministratorAccess"
      ]
      create_instance_profile = false
      tags = {
        Purpose = "CodeBuild"
      }
    }
    ebs-csi-driver-role = {
      description = "IAM Role for EBS CSI Driver with Pod Identity"
      assume_role_policy = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Sid" : "AllowEksAuthToAssumeRoleForPodIdentity",
            "Effect" : "Allow",
            "Principal" : {
              "Service" : "pods.eks.amazonaws.com"
            },
            "Action" : [
              "sts:AssumeRole",
              "sts:TagSession"
            ]
          }
        ]
      })
      policy_arns = [
        "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      ]
      create_instance_profile = false
      tags = {
        Purpose = "EBS-CSI-Driver"
      }
    }
  }
}

# -------------------------
# EKS Cluster Locals
# -------------------------
locals {
  eks_cluster_config = {
    # --------------------------------------------------------------------------
    # General Cluster Configuration
    # --------------------------------------------------------------------------
    cluster_name    = "vinay-dev-infra-eks-cluster"
    cluster_version = "1.34" # Kubernetes version

    # --------------------------------------------------------------------------
    # Networking Configuration
    # --------------------------------------------------------------------------
    # List of subnet IDs where the EKS cluster control plane (ENIs) and nodes will be placed.
    # For private clusters, these should be private subnets.
    subnet_ids = [
      module.private_subnets["eks-1"].subnet_id,
      module.private_subnets["eks-2"].subnet_id,
      module.private_subnets["eks-3"].subnet_id
    ]

    # Cluster Endpoint Access Control
    # It is recommended to keep public access disabled for security.
    cluster_endpoint_private_access      = true
    cluster_endpoint_public_access       = false
    cluster_endpoint_public_access_cidrs = []

    # --------------------------------------------------------------------------
    # Access Management (Authentication & Authorization)
    # --------------------------------------------------------------------------
    # Access entries for granting permissions to IAM principals (Users/Roles)
    access_entries = {
      admin_user = {
        principal_arn = "arn:aws:iam::516311263797:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_AdministratorAccess_5fe30505cf49ba4a"
        type          = "STANDARD"

        policy_associations = {
          admin = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = {
              type = "cluster"
            }
          }
        }
      }
    }

    # Enable IAM Roles for Service Accounts (IRSA) for fine-grained pod permissions
    enable_irsa = true

    # --------------------------------------------------------------------------
    # Logging & Encryption
    # --------------------------------------------------------------------------
    enable_cluster_logging = true
    create_kms_key         = false # Set to true to enable envelope encryption for Kubernetes secrets

    # --------------------------------------------------------------------------
    # Scaling & Reliability
    # --------------------------------------------------------------------------
    # Control Plane Scaling (Standard or High)
    control_plane_scaling_config = {
      tier = "standard"
    }

    # Zonal Shift (Automatic failover away from unhealthy AZs)
    zonal_shift_config = {
      enabled = true
    }

    # --------------------------------------------------------------------------
    # Maintenance & Upgrades
    # --------------------------------------------------------------------------
    upgrade_policy = {
      support_type = "STANDARD" # Options: STANDARD, EXTENDED
    }

    deletion_protection = false

    # --------------------------------------------------------------------------
    # Remote Network Configuration (EKS Hybrid Nodes support)
    # --------------------------------------------------------------------------
    # Uncomment and configure if using EKS Hybrid Nodes
    # remote_network_config = {
    #   remote_node_networks = {
    #     cidrs = ["10.0.0.0/8"]  # On-premises network CIDR
    #   }
    #   remote_pod_networks = {
    #     cidrs = ["172.30.0.0/16"]  # Pod network CIDR for hybrid nodes
    #   }
    # }

    # --------------------------------------------------------------------------
    # Node Groups Configuration
    # --------------------------------------------------------------------------
    managed_node_groups = {
      # Spot Instance Node Group (Cost-Optimized)
      spot_nodes = {
        name            = "dev-spot-nodes"
        use_name_prefix = true

        # Scaling Settings
        min_size     = 1
        max_size     = 2
        desired_size = 1

        # Instance Configuration
        capacity_type  = "SPOT"
        instance_types = ["t3a.medium"]
        ami_type       = "AL2023_x86_64_STANDARD"
        disk_size      = 25

        # Availability Settings
        update_config = {
          max_unavailable_percentage = 25
        }

        # Kubernetes Labels
        labels = {
          "node-type"     = "spot"
          "workload"      = "general"
          "capacity-type" = "spot"
          "environment"   = "dev"
          "managed"       = "true"
        }

        # Tags
        tags = {
          NodeGroup      = "spot-optimized"
          CostAllocation = "dev-spot"
        }

        # Storage Configuration
        create_launch_template = true
        block_device_mappings = {
          root = {
            device_name = "/dev/xvda"
            ebs = {
              volume_size           = 8
              volume_type           = "gp3"
              delete_on_termination = true
              encrypted             = true
              iops                  = 3000
              throughput            = 125
            }
          }
        }

        # IAM Configuration
        create_iam_role = true
        iam_role_additional_policies = {
          ssm_access = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        }
      }

      # NOTE: Example On-Demand Node Group (Uncomment to use)
      # dev_ondemand_nodes = {
      #   name            = "dev-ondemand-nodes"
      #   use_name_prefix = true
      #   min_size        = 1
      #   max_size        = 3
      #   desired_size    = 1
      #   capacity_type   = "ON_DEMAND"
      #   instance_types  = ["t3.medium"]
      #   ami_type        = "AL2023_x86_64_STANDARD"
      #   disk_size       = 30
      #   update_config   = { max_unavailable_percentage = 25 }
      #   labels          = { "node-type" = "ondemand", "workload" = "critical" }
      #   create_launch_template = true
      #   create_iam_role = true
      # }
    }

    # --------------------------------------------------------------------------
    # Cluster Add-ons
    # --------------------------------------------------------------------------
    cluster_addons = {
      vpc-cni = {
        addon_version               = "v1.20.4-eksbuild.1"
        resolve_conflicts_on_create = "OVERWRITE"
        resolve_conflicts_on_update = "OVERWRITE"
      }
      kube-proxy = {
        addon_version               = "v1.34.0-eksbuild.4"
        resolve_conflicts_on_create = "OVERWRITE"
        resolve_conflicts_on_update = "OVERWRITE"
      }
      coredns = {
        addon_version               = "v1.12.4-eksbuild.1"
        resolve_conflicts_on_create = "OVERWRITE"
        resolve_conflicts_on_update = "OVERWRITE"
      }
      eks-pod-identity-agent = {
        addon_version               = "v1.3.10-eksbuild.2"
        resolve_conflicts_on_create = "OVERWRITE"
        resolve_conflicts_on_update = "OVERWRITE"
      }
      aws-ebs-csi-driver = {
        addon_version = "v1.54.0-eksbuild.1"
        pod_identity_association = [{
          role_arn        = module.iam_roles["ebs-csi-driver-role"].role_arn
          service_account = "ebs-csi-controller-sa"
        }]
      }
    }

    # --------------------------------------------------------------------------
    # Global Tags
    # --------------------------------------------------------------------------
    tags = {
      Purpose = "EKS-Cluster"
    }
  }
}
