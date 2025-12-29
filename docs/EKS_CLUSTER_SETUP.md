# EKS Cluster Setup Guide - Development Environment

## Overview

This guide documents the EKS (Elastic Kubernetes Service) cluster setup for the development environment using Terraform. The cluster is configured with:

- **Managed Node Groups** using both Spot and On-Demand instances
- **Spot Instances** for cost optimization (primary node group)
- **On-Demand Instances** for critical workloads
- **Auto Scaling** with configurable min/max capacity
- **KMS Encryption** for cluster data
- **IRSA** (IAM Roles for Service Accounts) support
- **Multiple Add-ons** (VPC-CNI, CoreDNS, kube-proxy, EBS CSI Driver)
- **CloudWatch Logging** for cluster control plane
- **High Availability** across multiple subnets

## Architecture

### Cluster Configuration
- **Cluster Name**: `vinay-dev-eks-cluster`
- **Kubernetes Version**: 1.34
- **Region**: ap-south-1
- **VPC CIDR**: 172.20.0.0/16

### Node Groups

#### 1. Spot Instance Node Group (Primary)
**Purpose**: Cost-optimized general workloads

- **Name**: `dev-spot-nodes`
- **Capacity Type**: SPOT
- **Instance Types**: t3.medium, t3a.medium, t2.medium (multi-type for better availability)
- **Scaling**:
  - Min Size: 1
  - Max Size: 5
  - Desired Size: 2
- **Label**: `node-type=spot`, `capacity-type=spot`
- **Taint**: `spot=true:NoSchedule` (optional - for dedicated spot workloads)
- **Storage**: 30GB gp3 (encrypted)

#### 2. On-Demand Node Group (Optional)
**Purpose**: Critical workloads requiring stability

- **Name**: `dev-ondemand-nodes`
- **Capacity Type**: ON_DEMAND
- **Instance Type**: t3.medium
- **Scaling**:
  - Min Size: 0 (can be scaled down to save costs)
  - Max Size: 3
  - Desired Size: 1
- **Label**: `node-type=ondemand`, `workload=critical`
- **Taint**: `critical=true:NoSchedule` (for dedicated critical workloads)
- **Storage**: 30GB gp3 (encrypted)

## Infrastructure as Code Structure

### File Organization

```
aws_infra/
├── dev/
│   ├── main.tf              # EKS module instantiation
│   ├── locals.tf            # EKS cluster configuration
│   ├── outputs.tf           # EKS cluster outputs
│   ├── data.tf              # Data sources
│   ├── provider.tf          # AWS provider
│   ├── backend.tf           # Remote state configuration
│   └── variables.tf         # Input variables
├── modules/
│   └── compute/eks/
│       ├── main.tf          # EKS cluster resource
│       ├── node_groups.tf   # Managed node groups
│       ├── iam.tf           # IAM roles and policies
│       ├── security_groups.tf
│       ├── addons.tf        # Cluster add-ons
│       ├── variables.tf
│       ├── outputs.tf
│       └── ...
└── docs/
    └── EKS_CLUSTER_SETUP.md (this file)
```

## Configuration Details

### Locals Configuration (locals.tf)

The EKS cluster is configured entirely in the `eks_cluster_config` local variable:

```hcl
locals {
  eks_cluster_config = {
    cluster_name           = "vinay-dev-eks-cluster"
    cluster_version        = "1.34"
    enable_cluster_logging = true
    
    cluster_endpoint_private_access = true
    cluster_endpoint_public_access  = true
    cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]
    
    enable_irsa       = true    # For IRSA support
    create_kms_key    = true    # For encryption
    
    managed_node_groups = {
      # Spot and On-Demand configurations
    }
    
    cluster_addons = {
      vpc-cni         # VPC CNI plugin
      kube-proxy      # Kube proxy add-on
      coredns         # DNS service
      ebs-csi-driver  # EBS volume support
    }
  }
}
```

### Module Instantiation (main.tf)

The EKS module is called with configuration from locals:

```hcl
module "eks" {
  source = "../modules/compute/eks"

  cluster_name    = local.eks_cluster_config.cluster_name
  cluster_version = local.eks_cluster_config.cluster_version
  vpc_id          = module.vpc.vpc_id

  # Subnets from private subnets module
  subnet_ids = [for subnet in module.private_subnets : subnet.subnet_id]
  
  # Node groups with spot instances
  managed_node_groups = local.eks_cluster_config.managed_node_groups
  
  # Cluster add-ons
  cluster_addons = local.eks_cluster_config.cluster_addons
  
  # IRSA and encryption
  enable_irsa    = local.eks_cluster_config.enable_irsa
  create_kms_key = local.eks_cluster_config.create_kms_key
  
  tags = local.eks_cluster_config.tags
}
```

## Spot Instance Configuration

### Why Spot Instances?

1. **Cost Savings**: Up to 90% cheaper than On-Demand instances
2. **Ideal for Dev/Test**: Non-critical workloads benefit from cost reduction
3. **Multi-Type Strategy**: Using multiple instance types reduces interruption risk
4. **Auto Scaling**: Automatically scales based on demand

### Spot Instance Capacity Type

In the managed node group configuration:

```hcl
capacity_type  = "SPOT"
instance_types = ["t3.medium", "t3a.medium", "t2.medium"]
```

### Spot Instance Considerations

- **Interruption Risk**: AWS can reclaim instances with 2-minute notice
- **Mitigation**: 
  - Multiple instance types improve availability
  - Auto Scaling replaces interrupted instances
  - Pod Disruption Budgets can protect critical workloads
  - Cluster Autoscaler handles scale-up/down

- **Taints**: Optional taints prevent critical workloads from being scheduled on spot nodes
- **Labels**: Use labels for pod affinity rules to prefer specific node types

## Deployment Instructions

### Prerequisites

```bash
# Ensure Terraform is installed
terraform version

# Ensure AWS CLI is configured
aws configure
aws sts get-caller-identity
```

### Deployment Steps

#### 1. Navigate to Development Environment

```bash
cd aws_infra/dev
```

#### 2. Initialize Terraform

```bash
terraform init
```

#### 3. Validate Configuration

```bash
terraform validate
```

#### 4. Plan Deployment

```bash
terraform plan -out=tfplan
```

This will show you:
- VPC and subnet creation
- EKS cluster creation
- Managed node groups
- Add-ons installation
- Security groups and IAM roles

#### 5. Apply Configuration

```bash
terraform apply tfplan
```

**Estimated Deployment Time**: 15-20 minutes

#### 6. Configure kubectl

After deployment completes:

```bash
aws eks update-kubeconfig \
  --name vinay-dev-eks-cluster \
  --region ap-south-1
```

#### 7. Verify Cluster

```bash
# Check cluster
kubectl cluster-info

# Check nodes
kubectl get nodes

# Check node labels and taints
kubectl get nodes --show-labels

# Check node capacity and allocatable resources
kubectl describe nodes
```

### Example Output

```bash
$ kubectl get nodes
NAME                                           STATUS   ROLES    AGE     VERSION
ip-172-20-30-100.ap-south-1.compute.internal  Ready    <none>   5m      v1.34.x
ip-172-20-31-50.ap-south-1.compute.internal   Ready    <none>   5m      v1.34.x

$ kubectl get nodes --show-labels
NAME                                           STATUS   LABELS
ip-172-20-30-100.ap-south-1.compute.internal  Ready    node-type=spot,capacity-type=spot,kubernetes.io/arch=amd64
ip-172-20-31-50.ap-south-1.compute.internal   Ready    node-type=spot,capacity-type=spot,kubernetes.io/arch=amd64
```

## Accessing Outputs

After deployment, retrieve cluster information:

```bash
# Get all EKS-related outputs
terraform output

# Get specific outputs
terraform output eks_cluster_endpoint
terraform output eks_cluster_id
terraform output eks_oidc_provider_arn
```

### Key Outputs

| Output | Description |
|--------|-------------|
| `eks_cluster_id` | Cluster ID for AWS CLI commands |
| `eks_cluster_endpoint` | Kubernetes API endpoint URL |
| `eks_cluster_name` | Cluster name for kubeconfig |
| `eks_oidc_provider_arn` | OIDC provider for IRSA |
| `eks_managed_node_groups` | Details of node groups |
| `eks_cluster_auth_command` | Ready-to-use kubeconfig command |

## Workload Scheduling

### Scheduling on Spot Nodes

**Option 1: No Taint (Allows any workload)**

Pods will automatically schedule on spot nodes if resources are available.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-app
spec:
  containers:
  - name: app
    image: nginx:latest
  # Will schedule on spot nodes by default
```

**Option 2: With Node Affinity (Prefer spot)**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-app
spec:
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        preference:
          matchExpressions:
          - key: capacity-type
            operator: In
            values:
            - spot
  containers:
  - name: app
    image: nginx:latest
```

**Option 3: With Taint Toleration (If taints enabled)**

If spot nodes have taint `spot=true:NoSchedule`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-app
spec:
  tolerations:
  - key: spot
    operator: Equal
    value: "true"
    effect: NoSchedule
  containers:
  - name: app
    image: nginx:latest
```

### Scheduling on On-Demand Nodes

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: critical-service
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: node-type
            operator: In
            values:
            - ondemand
  containers:
  - name: service
    image: myapp:latest
```

## Spot Instance Interruption Handling

### 1. Pod Disruption Budgets

Protect critical workloads from disruptions:

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: critical-app-pdb
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: critical-app
```

### 2. Cluster Autoscaler

Automatically replaces interrupted spot instances:

- Monitors for underutilized nodes
- Scales up when pods are pending
- Scales down idle nodes

### 3. AWS Node Termination Handler

Gracefully handle spot interruption notices:

```bash
# This would be installed via Helm or kubectl
kubectl apply -f https://github.com/aws/aws-node-termination-handler/releases/
```

## Cost Optimization

### Estimated Monthly Costs (Example)

**t3.medium pricing (ap-south-1)**:
- On-Demand: ~$45/month per instance
- Spot: ~$13.50/month per instance

**Example Configuration**:
- 2 Spot instances (desired): ~$27/month
- 1 On-Demand instance: ~$45/month
- **Total**: ~$72/month (vs ~$180 for all On-Demand)

### Cost Optimization Tips

1. **Use Multiple Instance Types**: Improves spot availability
2. **Right-Size Instances**: Don't over-provision
3. **Implement Resource Requests**: Allows better bin-packing
4. **Use Spot for Non-Critical**: Only run non-critical workloads on spot
5. **Monitor Costs**: Use AWS Cost Explorer and Kubernetes cost tools
6. **Scale to Zero**: Use cluster autoscaler to scale down non-critical node groups

## Customization

### Modifying Node Group Configuration

Edit `aws_infra/dev/locals.tf`:

```hcl
dev_spot_nodes = {
  min_size     = 1      # Change minimum nodes
  max_size     = 5      # Change maximum nodes
  desired_size = 2      # Change desired nodes
  
  instance_types = ["t3.medium", "t3a.medium", "t2.medium"]  # Add/remove instance types
  disk_size = 30        # Increase volume size if needed
}
```

### Adding More Node Groups

Add new entries in `managed_node_groups`:

```hcl
gpu_spot_nodes = {
  name            = "gpu-spot-nodes"
  capacity_type   = "SPOT"
  instance_types  = ["g4dn.xlarge", "g4dn.2xlarge"]
  min_size        = 0
  max_size        = 3
  desired_size    = 0
  
  labels = {
    "workload" = "gpu"
  }
  
  tags = {
    NodeGroup = "gpu-spot"
  }
}
```

### Updating Kubernetes Version

```hcl
cluster_version = "1.35"  # Update in locals
```

Then:
```bash
terraform plan
terraform apply
```

## Monitoring and Logging

### CloudWatch Logs

Cluster control plane logs are sent to CloudWatch in log group:
```
/aws/eks/vinay-dev-eks-cluster/cluster
```

Enabled log types:
- `api` - API server logs
- `audit` - Audit logs
- `authenticator` - Auth logs
- `controllerManager` - Controller manager logs
- `scheduler` - Scheduler logs

### Check Logs

```bash
aws logs describe-log-groups --region ap-south-1
aws logs tail /aws/eks/vinay-dev-eks-cluster/cluster --follow
```

### Node Monitoring

```bash
# Check node resources
kubectl top nodes

# Check pod resources
kubectl top pods --all-namespaces

# Check node details
kubectl describe node <node-name>
```

## Security Best Practices

1. **KMS Encryption**: Enabled for cluster encryption
2. **Private Endpoint**: Control plane accessible only from VPC (can be modified)
3. **Security Groups**: Restrict traffic between cluster and nodes
4. **RBAC**: Configure with access entries or aws-auth ConfigMap
5. **IRSA**: Use for pod-level IAM permissions
6. **IMDSv2**: Enforced on all nodes for metadata security
7. **Network Policies**: Implement with Calico or other CNI plugins

## Troubleshooting

### Nodes Not Starting

```bash
# Check node group events
aws eks describe-nodegroup \
  --cluster-name vinay-dev-eks-cluster \
  --nodegroup-name dev-spot-nodes-xxx \
  --region ap-south-1

# Check CloudWatch logs
kubectl logs -n kube-system -l k8s-app=aws-node
```

### Pods Pending

```bash
# Describe pending pod
kubectl describe pod <pod-name>

# Check node resources
kubectl describe node

# Check for taints preventing scheduling
kubectl describe node --all-namespaces
```

### Spot Instance Interruption

```bash
# Check node termination events
kubectl describe node <node-name>

# View recent events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'
```

## Cleanup

To destroy the entire infrastructure:

```bash
terraform destroy
```

**Note**: This will delete:
- EKS cluster and node groups
- VPC and subnets
- All networking resources
- KMS keys
- CloudWatch log groups
- All workloads running in the cluster

Confirm by typing `yes` when prompted.

## Additional Resources

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [AWS EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [Spot Instances Guide](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-spot-instances.html)
- [Kubernetes Official Documentation](https://kubernetes.io/docs/)
- [Terraform AWS EKS Module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/)

## Support and Questions

For issues or questions:

1. Check CloudWatch logs: `/aws/eks/vinay-dev-eks-cluster/cluster`
2. Review Terraform state: `terraform state show`
3. Check AWS EKS console for cluster events
4. Review security group rules
5. Verify IAM permissions

---

**Last Updated**: 2024
**Terraform Version**: >= 1.0
**AWS Provider Version**: >= 5.0