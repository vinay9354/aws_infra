# EKS Cluster Quick Reference Guide

## Quick Start

### Deploy EKS Cluster
```bash
cd aws_infra/dev
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### Connect to Cluster
```bash
aws eks update-kubeconfig --name vinay-dev-eks-cluster --region ap-south-1
kubectl get nodes
```

## Cluster Information

| Property | Value |
|----------|-------|
| **Cluster Name** | vinay-dev-eks-cluster |
| **Kubernetes Version** | 1.34 |
| **Region** | ap-south-1 |
| **VPC CIDR** | 172.20.0.0/16 |
| **Endpoint Access** | Private + Public |

## Node Groups

### Spot Node Group (dev_spot_nodes)
- **Capacity**: SPOT (saves 70-90% cost)
- **Instance Types**: t3.medium, t3a.medium, t2.medium
- **Scaling**: Min=1, Max=5, Desired=2
- **Labels**: `node-type=spot`, `capacity-type=spot`
- **Taint**: `spot=true:NoSchedule`
- **Use Case**: Non-critical workloads, dev/test

### On-Demand Node Group (dev_ondemand_nodes)
- **Capacity**: ON_DEMAND (guaranteed availability)
- **Instance Type**: t3.medium
- **Scaling**: Min=0, Max=3, Desired=1
- **Labels**: `node-type=ondemand`, `workload=critical`
- **Taint**: `critical=true:NoSchedule`
- **Use Case**: Critical services, system components

## Configuration Files

### Key Locals (dev/locals.tf)
```hcl
local.eks_cluster_config  # All cluster configuration
  ├── cluster_name
  ├── cluster_version
  ├── managed_node_groups (spot + on-demand)
  ├── cluster_addons (vpc-cni, coredns, kube-proxy, ebs-csi-driver)
  └── tags
```

### Module Call (dev/main.tf)
```hcl
module "eks" {
  source = "../modules/compute/eks"
  
  # Uses configuration from local.eks_cluster_config
  # Deploys cluster, node groups, and add-ons
}
```

## Common kubectl Commands

### View Cluster
```bash
# Get cluster info
kubectl cluster-info

# Check nodes
kubectl get nodes
kubectl get nodes -o wide
kubectl get nodes --show-labels

# Check node details
kubectl describe nodes
kubectl describe node <node-name>
```

### Check Add-ons
```bash
# List all pods in kube-system
kubectl get pods -n kube-system

# Check specific add-on
kubectl describe pod -n kube-system <pod-name>

# Check node status
kubectl get nodes -o json | jq '.items[].status.conditions'
```

### Pod Scheduling

**Schedule on Spot Nodes (with toleration if taint enabled):**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: spot-workload
spec:
  tolerations:
  - key: spot
    operator: Equal
    value: "true"
    effect: NoSchedule
  nodeSelector:
    capacity-type: spot
  containers:
  - name: app
    image: nginx:latest
```

**Schedule on On-Demand Nodes:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: critical-workload
spec:
  nodeSelector:
    capacity-type: ondemand
  containers:
  - name: app
    image: nginx:latest
```

## Terraform Commands

### Planning & Applying
```bash
cd aws_infra/dev

# Initialize
terraform init

# Validate configuration
terraform validate

# See what will change
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan

# Destroy (WARNING: deletes cluster)
terraform destroy
```

### Viewing State
```bash
# List all resources
terraform state list

# Show specific resource
terraform state show module.eks

# Export state to JSON
terraform state list | grep eks
```

### Outputs
```bash
# View all outputs
terraform output

# Get specific output
terraform output eks_cluster_endpoint
terraform output eks_cluster_id
terraform output eks_oidc_provider_arn
terraform output eks_cluster_auth_command
```

## AWS CLI Commands

### Cluster Management
```bash
# Describe cluster
aws eks describe-cluster \
  --name vinay-dev-eks-cluster \
  --region ap-south-1

# List node groups
aws eks list-nodegroups \
  --cluster-name vinay-dev-eks-cluster \
  --region ap-south-1

# Describe node group
aws eks describe-nodegroup \
  --cluster-name vinay-dev-eks-cluster \
  --nodegroup-name dev-spot-nodes-xxx \
  --region ap-south-1
```

### Add-ons Management
```bash
# List add-ons
aws eks list-addons \
  --cluster-name vinay-dev-eks-cluster \
  --region ap-south-1

# Describe add-on
aws eks describe-addon \
  --addon-name vpc-cni \
  --cluster-name vinay-dev-eks-cluster \
  --region ap-south-1
```

### CloudWatch Logs
```bash
# View cluster logs
aws logs tail /aws/eks/vinay-dev-eks-cluster/cluster --follow

# Search for errors
aws logs filter-log-events \
  --log-group-name /aws/eks/vinay-dev-eks-cluster/cluster \
  --filter-pattern "ERROR"
```

### Spot Instance Info
```bash
# Check spot instance status
aws ec2 describe-spot-instance-requests \
  --filters Name=status-code,Values=marked-for-termination \
  --region ap-south-1

# Get pricing
aws ec2 describe-spot-price-history \
  --instance-types t3.medium t3a.medium t2.medium \
  --product-descriptions "Linux/UNIX" \
  --region ap-south-1
```

## Scaling Node Groups

### Via Terraform
Edit `aws_infra/dev/locals.tf`:

```hcl
dev_spot_nodes = {
  min_size     = 1      # Change here
  max_size     = 5      # Change here
  desired_size = 2      # Change here
  # ...
}
```

Then apply:
```bash
terraform plan -out=tfplan
terraform apply tfplan
```

### Via AWS Console
- Go to EKS > Clusters > vinay-dev-eks-cluster
- Select node group
- Update Desired size, Min size, Max size
- Click Update

### Via AWS CLI
```bash
aws eks update-nodegroup-config \
  --cluster-name vinay-dev-eks-cluster \
  --nodegroup-name dev-spot-nodes-xxx \
  --scaling-config minSize=1,maxSize=10,desiredSize=3 \
  --region ap-south-1
```

## Customization Examples

### Add GPU Node Group
Add to `local.eks_cluster_config.managed_node_groups`:

```hcl
gpu_nodes = {
  name            = "gpu-nodes"
  capacity_type   = "SPOT"
  instance_types  = ["g4dn.xlarge"]
  min_size        = 0
  max_size        = 2
  desired_size    = 0
  labels = {
    "workload" = "gpu"
    "gpu"      = "true"
  }
}
```

### Increase Spot Instance Types
```hcl
instance_types = [
  "t3.medium", "t3a.medium", "t2.medium",
  "t4g.medium",  # Graviton processor (cheaper)
  "m5.large", "m5a.large"  # If you need more CPU
]
```

### Restrict Public Access
```hcl
cluster_endpoint_public_access_cidrs = [
  "203.0.113.50/32",    # Your IP
  "198.51.100.0/24"     # Your office
]
```

### Disable Taints
```hcl
taints = []  # Remove or comment out taints block
```

## Troubleshooting

### Nodes Not Ready
```bash
# Check node status
kubectl describe node <node-name>

# Check node logs
aws ssm start-session --target <instance-id>

# In the session:
journalctl -u kubelet -f

# Check security groups
aws ec2 describe-security-groups \
  --filters Name=group-name,Values=*eks* \
  --region ap-south-1
```

### Pod Won't Schedule
```bash
# Describe pod
kubectl describe pod <pod-name>

# Check taints on nodes
kubectl describe nodes | grep -A 5 Taints

# Check node resources
kubectl top nodes
kubectl top pods

# Check pod affinity/selectors
kubectl get pod <pod-name> -o yaml | grep -A 10 nodeSelector
```

### Spot Instance Interrupted
```bash
# Monitor interruptions
watch "aws ec2 describe-spot-instance-requests --filters Name=status-code,Values=marked-for-termination --region ap-south-1"

# Check cluster autoscaler logs (if installed)
kubectl logs -n karpenter -f deployment/karpenter
```

### Can't Connect to Cluster
```bash
# Update kubeconfig
aws eks update-kubeconfig \
  --name vinay-dev-eks-cluster \
  --region ap-south-1

# Check authentication
kubectl auth can-i get pods

# Check if security groups allow access
aws ec2 describe-security-groups \
  --filters Name=group-id,Values=<cluster-sg-id> \
  --region ap-south-1
```

## Cost Estimation

### Monthly Costs (Example)
- **2 Spot t3.medium**: ~$27
- **1 On-Demand t3.medium**: ~$45
- **EKS Cluster**: $73
- **Total**: ~$145/month

### Savings with Spot
- All On-Demand (3 × t3.medium + EKS): ~$265/month
- With Spot (2 × spot + 1 × on-demand + EKS): ~$145/month
- **Savings**: ~45-50% monthly cost reduction

## Security Checklist

- [ ] Private endpoint enabled (cluster only accessible from VPC)
- [ ] KMS encryption enabled for secrets
- [ ] CloudWatch logging enabled
- [ ] Security groups properly configured
- [ ] IAM roles with least privilege
- [ ] IRSA (OpenID Connect) configured
- [ ] Network policies in place (if needed)
- [ ] Regular backups configured (Velero)
- [ ] Audit logging reviewed
- [ ] Node AMI updated regularly

## Maintenance Tasks

### Monthly
- [ ] Review CloudWatch logs
- [ ] Check for add-on updates
- [ ] Review security group rules
- [ ] Monitor costs
- [ ] Check spot interruption rates

### Quarterly
- [ ] Update Kubernetes version
- [ ] Review node AMI versions
- [ ] Audit IAM roles
- [ ] Update container images
- [ ] Review cluster autoscaling settings

### Annually
- [ ] Plan capacity growth
- [ ] Review pricing and instance types
- [ ] Disaster recovery drill
- [ ] Security audit
- [ ] Cost optimization review

## Useful Links

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Spot Instances Guide](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-spot-instances.html)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)

## Quick Tips

1. **Use `kubectl` aliases** for faster commands:
   ```bash
   alias k=kubectl
   alias kgn='kubectl get nodes'
   alias kgp='kubectl get pods'
   ```

2. **Install useful tools**:
   ```bash
   # kube-ps1 (shows current cluster)
   # kubectx (switch clusters easily)
   # stern (tail logs from multiple pods)
   ```

3. **Use Node Labels for Scheduling**:
   ```bash
   # View available labels
   kubectl get nodes --show-labels
   
   # Add custom label
   kubectl label nodes <node-name> workload=batch
   ```

4. **Monitor Spot Interruptions**:
   ```bash
   # Install AWS Node Termination Handler
   helm install aws-node-termination-handler \
     aws/aws-node-termination-handler \
     -n karpenter
   ```

5. **Enable Cluster Autoscaler** (for production):
   ```bash
   helm install autoscaler autoscaler/cluster-autoscaler \
     -n karpenter \
     --set autoDiscovery.clusterName=vinay-dev-eks-cluster
   ```

---

**Last Updated**: 2024
**Quick Reference Version**: 1.0