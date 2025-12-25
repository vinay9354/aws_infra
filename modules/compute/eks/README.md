# EKS Terraform Module

A comprehensive, production-grade Terraform module for provisioning Amazon EKS (Elastic Kubernetes Service) clusters on AWS. This module is designed with security, flexibility, and best practices as core principles, supporting multiple compute options, advanced networking, and modern Kubernetes access patterns.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Requirements](#requirements)
- [Module Inputs](#module-inputs)
- [Module Outputs](#module-outputs)
- [Usage Examples](#usage-examples)
- [Security Considerations](#security-considerations)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## Overview

This module provides a complete, opinionated implementation of AWS EKS with the following highlights:

- **Multi-compute support**: Managed Node Groups, Self-Managed Node Groups, and Fargate Profiles
- **Security-first design**: IMDSv2 enforcement, KMS encryption, least-privilege IAM roles, and network isolation
- **Modern access patterns**: EKS Access Entries API with optional legacy `aws-auth` ConfigMap support
- **IRSA ready**: Built-in OpenID Connect (OIDC) provider for IAM Roles for Service Accounts
- **Advanced networking**: IPv6 support, flexible subnet placement, and extensible security groups
- **Production-ready**: Comprehensive logging, monitoring, and high availability features

## Features

### Compute Options

#### Managed Node Groups
- **On-Demand and Spot instances** with automatic capacity management
- **Custom AMI support** for specialized workloads
- **Automatic scaling** with configurable min/max/desired sizes
- **Launch template integration** for advanced instance configuration
- **Update strategies** with configurable surge parameters
- **Taints and labels** for fine-grained pod scheduling

#### Self-Managed Node Groups
- **Complete control** over Auto Scaling Groups and EC2 instances
- **Mixed instance policies** for cost optimization
- **Windows support** with native EKS-optimized Windows AMIs
- **Custom user data** templates for Linux and Windows
- **Bootstrap customization** with extra arguments support
- **Dedicated IAM roles** per node group for security isolation

#### Fargate Profiles
- **Serverless pod execution** without managing EC2 instances
- **Namespace and label-based selectors** for automatic pod routing
- **Cost-effective** for batch jobs and ephemeral workloads
- **Dedicated pod execution roles** with fine-grained permissions

### Security

- **Least Privilege IAM**: Each node group (managed and self-managed) gets a dedicated IAM role, preventing lateral movement
- **IMDSv2 Enforcement**: All EC2 instances default to IMDSv2, mitigating SSRF attacks
- **Envelope Encryption**: Kubernetes Secrets encrypted at rest using AWS KMS
- **Network Isolation**: Configurable security groups with strict ingress/egress rules
- **Private/Public Access Control**: API endpoint access modes with optional CIDR restrictions
- **IRSA Support**: OpenID Connect provider for pod-level IAM credentials without credential sharing
- **Encryption by Default**: EBS volumes encrypted with optional custom KMS keys

### Networking

- **IPv4 and IPv6 Support**: Full dual-stack capability with automatic security group rule adjustments
- **Flexible Subnet Placement**: Separate control plane and data plane subnet configurations
- **Cluster Security Group**: Dedicated SG for control plane with customizable rules
- **Node Security Group**: Shared SG for all nodes with inter-node communication
- **Karpenter Integration**: Automatic resource tagging for Karpenter auto-discovery
- **Custom Rules**: Extensible security group architecture for complex networking requirements

### Access Management

- **EKS Access Entries**: Modern API-based cluster access management (replaces `aws-auth` ConfigMap)
- **Access Policies**: Fine-grained policy associations with namespace scoping
- **Cluster Creator Admin**: Automatic admin access for the Terraform execution identity
- **Legacy Support**: Optional `aws-auth` ConfigMap management for gradual migration
- **Multiple Identity Types**: Support for IAM users, roles, and service accounts

### Logging and Monitoring

- **CloudWatch Integration**: Automatic log group creation with configurable retention
- **Control Plane Logging**: All major log types (API, audit, authenticator, controllerManager, scheduler)
- **KMS Encryption**: Optional encryption of CloudWatch logs with customer-managed keys
- **Flexible Retention**: Customizable log retention periods for compliance

### Add-ons Management

- **EKS Add-ons**: Managed add-on lifecycle with conflict resolution strategies
- **Versioning Control**: Explicit version management for all add-ons (VPC CNI, CoreDNS, kube-proxy, etc.)
- **Configuration Overwrites**: YAML-based add-on configuration customization
- **Timeout Control**: Configurable create/update/delete timeouts for long-running add-ons
- **Service Account Integration**: Automatic service account role assignment for add-ons

## Quick Start

### Minimal Example

```hcl
module "eks" {
  source = "../../modules/compute/eks"

  cluster_name    = "my-cluster"
  cluster_version = "1.30"
  
  vpc_id    = aws_vpc.main.id
  subnet_ids = aws_subnet.private[*].id

  managed_node_groups = {
    general = {
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      instance_types = ["t3.medium"]
    }
  }

  tags = {
    Environment = "Production"
  }
}
```

### Accessing Your Cluster

```bash
# Update your kubeconfig
aws eks update-kubeconfig --name my-cluster --region us-east-1

# Verify connectivity
kubectl get nodes
kubectl get pods --all-namespaces
```

## Architecture

### Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     EKS Cluster                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │        EKS Control Plane (AWS Managed)               │   │
│  │  ┌─────────────┬──────────────┬─────────────┐        │   │
│  │  │   API       │  etcd        │  Controller │        │   │
│  │  │  Servers    │  (Encrypted) │  Manager    │        │   │
│  │  └─────────────┴──────────────┴─────────────┘        │   │
│  │                                                      │   │
│  │  Security: CloudWatch Logs, KMS Encryption           │   │
│  └──────────────────────────────────────────────────────┘   │
│         │                                                   │
│         ├─ Cluster Security Group (Control Plane SG)        │
│         │                                                   │
├─────────┼─────────────────────────────────────────────────┤ │
│         │         Data Plane (Your VPC)                     │
│         │                                                   │
│  ┌──────▼────────────────────────────────────────────┐      │
│  │  Node Security Group (Shared)                     │      │
│  │                                                   │      │
│  │  ┌──────────────┐  ┌──────────────┐               │      │
│  │  │   Managed    │  │   Managed    │               │      │
│  │  │  Node Group  │  │  Node Group  │               │      │
│  │  │  (On-Demand) │  │  (Spot)      │               │      │
│  │  ├──────────────┤  ├──────────────┤               │      │
│  │  │ • EC2 Inst.  │  │ • EC2 Inst.  │               │      │
│  │  │ • Kubelet    │  │ • Kubelet    │               │      │
│  │  │ • IAM Role   │  │ • IAM Role   │               │      │
│  │  │ • IMDSv2     │  │ • IMDSv2     │               │      │
│  │  └──────────────┘  └──────────────┘               │      │
│  │                                                   │      │
│  │  ┌──────────────┐  ┌──────────────┐               │      │
│  │  │Self-Managed  │  │   Fargate    │               │      │
│  │  │ Node Group   │  │   Profile    │               │      │
│  │  │(Windows)     │  │ (Serverless) │               │      │
│  │  ├──────────────┤  ├──────────────┤               │      │
│  │  │ • ASG        │  │ • Pods only  │               │      │
│  │  │ • Custom UDa │  │ • Managed by │               │      │
│  │  │ • IAM Role   │  │   AWS        │               │      │
│  │  └──────────────┘  └──────────────┘               │      │
│  │                                                   │      │
│  └───────────────────────────────────────────────────┘      │
│                                                             │
│  IRSA: OpenID Connect Provider for IAM Roles for SAs        │
│  Add-ons: VPC CNI, CoreDNS, kube-proxy (managed)            │
│  Logging: CloudWatch Log Group (/aws/eks/<name>/cluster)    │
│  Encryption: KMS key for Secrets and EBS volumes            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### IAM Role Structure

- **Cluster Role**: Grants EKS control plane permissions (AmazonEKSClusterPolicy, AmazonEKSVPCResourceController)
- **Managed Node Group Roles**: Dedicated IAM role per node group with:
  - AmazonEKSWorkerNodePolicy
  - AmazonEKS_CNI_Policy
  - AmazonEC2ContainerRegistryReadOnly
  - Custom policies via `iam_role_additional_policies`
- **Self-Managed Node Group Roles**: Same policies as managed groups, but independently managed
- **Fargate Pod Execution Role**: Permissions for running pods on Fargate with add-on support
- **OIDC Provider**: Enables IRSA for workload-specific permissions without credential sharing

## Requirements

| Name | Version |
|------|---------|
| **Terraform** | `~> 1.14.1` |
| **AWS Provider** | `~> 6.22.1` |
| **Kubernetes Provider** | `~> 3.0.1` |
| **TLS Provider** | `~> 4.1.0` |

### AWS Permissions

The identity executing Terraform must have permissions to create/manage:
- EKS Clusters and Node Groups
- EC2 Security Groups and Launch Templates
- IAM Roles and Policies
- KMS Keys (if creating encryption keys)
- CloudWatch Log Groups
- Auto Scaling Groups (for self-managed nodes)

### Infrastructure Requirements

- **VPC**: A properly configured VPC with internet access (NAT Gateway for private subnets)
- **Subnets**: Private subnets for control plane and data plane (public optional for NAT)
- **DNS Resolution**: AWS-provided DNS or custom DNS configured in VPC
- **Kubernetes CLI**: `kubectl` installed locally for cluster interaction

## Module Inputs

### Cluster Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `cluster_name` | Name of the EKS cluster (must be 1-100 characters, alphanumeric and hyphens) | `string` | n/a | **Yes** |
| `cluster_version` | Kubernetes version for the cluster (e.g., "1.30", "1.29") | `string` | `"1.34llama"` | No |
| `cluster_ip_family` | IP family for pod and service addresses (`ipv4` or `ipv6`) | `string` | `"ipv4"` | No |
| `cluster_service_ipv4_cidr` | CIDR block for Kubernetes service IPs (IPv4). If null, AWS assigns 10.100.0.0/16 or 172.20.0.0/16 | `string` | `null` | No |
| `cluster_service_ipv6_cidr` | CIDR block for Kubernetes pod and service IPs (IPv6, required if `cluster_ip_family = "ipv6"`) | `string` | `null` | No |
| `cluster_enabled_log_types` | List of control plane log types to enable (api, audit, authenticator, controllerManager, scheduler) | `list(string)` | `["api", "audit", "authenticator", "controllerManager", "scheduler"]` | No |
| `tags` | Tags to apply to all resources created by this module | `map(string)` | `{}` | No |

### Networking & VPC

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `vpc_id` | VPC ID where the cluster will be provisioned | `string` | n/a | **Yes** |
| `subnet_ids` | List of subnet IDs for cluster and node placement (fallback for both control plane and data plane) | `list(string)` | n/a | **Yes** |
| `control_plane_subnet_ids` | Specific subnet IDs for EKS control plane ENIs (overrides `subnet_ids` for control plane) | `list(string)` | `[]` | No |
| `node_group_subnet_ids` | Specific subnet IDs for node groups (overrides `subnet_ids` for data plane) | `list(string)` | `[]` | No |

**Subnet Selection Logic:**
```
Control Plane Subnets = control_plane_subnet_ids (if provided) → subnet_ids
Data Plane Subnets = node_group_subnet_ids (if provided) → subnet_ids
```

### API Endpoint Access

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `cluster_endpoint_public_access` | Enable public API endpoint (enables 0.0.0.0/0 unless restricted by CIDR) | `bool` | `true` | No |
| `cluster_endpoint_public_access_cidrs` | CIDR blocks allowed to access the public API endpoint | `list(string)` | `["0.0.0.0/0"]` | No |
| `cluster_endpoint_private_access` | Enable private API endpoint (for same-VPC access without internet routing) | `bool` | `true` | No |

**Endpoint Access Patterns:**
- **Public + Private** (default): Access from anywhere + internal access
- **Public only**: `cluster_endpoint_private_access = false`
- **Private only**: `cluster_endpoint_public_access = false`
- **Restricted public**: Set `cluster_endpoint_public_access_cidrs = ["203.0.113.0/24"]`

### Security Groups

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `create_cluster_security_group` | Create a new security group for the control plane (set false to provide existing) | `bool` | `true` | No |
| `cluster_security_group_id` | Existing security group ID for control plane (required if `create_cluster_security_group = false`) | `string` | `""` | No |
| `cluster_additional_security_group_ids` | Additional existing security groups to attach to the control plane | `list(string)` | `[]` | No |
| `cluster_security_group_additional_rules` | Custom security group rules to add to the cluster security group | `map(object)` | `{}` | No |
| `node_security_group_additional_rules` | Custom security group rules to add to the node security group | `map(object)` | `{}` | No |
| `node_security_group_enable_recommended_rules` | Enable default recommended rules for nodes (egress to 0.0.0.0/0). Set false for strict outbound control | `bool` | `true` | No |

**Security Group Rule Schema:**
```hcl
{
  type                     = "ingress" or "egress"
  from_port                = number
  to_port                  = number
  protocol                 = "tcp", "udp", "-1" (all), etc.
  cidr_blocks              = optional(list(string))
  source_security_group_id = optional(string)
  description              = optional(string)
}
```

### Encryption (KMS)

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `create_kms_key` | Create a new KMS key for cluster encryption | `bool` | `false` | No |
| `kms_key_arn` | ARN of an existing KMS key for encryption (uses customer-managed key instead of AWS-managed) | `string` | `null` | No |
| `kms_key_description` | Human-readable description for the KMS key (if creating) | `string` | `"EKS Cluster Encryption Key"` | No |
| `kms_key_administrators` | List of IAM ARNs with administrative permissions on the KMS key | `list(string)` | `[]` | No |
| `kms_key_deletion_window_in_days` | Days to wait before deleting the KMS key after scheduling deletion | `number` | `30` | No |

**Encryption Scope:**
- Kubernetes Secrets at rest in etcd
- EBS volumes on EC2 nodes
- CloudWatch logs (optional)

### Logging

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `cloudwatch_log_group_retention_in_days` | CloudWatch log retention period in days (0 = indefinite) | `number` | `90` | No |
| `cloudwatch_log_group_kms_key_id` | KMS key ID for encrypting CloudWatch logs (ARN format) | `string` | `null` | No |

### Compute Configuration

#### Managed Node Groups

| Name | Description | Type |
|------|-------------|------|
| `managed_node_groups` | Map of managed node group configurations | `map(object({...}))` |

**Schema for each managed node group:**
```hcl
{
  name            = optional(string)              # Name of the node group (auto-generated if null)
  use_name_prefix = optional(bool, true)          # Use name as prefix for uniqueness
  
  # Scaling
  min_size        = optional(number, 1)           # Minimum instances
  max_size        = optional(number, 3)           # Maximum instances
  desired_size    = optional(number, 1)           # Desired number of instances
  
  # Instance Configuration
  ami_type        = optional(string, "AL2_x86_64") # AMI type (AL2_x86_64, AL2_x86_64_GPU, etc.)
  ami_id          = optional(string)               # Custom AMI ID (overrides ami_type)
  instance_types  = optional(list(string), ["t3.medium"]) # EC2 instance types
  capacity_type   = optional(string, "ON_DEMAND") # ON_DEMAND or SPOT
  disk_size       = optional(number, 20)          # Root EBS volume size in GB
  
  # Update Strategy
  update_config = optional(object({
    max_unavailable            = optional(number)     # Max instances to update simultaneously
    max_unavailable_percentage = optional(number)     # Alternative: percentage of group
  }))
  
  # Kubernetes Configuration
  labels          = optional(map(string), {})     # Pod scheduling labels
  taints = optional(list(object({
    key    = string                                # Taint key
    value  = string                                # Taint value
    effect = string                                # NoSchedule, PreferNoSchedule, NoExecute
  })), [])
  
  # Launch Template
  create_launch_template = optional(bool, true)   # Create dedicated launch template
  launch_template_name   = optional(string)       # Custom launch template name
  block_device_mappings  = optional(any, {})      # Advanced EBS configuration
  
  # IAM
  create_iam_role              = optional(bool, true)     # Create role (set false to provide arn)
  iam_role_arn                 = optional(string)         # Existing IAM role ARN
  iam_role_additional_policies = optional(map(string), {}) # Additional policy ARNs to attach
  
  tags = optional(map(string), {})                # Node group-specific tags
}
```

**Examples:**
```hcl
# On-Demand general purpose nodes
general = {
  min_size       = 1
  max_size       = 5
  desired_size   = 2
  instance_types = ["t3.large", "t3a.large"]
  labels         = { workload = "general" }
}

# Spot instances for cost savings (tainted to prevent accidental scheduling)
spot_workers = {
  min_size       = 2
  max_size       = 10
  desired_size   = 5
  instance_types = ["m5.large", "m5a.large", "m6i.large"]
  capacity_type  = "SPOT"
  taints = [{
    key    = "spot"
    value  = "true"
    effect = "NoSchedule"
  }]
  labels = { workload = "spot" }
}

# GPU nodes with custom AMI
gpu = {
  min_size       = 0
  max_size       = 2
  desired_size   = 0
  instance_types = ["g4dn.xlarge"]
  ami_type       = "AL2_x86_64_GPU"
  labels         = { accelerator = "gpu" }
  taints = [{
    key    = "nvidia.com/gpu"
    value  = "true"
    effect = "NoSchedule"
  }]
}
```

#### Self-Managed Node Groups

| Name | Description | Type |
|------|-------------|------|
| `self_managed_node_groups` | Map of self-managed node group configurations | `map(object({...}))` |

**Schema for each self-managed node group:**
```hcl
{
  name            = optional(string)              # Name of the Auto Scaling Group
  use_name_prefix = optional(bool, true)          # Use name as prefix for uniqueness
  
  # Scaling
  min_size           = optional(number, 1)        # Minimum instances
  max_size           = optional(number, 3)        # Maximum instances
  desired_capacity   = optional(number, 1)        # Desired number of instances
  
  # Instance Configuration
  instance_type      = optional(string, "t3.medium") # Single instance type
  ami_id             = optional(string)           # Custom AMI (null = default optimized AMI)
  key_name           = optional(string)           # EC2 key pair name for SSH access
  
  # Bootstrap & User Data
  platform           = optional(string, "linux")  # "linux" or "windows"
  bootstrap_extra_args = optional(string, "")     # Extra kubelet args (e.g., labels, taints)
  user_data_template_path = optional(string)      # Custom user data template file path
  
  # Block Devices
  block_device_mappings = optional(any, {})       # Advanced EBS configuration
  
  # IAM
  create_iam_role              = optional(bool, true)     # Create role
  iam_role_arn                 = optional(string)         # Existing IAM role ARN
  iam_role_additional_policies = optional(map(string), {}) # Additional policies
  
  tags = optional(map(string), {})                # Node-specific tags
}
```

**Examples:**
```hcl
# Linux nodes with custom bootstrap
linux_custom = {
  min_size           = 1
  max_size           = 3
  desired_capacity   = 1
  instance_type      = "m5.large"
  key_name           = "my-ec2-key"
  bootstrap_extra_args = "--kubelet-extra-args '--max-pods=110'"
}

# Windows nodes (always requires platform = "windows")
windows_workers = {
  min_size           = 0
  max_size           = 2
  desired_capacity   = 0
  instance_type      = "t3.xlarge"
  platform           = "windows"
  # Windows will use Windows-optimized EKS AMI
}

# Budget-friendly with spot (note: requires mixed instances policy in ASG config)
budget_nodes = {
  min_size           = 2
  max_size           = 5
  desired_capacity   = 2
  instance_type      = "t3.large"
  bootstrap_extra_args = "--kubelet-extra-args '--eviction-hard=memory.available<5%'"
}
```

#### Fargate Profiles

| Name | Description | Type |
|------|-------------|------|
| `fargate_profiles` | Map of Fargate profile configurations | `map(object({...}))` |

**Schema for each Fargate profile:**
```hcl
{
  name = string                                   # Profile name (required)
  
  selectors = list(object({
    namespace = string                            # Kubernetes namespace to match
    labels    = optional(map(string))             # Optional label selector
  }))
  
  # Networking
  subnet_ids = optional(list(string))             # Fargate pod subnet IDs (defaults to node_group_subnet_ids)
  
  # IAM
  create_iam_role              = optional(bool, true)     # Create pod execution role
  iam_role_arn                 = optional(string)         # Existing IAM role ARN
  iam_role_additional_policies = optional(map(string), {}) # Additional policies
  
  tags = optional(map(string), {})                # Profile-specific tags
}
```

**Examples:**
```hcl
# Route backend apps to Fargate
backend = {
  name = "backend-profile"
  selectors = [
    {
      namespace = "backend-apps"
      labels    = { env = "prod" }
    }
  ]
}

# Separate Fargate profile for batch jobs
batch = {
  name = "batch-jobs"
  selectors = [
    {
      namespace = "batch"
    }
  ]
}
```

### Add-ons

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `cluster_addons` | Map of EKS cluster add-ons to manage | `map(object)` | `{}` | No |

**Schema for each add-on:**
```hcl
{
  addon_version              = optional(string)    # Add-on version (null = use latest)
  resolve_conflicts_on_create = optional(string, "OVERWRITE") # OVERWRITE or PRESERVE
  resolve_conflicts_on_update = optional(string, "OVERWRITE") # OVERWRITE or PRESERVE
  configuration_values       = optional(string)    # YAML configuration values
  service_account_role_arn   = optional(string)    # IAM role for service account (IRSA)
  preserve                   = optional(bool, false) # Preserve on cluster deletion
  
  timeouts = optional(object({
    create = optional(string)                      # Create timeout (e.g., "10m")
    update = optional(string)                      # Update timeout
    delete = optional(string)                      # Delete timeout
  }))
}
```

**Common Add-ons:**
```hcl
cluster_addons = {
  # VPC CNI - Required for pod networking
  vpc-cni = {
    addon_version = "v1.14.0"
    service_account_role_arn = aws_iam_role.vpc_cni.arn
  }
  
  # CoreDNS - Kubernetes DNS
  coredns = {
    addon_version = "v1.10.1"
  }
  
  # kube-proxy - Kubernetes network proxy
  kube-proxy = {
    addon_version = "v1.28.1"
  }
  
  # EBS CSI Driver - For persistent volumes
  aws-ebs-csi-driver = {
    addon_version = "v1.24.0"
    service_account_role_arn = aws_iam_role.ebs_csi.arn
  }
  
  # EFS CSI Driver
  aws-efs-csi-driver = {
    addon_version = "v1.7.0"
    service_account_role_arn = aws_iam_role.efs_csi.arn
  }
}
```

### Access Control

#### EKS Access Entries (Modern)

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `access_entries` | Map of EKS Access Entries for cluster access | `map(object)` | `{}` | No |
| `enable_cluster_creator_admin_permissions` | Automatically grant admin to the Terraform execution identity | `bool` | `true` | No |

**Schema for each access entry:**
```hcl
{
  principal_arn      = string                     # ARN of IAM user/role (required)
  kubernetes_groups  = optional(list(string), []) # K8s groups for RBAC
  type               = optional(string, "STANDARD") # STANDARD, EC2_LINUX, EC2_WINDOWS, FARGATE_LINUX, FARGATE_WINDOWS
  user_name          = optional(string)           # Custom username for the entry
  
  policy_associations = optional(map(object({
    policy_arn = string                           # ARN of the access policy
    access_scope = object({
      type       = string                         # "cluster" or "namespace"
      namespaces = optional(list(string))         # Namespace list if type = "namespace"
    })
  })), {})
}
```

**Examples:**
```hcl
access_entries = {
  # Admin user
  admin_user = {
    principal_arn = "arn:aws:iam::123456789012:user/admin"
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
  
  # Developer with namespace access
  developer = {
    principal_arn = "arn:aws:iam::123456789012:role/DeveloperRole"
    type          = "STANDARD"
    
    policy_associations = {
      developer = {
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
        access_scope = {
          type       = "namespace"
          namespaces = ["development"]
        }
      }
    }
  }
}
```

#### Legacy AWS Auth ConfigMap

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `manage_aws_auth_configmap` | Manage the legacy aws-auth ConfigMap (requires Kubernetes provider configured) | `bool` | `false` | No |
| `aws_auth_roles` | List of IAM roles to add to aws-auth | `list(object)` | `[]` | No |
| `aws_auth_users` | List of IAM users to add to aws-auth | `list(object)` | `[]` | No |
| `aws_auth_accounts` | List of AWS account IDs to add to aws-auth | `list(string)` | `[]` | No |

### IRSA (IAM Roles for Service Accounts)

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `enable_irsa` | Create OpenID Connect provider for IRSA (IAM Roles for Service Accounts) | `bool` | `true` | No |

### Integration & Discovery

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `enable_karpenter` | Tag resources for Karpenter auto-discovery (security groups, subnets) | `bool` | `false` | No |

## Module Outputs

### Cluster Outputs

| Name | Description |
|------|-------------|
| `cluster_name` | The name of the EKS cluster |
| `cluster_id` | The ID of the EKS cluster |
| `cluster_arn` | The Amazon Resource Name (ARN) of the cluster |
| `cluster_endpoint` | The endpoint for the EKS cluster API server (for kubeconfig) |
| `cluster_certificate_authority_data` | Base64 encoded CA certificate data for cluster authentication |
| `cluster_version` | The Kubernetes server version of the cluster |
| `cluster_platform_version` | AWS platform version (e.g., eks.1) |
| `cluster_status` | Current status of the cluster (CREATING, ACTIVE, DELETING, FAILED) |

### Security Outputs

| Name | Description |
|------|-------------|
| `cluster_primary_security_group_id` | The AWS-managed security group (created automatically by EKS) |
| `cluster_security_group_id` | The custom cluster security group (created by this module) |
| `node_security_group_id` | The shared node security group ID |

### Authentication & Authorization Outputs

| Name | Description |
|------|-------------|
| `cluster_oidc_issuer_url` | The complete OIDC issuer URL for IRSA |
| `oidc_provider` | The OIDC provider identifier (URL without https://) |
| `oidc_provider_arn` | The ARN of the OIDC provider resource |

### IAM Outputs

| Name | Description |
|------|-------------|
| `cluster_iam_role_name` | IAM role name for the EKS cluster control plane |
| `cluster_iam_role_arn` | IAM role ARN for the EKS cluster control plane |
| `managed_node_group_iam_role_arns` | Map of IAM role ARNs for each managed node group |
| `self_managed_node_group_iam_role_arns` | Map of IAM role ARNs for each self-managed node group |

### Compute Resource Outputs

| Name | Description |
|------|-------------|
| `managed_node_groups` | Map of all managed node group resources and their attributes |
| `managed_node_groups_autoscaling_group_names` | List of ASG names created by managed node groups |
| `self_managed_node_groups` | Map of all self-managed ASG resources |
| `fargate_profiles` | Map of all Fargate profile resources |

### Logging & Encryption Outputs

| Name | Description |
|------|-------------|
| `kms_key_arn` | The ARN of the KMS key used for cluster encryption |
| `cloudwatch_log_group_arn` | The ARN of the CloudWatch log group |

### Helper Outputs

| Name | Description |
|------|-------------|
| `kubeconfig_command` | Ready-to-run AWS CLI command to update local kubeconfig |

## Usage Examples

### Example 1: Production-Grade Cluster with Mixed Compute

```hcl
locals {
  cluster_name = "prod-eks"
  environment  = "production"
  region       = "us-east-1"
}

module "eks" {
  source = "../../modules/compute/eks"

  # Cluster Configuration
  cluster_name    = local.cluster_name
  cluster_version = "1.30"
  
  # Networking
  vpc_id = aws_vpc.main.id
  subnet_ids = concat(
    aws_subnet.private_a[*].id,
    aws_subnet.private_b[*].id,
    aws_subnet.private_c[*].id
  )
  
  # API Access (restrict to corporate network)
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = ["203.0.113.0/24", "198.51.100.0/24"]
  cluster_endpoint_private_access      = true
  
  # Security & Encryption
  create_kms_key              = true
  kms_key_administrators      = [aws_iam_role.devops_admin.arn]
  cloudwatch_log_group_retention_in_days = 90
  
  # Managed Node Groups
  managed_node_groups = {
    # General purpose on-demand nodes
    general = {
      min_size       = 2
      max_size       = 6
      desired_size   = 3
      instance_types = ["t3.xlarge", "t3a.xlarge"]
      capacity_type  = "ON_DEMAND"
      labels         = { role = "general", workload = "mixed" }
      
      iam_role_additional_policies = {
        S3Access = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
      }
    }
    
    # Spot instances for cost efficiency
    spot = {
      min_size       = 2
      max_size       = 10
      desired_size   = 3
      instance_types = ["m5.large", "m5a.large", "m6i.large", "c5.large"]
      capacity_type  = "SPOT"
      labels         = { role = "spot", workload = "batch" }
      
      taints = [{
        key    = "spot"
        value  = "true"
        effect = "NoSchedule"
      }]
    }
  }
  
  # Fargate for stateless workloads
  fargate_profiles = {
    core_services = {
      name = "core-services"
      selectors = [
        {
          namespace = "kube-system"
        },
        {
          namespace = "monitoring"
        }
      ]
    }
  }
  
  # EKS Add-ons
  cluster_addons = {
    vpc-cni = {
      addon_version            = "v1.14.0"
      resolve_conflicts_on_create = "OVERWRITE"
    }
    coredns = {
      addon_version = "v1.10.1"
    }
    kube-proxy = {
      addon_version = "v1.28.1"
    }
    aws-ebs-csi-driver = {
      addon_version = "v1.24.0"
    }
  }
  
  # Access Control
  enable_irsa                             = true
  enable_cluster_creator_admin_permissions = true
  
  access_entries = {
    platform_admin = {
      principal_arn = aws_iam_role.platform_admin.arn
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
    
    app_developers = {
      principal_arn = aws_iam_role.developers.arn
      type          = "STANDARD"
      
      policy_associations = {
        edit = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
          access_scope = {
            type       = "namespace"
            namespaces = ["default", "development"]
          }
        }
      }
    }
  }
  
  # Karpenter Integration
  enable_karpenter = true
  
  # Tags
  tags = {
    Environment = local.environment
    Terraform   = "true"
    ManagedBy   = "Platform Team"
  }
}

# Output for reference
output "cluster_name" {
  value = module.eks.cluster_name
}

output "kubeconfig_command" {
  value = module.eks.kubeconfig_command
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}
```

### Example 2: Windows Node Cluster

```hcl
module "eks_windows" {
  source = "../../modules/compute/eks"

  cluster_name    = "windows-cluster"
  cluster_version = "1.28"
  
  vpc_id    = aws_vpc.main.id
  subnet_ids = aws_subnet.private[*].id
  
  # Linux nodes (required for core services)
  managed_node_groups = {
    core_linux = {
      min_size       = 1
      max_size       = 2
      desired_size   = 1
      instance_types = ["t3.medium"]
      labels         = { role = "linux-core" }
    }
  }
  
  # Windows nodes (self-managed for more control)
  self_managed_node_groups = {
    windows = {
      name               = "windows-workers"
      platform           = "windows" # REQUIRED
      min_size           = 1
      max_size           = 3
      desired_capacity   = 1
      instance_type      = "t3.xlarge"
      key_name           = "my-ec2-key"
      bootstrap_extra_args = "-KubeletExtraArgs '--node-labels=os=windows,workload=dotnet'"
    }
  }
  
  tags = {
    WorkloadType = "Windows"
  }
}
```

### Example 3: IPv6 Cluster

```hcl
module "eks_ipv6" {
  source = "../../modules/compute/eks"

  cluster_name         = "ipv6-cluster"
  cluster_ip_family    = "ipv6"
  cluster_service_ipv6_cidr = "fd00:100::/108"
  
  # Ensure VPC and subnets are IPv6 enabled
  vpc_id    = aws_vpc.ipv6_vpc.id
  subnet_ids = aws_subnet.ipv6_subnets[*].id
  
  managed_node_groups = {
    ipv6_nodes = {
      min_size       = 2
      max_size       = 4
      desired_size   = 2
      instance_types = ["t3.large"]
    }
  }
}
```

### Example 4: Minimal Development Cluster

```hcl
module "eks_dev" {
  source = "../../modules/compute/eks"

  cluster_name = "dev-cluster"
  vpc_id       = aws_vpc.dev.id
  subnet_ids   = aws_subnet.dev_private[*].id
  
  managed_node_groups = {
    dev = {
      min_size       = 1
      max_size       = 2
      desired_size   = 1
      instance_types = ["t3.medium"]
    }
  }
}
```

## Security Considerations

### 1. **Least Privilege IAM Roles**

This module creates **dedicated IAM roles for each node group**, preventing lateral movement between groups:

```
✓ Node Group A → Role A (can assume only Role A)
✓ Node Group B → Role B (can assume only Role B)
✗ Cross-group: Role A cannot assume Role B
```

**Best Practice**: Attach service-specific policies only to required roles:

```hcl
iam_role_additional_policies = {
  S3ReadOnly   = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  DynamoDBRead = "arn:aws:iam::123456789012:policy/DynamoDB-ReadOnly"
}
```

### 2. **IMDSv2 Enforcement**

All instances (managed and self-managed) default to **IMDSv2-only**, preventing SSRF token theft:

- Requires request signing (instance metadata API calls must be authenticated)
- Hop limit set to 2 (prevents container escape to metadata service)
- Default everywhere; no opt-in required

### 3. **Encryption at Rest**

- **Kubernetes Secrets**: Use `create_kms_key = true` for envelope encryption in etcd
- **EBS Volumes**: Automatically encrypted with gp3 volumes
- **CloudWatch Logs**: Optional KMS encryption via `cloudwatch_log_group_kms_key_id`

### 4. **Network Isolation**

- **Security Groups**: Cluster and node security groups restrict traffic
- **Private/Public Access**: Disable public API endpoint for air-gapped clusters
- **CIDR Restrictions**: Use `cluster_endpoint_public_access_cidrs` to limit API access
- **IPv6 Support**: Security rules automatically adjust for IPv6 traffic

### 5. **IRSA (IAM Roles for Service Accounts)**

Instead of sharing node credentials, use IRSA for pod-level permissions:

```bash
# Set up workload identity for ExternalDNS
kubectl annotate serviceaccount external-dns -n kube-system \
  eks.amazonaws.com/role-arn=arn:aws:iam::ACCOUNT_ID:role/external-dns-role
```

### 6. **API Endpoint Access**

Default configuration allows public access. For production:

```hcl
# Option 1: Restrict to IP ranges
cluster_endpoint_public_access       = true
cluster_endpoint_public_access_cidrs = ["203.0.113.0/24"]

# Option 2: Private-only (requires VPN or bastion)
cluster_endpoint_public_access  = false
cluster_endpoint_private_access = true
```

### 7. **Node Authentication**

- **Access Entries**: Modern, recommended approach (uses EKS API)
- **aws-auth ConfigMap**: Legacy fallback for gradual migration
- **Avoid**: Never hardcode AWS credentials in containers

## Best Practices

### 1. **Use Multiple Node Groups**

Separate concerns by workload type:

```hcl
managed_node_groups = {
  system     = { ... }  # core services
  general    = { ... }  # standard workloads
  compute    = { ... }  # CPU-intensive jobs
  memory     = { ... }  # high-memory applications
  spot       = { ... }  # batch/interruption-tolerant
}
```

### 2. **Implement Pod Disruption Budgets**

Protect critical workloads during node updates:

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: critical-service
spec:
  minAvailable: 2
  selector:
    matchLabels:
      tier: critical
```

### 3. **Set Resource Requests and Limits**

Improve scheduling and prevent resource starvation:

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### 4. **Use Taints and Tolerations**

Ensure workloads land on appropriate nodes:

```hcl
# Node configuration
taints = [{
  key    = "gpu"
  value  = "true"
  effect = "NoSchedule"
}]

# Pod configuration
tolerations:
- key: "gpu"
  operator: "Equal"
  value: "true"
  effect: "NoSchedule"
```

### 5. **Enable Horizontal Pod Autoscaling (HPA)**

Scale pods based on metrics:

```bash
kubectl autoscale deployment myapp --min=2 --max=10 --cpu-percent=80
```

### 6. **Monitor Cluster Health**

Set up CloudWatch alarms for:
- Node status (Ready/NotReady)
- Pod eviction rates
- API latency
- etcd database size

### 7. **Implement Network Policies**

Restrict pod-to-pod traffic:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: frontend
```

### 8. **Use Spot Instances Wisely**

Great for non-critical workloads, but implement:

```hcl
spot = {
  capacity_type = "SPOT"
  taints = [{
    key    = "spot"
    value  = "true"
    effect = "NoSchedule"
  }]
}

# With pod priorityClass for graceful handling
```

### 9. **Upgrade Strategy**

Plan cluster upgrades with multiple node groups:

```bash
# 1. Upgrade managed node group 1
# 2. Monitor workload migration
# 3. Upgrade managed node group 2
# 4. Verify all pods running
```

### 10. **Backup and Disaster Recovery**

- Use persistent volumes with snapshots
- Backup `kubectl` resource manifests to Git
- Test failover procedures regularly

## Troubleshooting

### Common Issues

#### Issue: Nodes failing to join cluster

**Symptoms**: Nodes in "NotReady" state, kubelet logs showing auth errors

**Solutions**:
1. Check security group rules allow control plane → node communication (port 443)
2. Verify IAM role has proper permissions attached
3. Check user data logs: `tail -f /var/log/cloud-init-output.log` (Linux) or `Get-Content 'C:\ProgramData\Amazon\EC2Launch\log\agent.log'` (Windows)
4. Ensure cluster version matches node AMI version

#### Issue: Pods pending indefinitely

**Symptoms**: `kubectl get pods` shows Pending pods

**Solutions**:
1. Check node capacity: `kubectl describe nodes`
2. Verify node selectors/taints match pod tolerations
3. Check resource requests vs available capacity
4. Inspect events: `kubectl describe pod <pod-name>`

#### Issue: IRSA not working

**Symptoms**: Pods cannot assume IAM roles despite service account annotation

**Solutions**:
1. Verify OIDC provider exists: `aws iam list-open-id-connect-providers`
2. Check service account annotation: `kubectl describe sa <sa-name> -n <namespace>`
3. Verify IAM role trust policy includes correct OIDC provider
4. Check pod logs for credential fetch errors

#### Issue: API endpoint timeout

**Symptoms**: `kubectl` commands timeout or connection refused

**Solutions**:
1. Check security group allows your IP to port 443
2. Verify `cluster_endpoint_public_access_cidrs` includes your IP
3. Test connectivity: `curl -k https://<cluster-endpoint>` (should fail with auth error, not timeout)
4. Check cluster status in AWS console (should be "Active")

#### Issue: Windows nodes not ready

**Symptoms**: Windows nodes stuck in NotReady state

**Solutions**:
1. Windows nodes need 5-10 minutes to boot; check CloudWatch logs
2. Verify Windows AMI is compatible with cluster version
3. Ensure t3.large or larger instance type (Windows is resource-heavy)
4. Check that subnets have outbound internet access (NAT Gateway)

### Debugging Commands

```bash
# Check cluster status
aws eks describe-cluster --name <cluster-name> --region <region>

# Get node status
kubectl get nodes -o wide

# Check node events
kubectl describe node <node-name>

# View kubelet logs (SSH to node)
journalctl -u kubelet -f

# Check security group rules
aws ec2 describe-security-groups --group-ids <sg-id>

# View CloudWatch logs
aws logs tail /aws/eks/<cluster-name>/cluster --follow

# Test API connectivity
kubectl cluster-info
kubectl get all --all-namespaces
```

## License

Apache 2 Licensed. See LICENSE for full details.

## Authors

Module developed and maintained by Vinay Datta.

---

## Additional Resources

- [AWS EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS EKS User Guide](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
