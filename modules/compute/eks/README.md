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
  - [Example 1: Production-Grade Cluster with Mixed Compute](#example-1-production-grade-cluster-with-mixed-compute)
  - [Example 2: Windows Node Cluster](#example-2-windows-node-cluster)
  - [Example 3: IPv6 Cluster](#example-3-ipv6-cluster)
  - [Example 4: Minimal Development Cluster](#example-4-minimal-development-cluster)
  - [Example 5: EKS Pod Identity with Service Accounts](#example-5-eks-pod-identity-with-service-accounts)
  - [Example 6: Highly Available Production Cluster with Advanced Features](#example-6-highly-available-production-cluster-with-advanced-features)
  - [Example 7: Cost-Optimized Cluster with Spot Instances and Autoscaling](#example-7-cost-optimized-cluster-with-spot-instances-and-autoscaling)
  - [Example 8: GPU-Enabled Cluster for ML Workloads](#example-8-gpu-enabled-cluster-for-ml-workloads)
  - [Example 9: EKS Hybrid Nodes (On-Premises + AWS)](#example-9-eks-hybrid-nodes-on-premises--aws)
  - [Example 10: Enterprise Multi-Tenant Cluster with Security Hardening](#example-10-enterprise-multi-tenant-cluster-with-security-hardening)
- [Security Considerations](#security-considerations)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)
- [Recent Updates](#recent-updates)
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
- **Smart Dependency Management**: VPC CNI created before node groups (required for pod networking), other add-ons created after nodes exist
- **Pod Identity Associations**: Direct service account to IAM role bindings via native EKS Pod Identity

### Pod Identity

- **EKS Pod Identity**: Native AWS solution for pod-level IAM credentials (alternative to IRSA)
- **Service Account Binding**: Automatic association between Kubernetes service accounts and IAM roles
- **No annotations required**: Unlike IRSA, Pod Identity doesn't require service account annotations
- **Fine-grained Access**: Pod-specific permissions without node-level credential sharing
- **Seamless Integration**: Works alongside traditional IRSA for gradual migration



### Advanced Cluster Features

- **Control Plane Scaling**: Dynamic tier upgrades (standard, tier-xl, tier-2xl, tier-4xl) for performance and availability
- **Zonal Shift**: Automatic traffic shifting away from affected availability zones during events
- **EKS Hybrid Nodes**: Connect on-premises infrastructure and external nodes to your EKS cluster
- **Extended Support**: Choose between standard (14-month) and extended (24-month) support windows for cluster versions

## Quick Start

### Minimal Example

```hcl
module "eks" {
  source = "../../modules/compute/eks"

  cluster_name    = "my-cluster"
  cluster_version = "1.34"
  
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
| **AWS Provider** | `~> 6.27.0` |
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
| `cluster_version` | Kubernetes version for the cluster (e.g., "1.34", "1.30") | `string` | `"1.34"` | No |
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
| `cluster_endpoint_public_access` | Enable public API endpoint (enables 0.0.0.0/0 unless restricted by CIDR) | `bool` | `false` | No |
| `cluster_endpoint_public_access_cidrs` | CIDR blocks allowed to access the public API endpoint | `list(string)` | `[]` | No |
| `cluster_endpoint_private_access` | Enable private API endpoint (for same-VPC access without internet routing) | `bool` | `true` | No |

**Endpoint Access Patterns:**
- **Private only** (default): Private API endpoint enabled, public access disabled
- **Private + Public**: `cluster_endpoint_public_access = true` and set `cluster_endpoint_public_access_cidrs` (e.g., `["0.0.0.0/0"]`)
- **Public only**: `cluster_endpoint_private_access = false, cluster_endpoint_public_access = true`
- **Restricted public**: Set `cluster_endpoint_public_access = true` and `cluster_endpoint_public_access_cidrs = ["203.0.113.0/24"]`

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
  ami_type        = optional(string, "AL2023_x86_64_STANDARD") # AMI type (AL2023_x86_64_STANDARD, AL2023_x86_64_GPU, etc.)
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

#### Pod Identity Associations

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `pod_identity_associations` | Map of EKS Pod Identity Associations to create for workload authentication without sharing node credentials | `map(object)` | `{}` | No |

**Schema for each pod identity association:**
```hcl
{
  namespace       = string     # Kubernetes namespace where the service account resides (required)
  service_account = string     # Service account name (required)
  role_arn        = string     # IAM role ARN to associate with the service account (required)
}
```

**Example:**
```hcl
pod_identity_associations = {
  ebs_csi = {
    namespace       = "kube-system"
    service_account = "ebs-csi-controller-sa"
    role_arn        = aws_iam_role.ebs_csi.arn
  }
  
  external_dns = {
    namespace       = "kube-system"
    service_account = "external-dns"
    role_arn        = aws_iam_role.external_dns.arn
  }
}
```

**Note**: EKS Pod Identity is an alternative to IRSA that simplifies IAM role binding for service accounts. It does not require annotation of service accounts.

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
| `enable_karpenter_tags` | Tag resources for Karpenter auto-discovery (security groups, subnets) | `bool` | `false` | No |

### Advanced Cluster Features

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `control_plane_scaling_config` | Configuration for control plane scaling tier (standard, tier-xl, tier-2xl, tier-4xl for improved performance and availability) | `object` | `null` | No |
| `zonal_shift_config` | Configuration for automatic zonal shift to manage traffic during availability zone events | `object` | `null` | No |
| `remote_network_config` | Configuration for EKS Hybrid Nodes to connect on-premises infrastructure to the cluster | `object` | `null` | No |
| `upgrade_policy` | Configuration for cluster support policy (STANDARD or EXTENDED support with longer maintenance windows) | `object` | `null` | No |

**Control Plane Scaling Configuration:**
```hcl
control_plane_scaling_config = {
  tier = "standard"  # Options: "standard", "tier-xl", "tier-2xl", "tier-4xl"
}
```
Valid tiers provide progressively higher resource allocation and availability:
- `standard`: Default tier for most clusters
- `tier-xl`: 2x control plane resources, recommended for clusters with >10 node groups
- `tier-2xl`: 4x control plane resources, for very large or demanding clusters
- `tier-4xl`: 8x control plane resources, for massive scale deployments

**Zonal Shift Configuration:**
```hcl
zonal_shift_config = {
  enabled = true  # Enable automatic shift of traffic away from affected AZs during events
}
```
When enabled, EKS automatically shifts cluster traffic away from an availability zone experiencing issues.

**Remote Network Configuration (EKS Hybrid Nodes):**
```hcl
remote_network_config = {
  remote_node_networks = {
    cidrs = ["10.0.0.0/8"]  # CIDR blocks of on-premises networks where hybrid nodes run
  }
  remote_pod_networks = {
    cidrs = ["192.168.0.0/16"]  # CIDR blocks for pods running on hybrid nodes
  }
}
```
Enables connecting on-premises EC2 instances or virtual machines as nodes in your EKS cluster.

**Upgrade Policy Configuration:**
```hcl
upgrade_policy = {
  support_type = "STANDARD"  # Options: "STANDARD" or "EXTENDED"
}
```
- `STANDARD`: 14-month support (default)
- `EXTENDED`: 24-month extended support window for longer maintenance cycles

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
  cluster_version = "1.34"
  
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
  enable_karpenter_tags = true
  
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
  cluster_version = "1.34"
  
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
  cluster_version      = "1.34"
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

  cluster_name    = "dev-cluster"
  cluster_version = "1.34"
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

### Example 5: EKS Pod Identity with Service Accounts

This example demonstrates using native EKS Pod Identity for workload IAM credentials without annotations:

```hcl
# Create IAM roles for workloads
resource "aws_iam_role" "ebs_csi_role" {
  name = "ebs-csi-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_iam_role" "external_dns_role" {
  name = "external-dns"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  role       = aws_iam_role.external_dns_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
}

# EKS cluster with Pod Identity associations
module "eks_pod_identity" {
  source = "../../modules/compute/eks"

  cluster_name    = "pod-identity-cluster"
  cluster_version = "1.34"
  
  vpc_id    = aws_vpc.main.id
  subnet_ids = aws_subnet.private[*].id
  
  # Enable IRSA for broader compatibility
  enable_irsa = true
  
  managed_node_groups = {
    general = {
      min_size       = 2
      max_size       = 4
      desired_size   = 2
      instance_types = ["t3.large"]
    }
  }
  
  # EKS Add-ons
  cluster_addons = {
    vpc-cni = {
      addon_version = "v1.14.0"
    }
    coredns = {
      addon_version = "v1.10.1"
    }
    kube-proxy = {
      addon_version = "v1.28.1"
    }
    aws-ebs-csi-driver = {
      addon_version = "v1.24.0"
      # Service account will be created by the add-on
    }
  }
  
  # Pod Identity Associations - Direct binding without annotations
  pod_identity_associations = {
    ebs_csi = {
      namespace       = "kube-system"
      service_account = "ebs-csi-controller-sa"
      role_arn        = aws_iam_role.ebs_csi_role.arn
    }
    
    external_dns = {
      namespace       = "kube-system"
      service_account = "external-dns-sa"
      role_arn        = aws_iam_role.external_dns_role.arn
    }
  }
  
  tags = {
    Environment = "production"
    PodIdentity = "enabled"
  }
}

output "cluster_name" {
  value = module.eks_pod_identity.cluster_name
}

# Note: No need to annotate service accounts with eks.amazonaws.com/role-arn
# Pod Identity handles the binding automatically
```

### Example 6: Highly Available Production Cluster with Advanced Features

This example uses control plane scaling, zonal shift, and extended support for enterprise requirements:

```hcl
module "eks_ha_production" {
  source = "../../modules/compute/eks"

  cluster_name    = "ha-prod-cluster"
  cluster_version = "1.34"
  
  vpc_id = aws_vpc.production.id
  subnet_ids = concat(
    aws_subnet.private_us_east_1a[*].id,
    aws_subnet.private_us_east_1b[*].id,
    aws_subnet.private_us_east_1c[*].id
  )
  
  # Separate subnets for control plane
  control_plane_subnet_ids = aws_subnet.control_plane[*].id
  
  # High Availability Configuration
  # Upgrade to tier-xl for control plane scaling (recommended for >10 node groups)
  control_plane_scaling_config = {
    tier = "tier-xl"  # 2x standard resources for HA
  }
  
  # Zonal shift for automatic failover during AZ events
  zonal_shift_config = {
    enabled = true
  }
  
  # Extended support for 24-month upgrade windows
  upgrade_policy = {
    support_type = "EXTENDED"
  }
  
  # API endpoint configuration for production
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = ["10.0.0.0/8"]  # Only internal networks
  cluster_endpoint_private_access      = true
  
  # KMS encryption for secrets
  create_kms_key         = true
  kms_key_administrators = [aws_iam_role.security_team.arn]
  
  # CloudWatch logging
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cloudwatch_log_group_retention_in_days = 365  # 1 year retention
  cloudwatch_log_group_kms_key_id        = aws_kms_key.logs.arn
  
  # Multiple node groups for workload separation
  managed_node_groups = {
    system = {
      name             = "system"
      min_size         = 3
      max_size         = 6
      desired_size     = 3
      instance_types   = ["t3.large"]
      capacity_type    = "ON_DEMAND"
      labels           = { workload = "system" }
      
      taints = [{
        key    = "system"
        value  = "true"
        effect = "NoSchedule"
      }]
    }
    
    general = {
      name             = "general"
      min_size         = 3
      max_size         = 10
      desired_size     = 5
      instance_types   = ["m5.xlarge", "m6i.xlarge"]
      capacity_type    = "ON_DEMAND"
      labels           = { workload = "general" }
    }
    
    memory_optimized = {
      name             = "memory"
      min_size         = 2
      max_size         = 6
      desired_size     = 2
      instance_types   = ["r5.2xlarge", "r6i.2xlarge"]
      capacity_type    = "ON_DEMAND"
      labels           = { workload = "memory-intensive" }
      
      taints = [{
        key    = "memory-intensive"
        value  = "true"
        effect = "NoSchedule"
      }]
    }
    
    spot_batch = {
      name             = "spot"
      min_size         = 2
      max_size         = 20
      desired_size     = 5
      instance_types   = ["m5.xlarge", "m6i.xlarge", "c5.xlarge", "c6i.xlarge"]
      capacity_type    = "SPOT"
      labels           = { workload = "batch", cost-optimized = "true" }
      
      taints = [{
        key    = "spot"
        value  = "true"
        effect = "NoSchedule"
      }]
    }
  }
  
  # Fargate for variable workloads
  fargate_profiles = {
    system = {
      name = "kube-system"
      selectors = [{
        namespace = "kube-system"
      }]
    }
    
    batch_jobs = {
      name = "batch"
      selectors = [{
        namespace = "batch"
        labels    = { type = "batch-job" }
      }]
    }
  }
  
  # Add-ons with advanced configuration
  cluster_addons = {
    vpc-cni = {
      addon_version = "v1.14.0"
      configuration_values = jsonencode({
        env = {
          WARM_IP_TARGET = "5"
        }
      })
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
    
    aws-efs-csi-driver = {
      addon_version = "v1.7.0"
    }
  }
  
  # Access control with role-based policies
  enable_irsa                             = true
  enable_cluster_creator_admin_permissions = false  # Explicit control
  
  access_entries = {
    cluster_admins = {
      principal_arn = aws_iam_role.platform_team.arn
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
    
    developers = {
      principal_arn = aws_iam_role.developers.arn
      type          = "STANDARD"
      
      policy_associations = {
        edit = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
          access_scope = {
            type       = "namespace"
            namespaces = ["default", "development", "staging"]
          }
        }
      }
    }
    
    read_only = {
      principal_arn = aws_iam_role.auditors.arn
      type          = "STANDARD"
      
      policy_associations = {
        view = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
  
  # Security groups
  create_cluster_security_group = true
  
  cluster_security_group_additional_rules = {
    allow_internal_api = {
      type        = "ingress"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
      description = "Allow internal API access"
    }
  }
  
  node_security_group_enable_recommended_rules = true
  
  # Karpenter integration for auto-scaling
  enable_karpenter_tags = true
  
  tags = {
    Environment = "production"
    HA          = "enabled"
    Team        = "platform"
    CostCenter  = "engineering"
  }
}

output "cluster_name" {
  value = module.eks_ha_production.cluster_name
}

output "cluster_endpoint" {
  value = module.eks_ha_production.cluster_endpoint
}

output "kubeconfig_command" {
  value = module.eks_ha_production.kubeconfig_command
}
```

### Example 7: Cost-Optimized Cluster with Spot Instances and Autoscaling

This example demonstrates cost optimization using Spot instances, mixed capacity types, and smart scaling:

```hcl
module "eks_cost_optimized" {
  source = "../../modules/compute/eks"

  cluster_name    = "cost-optimized-cluster"
  cluster_version = "1.34"
  
  vpc_id    = aws_vpc.main.id
  subnet_ids = aws_subnet.private[*].id
  
  # Cost-friendly API access
  cluster_endpoint_public_access       = false
  cluster_endpoint_private_access      = true
  
  managed_node_groups = {
    # Minimal on-demand for system workloads
    system = {
      min_size       = 2
      max_size       = 3
      desired_size   = 2
      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"
      labels         = { workload = "system" }
      
      taints = [{
        key    = "system"
        value  = "true"
        effect = "NoSchedule"
      }]
    }
    
    # Spot instances for significant cost savings (70-90% discount)
    spot_primary = {
      min_size       = 3
      max_size       = 20
      desired_size   = 5
      
      # Diversified instance types for better Spot availability
      instance_types = [
        "t3.large", "t3a.large", "t4g.large",
        "m5.large", "m6i.large", "m7i.large",
        "c5.large", "c6i.large", "c7i.large"
      ]
      
      capacity_type  = "SPOT"
      labels         = { workload = "spot", cost-optimized = "true" }
      
      taints = [{
        key    = "spot"
        value  = "true"
        effect = "NoSchedule"
      }]
      
      # Allow pod disruption budgets for graceful handling
      update_config = {
        max_unavailable_percentage = 50
      }
    }
    
    # On-demand backup for critical workloads
    on_demand_backup = {
      min_size       = 1
      max_size       = 5
      desired_size   = 1
      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"
      labels         = { workload = "backup", cost-optimized = "true" }
    }
  }
  
  # Fargate for bursty workloads (no idle cost)
  fargate_profiles = {
    batch = {
      name = "batch-jobs"
      selectors = [{
        namespace = "batch"
      }]
    }
    
    cron = {
      name = "scheduled-tasks"
      selectors = [{
        namespace = "cron"
      }]
    }
  }
  
  cluster_addons = {
    vpc-cni = {
      addon_version = "v1.14.0"
    }
    coredns = {
      addon_version = "v1.10.1"
    }
    kube-proxy = {
      addon_version = "v1.28.1"
    }
  }
  
  tags = {
    CostCenter     = "engineering"
    CostOptimized  = "true"
  }
}

# For cost monitoring, you should also deploy:
# - Kubecost (in-cluster cost visibility)
# - AWS Cost Anomaly Detection
# - AWS Cost & Usage Reports integration
```

### Example 8: GPU-Enabled Cluster for ML Workloads

This example sets up a cluster optimized for machine learning with GPU support:

```hcl
module "eks_gpu_ml" {
  source = "../../modules/compute/eks"

  cluster_name    = "gpu-ml-cluster"
  cluster_version = "1.34"
  
  vpc_id    = aws_vpc.main.id
  subnet_ids = aws_subnet.private[*].id
  
  # Default nodes for control plane and support workloads
  managed_node_groups = {
    cpu_system = {
      min_size       = 2
      max_size       = 4
      desired_size   = 2
      instance_types = ["t3.large"]
      labels         = { workload = "system" }
      
      taints = [{
        key    = "system"
        value  = "true"
        effect = "NoSchedule"
      }]
    }
    
    # GPU nodes for training (NVIDIA A100 or H100)
    gpu_training = {
      min_size       = 0
      max_size       = 5
      desired_size   = 1
      instance_types = ["g4dn.12xlarge", "g4dn.24xlarge"]  # NVIDIA T4 GPUs
      ami_type       = "AL2_x86_64_GPU"
      disk_size      = 100
      
      labels = {
        workload  = "training"
        gpu       = "true"
        gpu-type  = "nvidia-t4"
      }
      
      taints = [{
        key    = "nvidia.com/gpu"
        value  = "true"
        effect = "NoSchedule"
      }]
      
      iam_role_additional_policies = {
        S3Access = "arn:aws:iam::aws:policy/AmazonS3FullAccess"  # For data/model access
      }
    }
    
    # CPU nodes for inference (cost-effective)
    cpu_inference = {
      min_size       = 1
      max_size       = 10
      desired_size   = 2
      instance_types = ["c5.2xlarge", "c6i.2xlarge"]
      labels         = { workload = "inference", gpu = "false" }
    }
  }
  
  cluster_addons = {
    vpc-cni = {
      addon_version = "v1.14.0"
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
  
  tags = {
    Workload = "ML-Training"
    GPU      = "enabled"
  }
}

# Note: After cluster creation, install NVIDIA GPU drivers:
# kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.13.0/nvidia-device-plugin.yml
#
# Verify GPU availability:
# kubectl get nodes -L nvidia.com/gpu
# kubectl describe node <gpu-node>
```

### Example 9: EKS Hybrid Nodes (On-Premises + AWS)

This example configures a cluster that spans AWS and on-premises infrastructure:

```hcl
# Prerequisites: On-premises nodes must have network connectivity to AWS
# - Direct Connect or VPN tunnel configured
# - Security groups/firewalls allow required ports

module "eks_hybrid" {
  source = "../../modules/compute/eks"

  cluster_name    = "hybrid-cluster"
  cluster_version = "1.34"
  
  vpc_id    = aws_vpc.main.id
  subnet_ids = aws_subnet.private[*].id
  
  # Configure remote networks for on-premises infrastructure
  remote_network_config = {
    # CIDR blocks where on-premises nodes run
    remote_node_networks = {
      cidrs = [
        "192.168.0.0/16",  # Corporate data center
        "10.50.0.0/16"     # Branch office
      ]
    }
    
    # CIDR blocks for pods running on hybrid nodes
    remote_pod_networks = {
      cidrs = [
        "172.16.0.0/16",   # Pod CIDR for on-premises nodes
        "172.17.0.0/16"
      ]
    }
  }
  
  # AWS-managed nodes for cloud workloads
  managed_node_groups = {
    cloud = {
      min_size       = 2
      max_size       = 8
      desired_size   = 2
      instance_types = ["m5.xlarge"]
      labels = {
        location = "aws"
        workload = "cloud-native"
      }
    }
    
    batch = {
      min_size       = 0
      max_size       = 10
      desired_size   = 0
      instance_types = ["c5.2xlarge"]
      capacity_type  = "SPOT"
      labels = {
        location = "aws"
        workload = "batch"
      }
      
      taints = [{
        key    = "batch"
        value  = "true"
        effect = "NoSchedule"
      }]
    }
  }
  
  cluster_addons = {
    vpc-cni = {
      addon_version = "v1.14.0"
    }
    coredns = {
      addon_version = "v1.10.1"
    }
    kube-proxy = {
      addon_version = "v1.28.1"
    }
  }
  
  tags = {
    Infrastructure = "hybrid"
    OnPremises     = "enabled"
  }
}

# After cluster creation, register on-premises nodes:
# 1. Install EKS Hybrid Node Agent on on-premises servers
# 2. Run: aws ssm send-command --document-name "AWS-RunShellScript" --targets "Key=tag:Name,Values=on-premises-node" --parameters commands="sudo /opt/eks-hybrid/bin/node-agent start"
# 3. Verify: kubectl get nodes -L topology.kubernetes.io/zone
```

### Example 10: Enterprise Multi-Tenant Cluster with Security Hardening

This example demonstrates best practices for multi-tenant environments with security and isolation:

```hcl
module "eks_enterprise" {
  source = "../../modules/compute/eks"

  cluster_name    = "enterprise-multi-tenant"
  cluster_version = "1.34"
  
  vpc_id = aws_vpc.main.id
  
  # Separate subnets for different security zones
  control_plane_subnet_ids = aws_subnet.secure[*].id
  node_group_subnet_ids    = aws_subnet.nodes[*].id
  
  # Security-first configuration
  cluster_endpoint_public_access       = false
  cluster_endpoint_private_access      = true
  
  create_cluster_security_group = true
  cluster_security_group_additional_rules = {
    allow_bastion_api = {
      type                     = "ingress"
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      source_security_group_id = aws_security_group.bastion.id
      description              = "Allow bastion host access"
    }
  }
  
  node_security_group_enable_recommended_rules = true
  node_security_group_additional_rules = {
    allow_velero_backup = {
      type        = "egress"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow backup egress"
    }
  }
  
  # Encryption at rest for secrets
  create_kms_key         = true
  kms_key_administrators = [aws_iam_role.security_team.arn]
  
  # Comprehensive logging
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cloudwatch_log_group_retention_in_days = 180
  cloudwatch_log_group_kms_key_id        = aws_kms_key.logs.arn
  
  # Isolated node groups per tenant
  managed_node_groups = {
    system = {
      min_size       = 3
      max_size       = 5
      desired_size   = 3
      instance_types = ["t3.large"]
      labels         = { tenant = "system", isolation = "strict" }
      
      taints = [{
        key    = "system"
        value  = "true"
        effect = "NoSchedule"
      }]
    }
    
    tenant_a = {
      min_size       = 2
      max_size       = 6
      desired_size   = 2
      instance_types = ["m5.large"]
      labels         = { tenant = "tenant-a", isolation = "strict" }
      
      taints = [{
        key    = "tenant"
        value  = "tenant-a"
        effect = "NoSchedule"
      }]
      
      # Dedicated IAM role with minimal permissions
      create_iam_role = true
    }
    
    tenant_b = {
      min_size       = 2
      max_size       = 6
      desired_size   = 2
      instance_types = ["m5.large"]
      labels         = { tenant = "tenant-b", isolation = "strict" }
      
      taints = [{
        key    = "tenant"
        value  = "tenant-b"
        effect = "NoSchedule"
      }]
    }
  }
  
  cluster_addons = {
    vpc-cni = {
      addon_version = "v1.14.0"
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
  
  # IRSA for service account security
  enable_irsa                             = true
  enable_cluster_creator_admin_permissions = false
  
  # Fine-grained access control per role
  access_entries = {
    cluster_admin = {
      principal_arn = aws_iam_role.cluster_admin.arn
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
    
    tenant_a_admin = {
      principal_arn = aws_iam_role.tenant_a_admin.arn
      type          = "STANDARD"
      
      policy_associations = {
        edit = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
          access_scope = {
            type       = "namespace"
            namespaces = ["tenant-a"]
          }
        }
      }
    }
    
    tenant_b_admin = {
      principal_arn = aws_iam_role.tenant_b_admin.arn
      type          = "STANDARD"
      
      policy_associations = {
        edit = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
          access_scope = {
            type       = "namespace"
            namespaces = ["tenant-b"]
          }
        }
      }
    }
    
    auditor = {
      principal_arn = aws_iam_role.auditor.arn
      type          = "STANDARD"
      
      policy_associations = {
        view = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
  
  tags = {
    Environment = "production"
    MultiTenant = "true"
    Compliance  = "required"
    SecurityLevel = "high"
  }
}

# Post-deployment network policies (apply with kubectl):
# kubectl apply -f - <<EOF
# apiVersion: networking.k8s.io/v1
# kind: NetworkPolicy
# metadata:
#   name: tenant-isolation
# spec:
#   podSelector:
#     matchLabels:
#       tenant: tenant-a
#   policyTypes:
#   - Ingress
#   - Egress
#   ingress:
#   - from:
#     - podSelector:
#         matchLabels:
#           tenant: tenant-a
#   egress:
#   - to:
#     - podSelector:
#         matchLabels:
#           tenant: tenant-a
#   - to:
#     - namespaceSelector: {}
#       podSelector:
#         matchLabels:
#           k8s-app: kube-dns
#     ports:
#     - protocol: UDP
#       port: 53
# EOF
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
# =========================
# Cluster & Control Plane
# =========================

# Verify cluster status and endpoint
aws eks describe-cluster --name <cluster-name> --region <region> \
  --query "cluster.{status:status,endpoint:endpoint,version:version}"

# Check control plane logs enabled
aws eks describe-cluster --name <cluster-name> --region <region> \
  --query "cluster.logging.clusterLogging"

# View EKS control plane logs
aws logs tail /aws/eks/<cluster-name>/cluster --follow

# Test API server connectivity
kubectl cluster-info
kubectl version --short

# =========================
# Nodes & Node Groups
# =========================

# List nodes with details
kubectl get nodes -o wide

# Describe a node (conditions, taints, capacity)
kubectl describe node <node-name>

# Check node group health
aws eks describe-nodegroup \
  --cluster-name <cluster-name> \
  --nodegroup-name <nodegroup-name> \
  --region <region>

# View recent node events
kubectl get events --field-selector involvedObject.kind=Node --sort-by=.lastTimestamp

# Kubelet logs (SSH into node)
journalctl -u kubelet -n 200
journalctl -u kubelet -f

# Container runtime logs (containerd)
journalctl -u containerd -n 200

# =========================
# Pods & Workloads
# =========================

# Get pods with node placement
kubectl get pods -o wide -n <namespace>

# Describe pod (events, probes, scheduling)
kubectl describe pod <pod-name> -n <namespace>

# View pod logs
kubectl logs <pod-name> -n <namespace>

# View logs from a specific container
kubectl logs <pod-name> -c <container-name> -n <namespace>

# Previous container logs (crash loops)
kubectl logs <pod-name> --previous -n <namespace>

# Exec into a running pod
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh

# =============================
# Deployments, DaemonSets, Jobs
# =============================

# Check rollout status
kubectl rollout status deployment/<deployment-name> -n <namespace>

# Describe deployment
kubectl describe deployment <deployment-name> -n <namespace>

# Check DaemonSet health
kubectl get ds -n <namespace>
kubectl describe ds <daemonset-name> -n <namespace>

# Debug failed Jobs
kubectl get jobs -n <namespace>
kubectl describe job <job-name> -n <namespace>

# =========================
# Networking & DNS
# =========================

# Check services and endpoints
kubectl get svc -n <namespace>
kubectl get endpoints -n <namespace>

# Verify CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns

# DNS resolution test inside cluster
kubectl run dns-test --rm -it --image=busybox \
  -- nslookup kubernetes.default

# Check CNI (AWS VPC CNI)
kubectl get pods -n kube-system -l k8s-app=aws-node
kubectl logs -n kube-system -l k8s-app=aws-node

# ==============================
# Security & Access (IAM / RBAC)
# ==============================

# Verify aws-auth ConfigMap
kubectl get configmap aws-auth -n kube-system -o yaml

# Check current Kubernetes context
kubectl config current-context
kubectl config get-contexts

# Check permissions for current user
kubectl auth can-i get pods --all-namespaces
kubectl auth can-i create deployments -n <namespace>

# =========================
# Load Balancers & Ingress
# =========================

# List ingress resources
kubectl get ingress -A
kubectl describe ingress <ingress-name> -n <namespace>

# Check AWS Load Balancers created by EKS
aws elbv2 describe-load-balancers

# Check target group health
aws elbv2 describe-target-health --target-group-arn <tg-arn>

# ==========================
# Events & General Debugging
# ==========================

# View all recent events
kubectl get events -A --sort-by=.lastTimestamp

# Watch events in real time
kubectl get events -A -w

# Check resource usage (metrics-server required)
kubectl top nodes
kubectl top pods -A

# ==================================
# Security Groups & Networking (AWS)
# ==================================

# Describe security group rules
aws ec2 describe-security-groups --group-ids <sg-id>

# Check route tables
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=<vpc-id>"

# Verify VPC endpoints (ECR, STS, EC2, S3)
aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=<vpc-id>"
```

## Recent Updates (Synchronized with Code)

### Latest Changes (Current)

#### New Features
- **EKS Pod Identity Support**: Added `pod_identity_associations` variable for native AWS pod identity credential binding (alternative to IRSA)
- **Control Plane Scaling Configuration**: Added `control_plane_scaling_config` for dynamic control plane tier management (standard, tier-xl, tier-2xl, tier-4xl)
- **Zonal Shift Configuration**: Added `zonal_shift_config` for automatic traffic shift during availability zone events
- **EKS Hybrid Nodes Support**: Added `remote_network_config` for connecting on-premises infrastructure as cluster nodes
- **Extended Upgrade Policy**: Added `upgrade_policy` for STANDARD (14-month) and EXTENDED (24-month) support windows

#### Improved Add-ons Management
- **Smart Dependency Management**: VPC CNI add-on now created before node groups (required for pod networking), other add-ons created after nodes exist to allow pod scheduling
- **Pod Identity Association in Add-ons**: Add-ons can now define pod identity associations directly in their configuration
- **Timeout Configuration**: Full support for create/update/delete timeout customization per add-on

#### Access Entry Enhancements
- **Robust Access Policy Association**: Re-implemented access policy association with improved flattening logic for managing multiple policies per access entry
- **Multiple Policy Support**: Each access entry can now have multiple policy associations with different scopes

### Previous Updates
- **Fixed cluster_version default**: Updated from erroneous `"1.34llama"` to correct `"1.34"`
- **Corrected API endpoint access defaults**:
  - `cluster_endpoint_public_access`: Changed from `true` to `false` (private-first approach)
  - `cluster_endpoint_public_access_cidrs`: Changed from `["0.0.0.0/0"]` to `[]`
  - Updated endpoint access pattern documentation to reflect private-first default
- **Updated AMI type documentation**: Changed from `AL2_x86_64` to `AL2023_x86_64_STANDARD` to match current code
- **Updated Kubernetes version examples**: All code examples now use version `1.34` (current default)
- **Verified provider versions**: Terraform ~> 1.14.1, AWS ~> 6.27.0, Kubernetes ~> 3.0.1

### Key Module Features (Verified Current)
- ✅ EKS Access Entries API with optional legacy aws-auth ConfigMap support
- ✅ IRSA (IAM Roles for Service Accounts) with OIDC provider
- ✅ EKS Pod Identity for simplified service account to role binding
- ✅ Managed Node Groups with AL2023 default AMI and launch template support
- ✅ Self-Managed Node Groups with Windows and Linux support
- ✅ Fargate Profiles for serverless pod execution
- ✅ KMS encryption for secrets and optional CloudWatch logs
- ✅ IPv4 and IPv6 support with flexible subnet placement
- ✅ Comprehensive security groups with customizable rules
- ✅ EKS add-ons management with smart dependency handling (VPC CNI before nodes, others after)
- ✅ CloudWatch logging with configurable retention
- ✅ Control plane scaling, zonal shift, hybrid nodes, and extended support policies

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
