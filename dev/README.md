# AWS Infrastructure - Dev Environment

This directory contains Terraform configurations for the **Development** environment of the AWS infrastructure. It provisions core networking resources including VPC, subnets, and supporting infrastructure components.

## 📋 Overview

This Terraform configuration creates:
- **VPC**: A Virtual Private Cloud with CIDR block `172.20.0.0/16`
- **Internet Gateway**: For public subnet internet connectivity
- **Public Subnets**: Subnets with direct internet access via Internet Gateway
- **S3 Backend**: Terraform state storage with versioning and encryption
- **Route Tables**: Automatic routing configuration for each subnet

### Current Architecture

```
VPC (172.20.0.0/16)
├── Internet Gateway
└── Public Subnets
    ├── ec2-1 (172.20.0.0/24) - ap-south-1a
    └── ec2-2 (172.20.1.0/24) - ap-south-1b
```

## 🔧 Prerequisites

Before you begin, ensure you have:

1. **Terraform** installed (version ~> 1.14.1)
   ```bash
   terraform --version
   ```

2. **AWS CLI** configured with appropriate credentials
   ```bash
   aws configure
   ```

3. **AWS Account Access** with permissions to create:
   - VPC and networking resources
   - S3 buckets
   - IAM roles (if needed)

4. **S3 Bucket** for Terraform state (or it will be created on first run):
   - Bucket name: `vinay-terraform-state-dev`
   - Region: `ap-south-1`

## 📁 Project Structure

```
dev/
├── README.md              # This file
├── backend.tf             # S3 backend configuration for state management
├── main.tf                # Main infrastructure resources (VPC, subnets)
├── provider.tf            # AWS provider configuration
├── variables.tf           # Variable definitions
├── outputs.tf             # Output definitions
├── terraform.tfvars       # Variable values (environment-specific)
├── examples.tfvars        # Example variable configurations
└── locals.tf              # Local values (if any)
```

## 🚀 Getting Started

### 1. Initialize Terraform

Initialize the Terraform working directory and download required providers:

```bash
cd aws_infra/dev
terraform init
```

### 2. Review Configuration

Check the `terraform.tfvars` file to ensure variables are set correctly for your environment.

### 3. Plan the Changes

Generate and review an execution plan:

```bash
terraform plan
```

This will show you what resources will be created, modified, or destroyed.

### 4. Apply the Configuration

Create the infrastructure:

```bash
terraform apply
```

Type `yes` when prompted to confirm.

### 5. Verify Outputs

After successful apply, Terraform will display outputs like:
- VPC ID
- Internet Gateway ID
- Subnet IDs
- Route Table IDs

## 📝 Configuration

### Key Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `aws_region` | AWS region for resources | `ap-south-1` | No |
| `allowed_account_ids` | List of allowed AWS account IDs | `[]` | Yes |
| `environment` | Environment name | `dev` | No |
| `public_subnets` | Map of public subnet configurations | `{}` | Yes |
| `private_subnets` | Map of private subnet configurations | `{}` | No |

### Public Subnet Configuration

Each public subnet requires:
- `cidr_block`: CIDR block for the subnet (e.g., "172.20.0.0/24")
- `availability_zone`: AWS availability zone (e.g., "ap-south-1a")
- `extra_routes` (optional): Additional routes for the subnet
- `tags` (optional): Custom tags for the subnet
- `subnet_tags` (optional): Tags specifically for the subnet resource

**Example:**

```hcl
public_subnets = {
  ec2-1 = {
    cidr_block        = "172.20.0.0/24"
    availability_zone = "ap-south-1a"
    tags = {
      Tier    = "web"
      Purpose = "load-balancers"
    }
  }
}
```

### Private Subnet Configuration (Currently Commented Out)

To enable private subnets, uncomment the `private_subnets` module in `main.tf` and configure:
- All public subnet fields
- `nat_gateway_id`: NAT Gateway ID for outbound internet access

## 📤 Outputs

This configuration exports the following outputs:

| Output | Description |
|--------|-------------|
| `vpc_id` | ID of the created VPC |
| `igw_id` | ID of the Internet Gateway |
| `public_subnet_ids` | Map of public subnet IDs |
| `private_subnet_ids` | Map of private subnet IDs |
| `public_route_table_ids` | Map of public route table IDs |
| `private_route_table_ids` | Map of private route table IDs |

View outputs anytime with:
```bash
terraform output
```

## 🔄 Making Changes

### Adding a New Public Subnet

1. Edit `terraform.tfvars`
2. Add a new entry to `public_subnets` map:
   ```hcl
   public_subnets = {
     # ... existing subnets ...
     ec2-3 = {
       cidr_block        = "172.20.2.0/24"
       availability_zone = "ap-south-1c"
     }
   }
   ```
3. Run `terraform plan` and `terraform apply`

### Adding Custom Routes

Add `extra_routes` to any subnet configuration:

```hcl
public_subnets = {
  ec2-1 = {
    cidr_block        = "172.20.0.0/24"
    availability_zone = "ap-south-1a"
    extra_routes = [
      {
        destination_cidr_block = "10.0.0.0/8"
        target_type            = "tgw"
        target_id              = "tgw-xxxxxxxxxxxxx"
      }
    ]
  }
}
```

**Supported target types:**
- `igw` - Internet Gateway
- `natgw` - NAT Gateway
- `tgw` - Transit Gateway
- `pcx` - VPC Peering Connection
- `vpce` - VPC Endpoint

## 🗑️ Destroying Infrastructure

To destroy all resources created by this configuration:

```bash
terraform destroy
```

**⚠️ Warning:** This will permanently delete all resources. Use with caution in production environments.

## 🔒 Backend Configuration

Terraform state is stored remotely in an S3 bucket with the following features:
- **Bucket**: `vinay-terraform-state-dev`
- **Encryption**: Enabled
- **Versioning**: Enabled
- **State Locking**: Enabled via `use_lockfile`
- **Region**: `ap-south-1`

State file location: `s3://vinay-terraform-state-dev/aws_infra/dev/terraform.tfstate`

## 🏷️ Resource Tagging

All resources are automatically tagged with:
- `Owner`: vinay
- `Managed_by`: terraform
- `Environment`: dev

Additional tags can be added per subnet using the `tags` and `subnet_tags` variables.

## 🛠️ Troubleshooting

### Issue: `terraform init` fails

**Solution:** Ensure you have valid AWS credentials configured:
```bash
aws sts get-caller-identity
```

### Issue: S3 bucket doesn't exist

**Solution:** The backend module creates the bucket automatically. If it fails:
1. Comment out the `backend "s3"` block in `backend.tf`
2. Run `terraform init` and `terraform apply` to create the bucket
3. Uncomment the backend block
4. Run `terraform init -migrate-state` to migrate state to S3

### Issue: Subnet CIDR conflicts

**Solution:** Ensure all subnet CIDR blocks:
- Are within the VPC CIDR range (172.20.0.0/16)
- Don't overlap with each other
- Use valid subnet masks

### Issue: Account ID not allowed

**Solution:** Update `allowed_account_ids` in `terraform.tfvars` with your AWS account ID:
```bash
aws sts get-caller-identity --query Account --output text
```

## 📚 Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [Subnet Calculator](https://visualsubnetcalc.com/)

## 🤝 Contributing

When making changes:
1. Create a new branch
2. Make your changes
3. Run `terraform fmt` to format code
4. Run `terraform validate` to validate configuration
5. Test with `terraform plan`
6. Create a pull request

## 📧 Support

For questions or issues, contact the amaravinaykumar@gmail.com or create an issue in the repository.

---

**Last Updated:** 30th November 2025  
**Maintained By:** Vinay Datta  
**Terraform Version:** ~> 1.14.1  
**AWS Provider Version:** ~> 6.27.0