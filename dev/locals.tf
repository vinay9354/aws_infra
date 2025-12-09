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
        Usecase = "nat"
      }
    }

  }
}

