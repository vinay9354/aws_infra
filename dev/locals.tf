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