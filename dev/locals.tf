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
  }
}

# -------------------------
# EKS Cluster Locals
# -------------------------
locals {
  eks_cluster_config = {
    cluster_name           = "vinay-dev-infra-eks-cluster"
    cluster_version        = "1.34"
    subnet_ids             = [module.private_subnets["eks-1"].subnet_id, module.private_subnets["eks-2"].subnet_id, module.private_subnets["eks-3"].subnet_id]
    enable_cluster_logging = true

    # Endpoint access configuration
    cluster_endpoint_private_access      = true
    cluster_endpoint_public_access       = false
    cluster_endpoint_public_access_cidrs = []

    # IRSA (IAM Roles for Service Accounts)
    enable_irsa = true

    # KMS encryption
    create_kms_key = false

    deletion_protection = false

    # Control Plane Scaling Configuration
    control_plane_scaling_config = {
      tier = "standard"
    }

    # Zonal Shift Configuration (enables automatic shift during AZ events)
    zonal_shift_config = {
      enabled = true
    }

    # Upgrade Policy Configuration (STANDARD or EXTENDED support)
    upgrade_policy = {
      support_type = "STANDARD"
    }

    # Remote Network Configuration (for EKS Hybrid Nodes - optional)
    # Uncomment and configure if using EKS Hybrid Nodes
    # remote_network_config = {
    #   remote_node_networks = {
    #     cidrs = ["10.0.0.0/8"]  # On-premises network CIDR
    #   }
    #   remote_pod_networks = {
    #     cidrs = ["172.30.0.0/16"]  # Pod network CIDR for hybrid nodes
    #   }
    # }

    # Managed Node Groups with Spot Instances
    managed_node_groups = {
      # Spot instance node group - cost-optimized
      spot_nodes = {
        name            = "dev-spot-nodes"
        use_name_prefix = true

        # Scaling configuration
        min_size     = 1
        max_size     = 2
        desired_size = 1

        # Spot instance configuration
        capacity_type  = "SPOT"
        instance_types = ["t3a.medium", "t3.medium", "t2.medium"] # Multiple types for better availability

        # AMI and disk configuration
        ami_type  = "AL2023_x86_64_STANDARD"
        disk_size = 8

        # Update strategy
        update_config = {
          max_unavailable_percentage = 25
        }

        # Labels for workload scheduling
        labels = {
          "node-type"     = "spot"
          "workload"      = "general"
          "capacity-type" = "spot"
          "environment"   = "dev"
          "managed"       = "true"
        }

        # Taints (optional - use if you want dedicated spot node groups)
        # taints = [
        #   {
        #     key    = "spot"
        #     value  = "true"
        #     effect = "NoSchedule"
        #   }
        # ]

        # Tags
        tags = {
          NodeGroup      = "spot-optimized"
          CostAllocation = "dev-spot"
        }

        # Launch template configuration
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

        # IAM configuration
        create_iam_role = true
        iam_role_additional_policies = {
          # Add any additional policies needed for your workloads
        }
      }

      #   # Optional: On-demand node group for critical workloads
      #   dev_ondemand_nodes = {
      #     name            = "dev-ondemand-nodes"
      #     use_name_prefix = true

      #     # Scaling configuration
      #     min_size     = 0
      #     max_size     = 3
      #     desired_size = 1

      #     # On-demand instance configuration
      #     capacity_type  = "ON_DEMAND"
      #     instance_types = ["t3.medium"]

      #     # AMI and disk configuration
      #     ami_type  = "AL2023_x86_64_STANDARD"
      #     disk_size = 30

      #     # Update strategy
      #     update_config = {
      #       max_unavailable_percentage = 25
      #     }

      #     # Labels for workload scheduling
      #     labels = {
      #       "node-type"     = "ondemand"
      #       "workload"      = "critical"
      #       "capacity-type" = "ondemand"
      #       "environment"   = "dev"
      #     }

      #     # Taints
      #     taints = [
      #       {
      #         key    = "critical"
      #         value  = "true"
      #         effect = "NoSchedule"
      #       }
      #     ]

      #     # Tags
      #     tags = {
      #       NodeGroup      = "ondemand-critical"
      #       CostAllocation = "dev-ondemand"
      #     }

      #     # Launch template configuration
      #     create_launch_template = true
      #     block_device_mappings = {
      #       root = {
      #         device_name = "/dev/xvda"
      #         ebs = {
      #           volume_size           = 30
      #           volume_type           = "gp3"
      #           delete_on_termination = true
      #           encrypted             = true
      #           iops                  = 3000
      #           throughput            = 125
      #         }
      #       }
    }

    #     # IAM configuration
    #     create_iam_role = true
    #     iam_role_additional_policies = {
    #       # Add any additional policies needed for your workloads
    #     }
    #   }
    # }

    # EKS Add-ons configuration
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

      # ebs-csi-driver = {
      #   addon_version               = "v1.31.0-eksbuild.1"
      #   resolve_conflicts_on_create = "OVERWRITE"
      #   resolve_conflicts_on_update = "OVERWRITE"
      # }
    }

    # Tags for all resources
    tags = {
      Purpose = "EKS-Cluster"
    }
  }
}
