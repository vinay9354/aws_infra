# EKS Cluster with Spot Instances - Documentation Hub

Welcome! This folder contains comprehensive documentation for the EKS cluster deployment in the development environment using Terraform with spot instances for cost optimization.

## 📚 Documentation Files

### 1. **IMPLEMENTATION_SUMMARY.md** ⭐ START HERE
   - **Purpose**: Overview of what was created and why
   - **Best for**: Understanding the big picture
   - **Contents**:
     - What was implemented
     - Key features and architecture
     - File changes and new files
     - How to deploy
     - Quick command reference
   - **Read time**: 10-15 minutes

### 2. **DEPLOYMENT_CHECKLIST.md** ✅ BEFORE YOU DEPLOY
   - **Purpose**: Step-by-step checklist for deployment
   - **Best for**: Ensuring nothing is missed during deployment
   - **Contents**:
     - Pre-deployment checklist
     - Deployment phase checklist
     - Post-deployment verification
     - Testing procedures
     - Ongoing operations tasks
     - Troubleshooting reference
   - **Use**: Follow this checklist for each deployment
   - **Read time**: Reference document

### 3. **EKS_CLUSTER_SETUP.md** 📖 COMPREHENSIVE GUIDE
   - **Purpose**: Detailed technical guide for the EKS cluster
   - **Best for**: In-depth understanding and troubleshooting
   - **Contents**:
     - Complete architecture overview
     - Configuration details explained
     - Step-by-step deployment instructions
     - Working with spot instances
     - Cost analysis and optimization
     - Security best practices
     - Monitoring and operations
     - Maintenance procedures
     - Customization examples
   - **Read time**: 30-40 minutes

### 4. **EKS_QUICK_REFERENCE.md** ⚡ QUICK LOOKUP
   - **Purpose**: Fast reference for common operations
   - **Best for**: Quick answers and commands
   - **Contents**:
     - Quick start commands
     - Common kubectl commands
     - AWS CLI commands
     - Terraform operations
     - Scaling procedures
     - Cost estimation
     - Common tasks with examples
     - Troubleshooting quick tips
     - Maintenance checklist
   - **Read time**: 5-10 minutes per section

### 5. **README.md** (this file) 🏠 YOU ARE HERE
   - **Purpose**: Navigation hub for all documentation
   - **Best for**: Knowing where to find information
   - **Contents**: This file

---

## 🚀 Quick Start

### I want to...

#### Deploy the cluster
1. Read: **IMPLEMENTATION_SUMMARY.md** - "How to Deploy" section (5 min)
2. Check: **DEPLOYMENT_CHECKLIST.md** - Pre-Deployment Phase (10 min)
3. Follow: **DEPLOYMENT_CHECKLIST.md** - Deployment Phase (20 min)
4. Verify: **DEPLOYMENT_CHECKLIST.md** - Post-Deployment Phase (15 min)

**Total time**: ~50 minutes + deployment time (15-20 min)

#### Understand the architecture
1. Read: **IMPLEMENTATION_SUMMARY.md** - "Spot Instance Configuration" section
2. Read: **EKS_CLUSTER_SETUP.md** - "Architecture Overview" and "Configuration Details"
3. Review: Configuration in `aws_infra/dev/locals.tf`

**Total time**: ~20 minutes

#### Find a command quickly
1. Go to: **EKS_QUICK_REFERENCE.md**
2. Search for the section you need
3. Copy the command and adapt as needed

**Total time**: 2-5 minutes

#### Troubleshoot a problem
1. Go to: **EKS_CLUSTER_SETUP.md** - "Troubleshooting" section
2. Or: **EKS_QUICK_REFERENCE.md** - "Troubleshooting" section
3. If not found, check: **DEPLOYMENT_CHECKLIST.md** - "Troubleshooting Quick Reference"

**Total time**: 5-15 minutes

#### Scale node groups
1. Go to: **EKS_QUICK_REFERENCE.md** - "Scaling Node Groups" section
2. Or: **EKS_CLUSTER_SETUP.md** - "Monitoring and Operations" > "Scaling Operations"
3. Follow: **DEPLOYMENT_CHECKLIST.md** - "Customization Checklist"

**Total time**: 10 minutes

#### Understand costs
1. Go to: **IMPLEMENTATION_SUMMARY.md** - "Cost Analysis" section
2. Or: **EKS_QUICK_REFERENCE.md** - "Cost Estimation" section
3. Or: **EKS_CLUSTER_SETUP.md** - "Cost Optimization" section

**Total time**: 5 minutes

#### Learn about spot instances
1. Read: **EKS_CLUSTER_SETUP.md** - "Working with Spot Instances" section
2. Read: **EKS_QUICK_REFERENCE.md** - "Spot Instance Tips"
3. Review examples in both files

**Total time**: 15 minutes

#### Customize the configuration
1. Review: **IMPLEMENTATION_SUMMARY.md** - "Configuration Customization" section
2. Read: **EKS_CLUSTER_SETUP.md** - "Customization Examples" section
3. Edit: `aws_infra/dev/locals.tf` with changes
4. Run: `terraform plan` to preview
5. Run: `terraform apply` to apply

**Total time**: 20-30 minutes

---

## 📋 Key Information at a Glance

### Cluster Details
| Property | Value |
|----------|-------|
| **Cluster Name** | vinay-dev-eks-cluster |
| **Kubernetes Version** | 1.34 |
| **Region** | ap-south-1 (Mumbai) |
| **VPC CIDR** | 172.20.0.0/16 |
| **Deployment Method** | Terraform IaC |

### Node Groups
| Name | Type | Min | Max | Desired | Instance Types |
|------|------|-----|-----|---------|-----------------|
| dev_spot_nodes | SPOT | 1 | 5 | 2 | t3, t3a, t2.medium |
| dev_ondemand_nodes | ON_DEMAND | 0 | 3 | 1 | t3.medium |

### Cost Estimation (Monthly)
- 2 Spot t3.medium: ~$27
- 1 On-Demand t3.medium: ~$45
- EKS Cluster: $73
- **Total: ~$145/month**
- **Savings vs all on-demand: ~45%**

### Features
✅ Spot instances for cost optimization  
✅ Multi-type strategy for high availability  
✅ Auto-scaling configured  
✅ KMS encryption enabled  
✅ IRSA support ready  
✅ Managed add-ons pre-configured  
✅ CloudWatch logging enabled  
✅ Private subnet deployment  
✅ Security groups auto-managed  
✅ Comprehensive monitoring  

---

## 🛠️ Files Modified/Created

### Configuration Files (Modified)
- `aws_infra/dev/locals.tf` - Added `eks_cluster_config` local
- `aws_infra/dev/main.tf` - Added EKS module call
- `aws_infra/dev/outputs.tf` - Added EKS cluster outputs
- `aws_infra/dev/data.tf` - Added AWS region data source

### Documentation Files (Created)
- `aws_infra/docs/README.md` - This file
- `aws_infra/docs/IMPLEMENTATION_SUMMARY.md` - Implementation overview
- `aws_infra/docs/DEPLOYMENT_CHECKLIST.md` - Deployment checklist
- `aws_infra/docs/EKS_CLUSTER_SETUP.md` - Comprehensive setup guide
- `aws_infra/docs/EKS_QUICK_REFERENCE.md` - Quick reference guide

---

## 🎯 Common Workflows

### Deploy EKS Cluster
```bash
# 1. Review configuration
cd aws_infra/dev
cat locals.tf | grep -A 200 "eks_cluster_config"

# 2. Plan
terraform init
terraform plan -out=tfplan

# 3. Deploy
terraform apply tfplan

# 4. Configure kubectl
aws eks update-kubeconfig --name vinay-dev-eks-cluster --region ap-south-1

# 5. Verify
kubectl get nodes
```

### Scale Node Groups
```bash
# 1. Edit configuration
vim aws_infra/dev/locals.tf

# 2. Find dev_spot_nodes or dev_ondemand_nodes
# 3. Change desired_size, min_size, or max_size

# 4. Plan
terraform plan -out=tfplan

# 5. Apply
terraform apply tfplan

# 6. Monitor
watch 'kubectl get nodes'
```

### Deploy Workload on Spot Nodes
```bash
# 1. Create deployment with spot affinity
kubectl create deployment test-app --image=nginx

# 2. Edit to add node selector (optional)
kubectl edit deployment test-app
# Add: nodeSelector: capacity-type: spot

# 3. Verify
kubectl get pods -o wide
```

### Monitor Cluster
```bash
# Check nodes
kubectl get nodes --show-labels

# Check resources
kubectl top nodes
kubectl top pods -A

# Check logs
aws logs tail /aws/eks/vinay-dev-eks-cluster/cluster --follow

# Check add-ons
kubectl get pods -n kube-system
```

### Troubleshoot Issue
```bash
# 1. Get cluster status
kubectl cluster-info

# 2. Check node status
kubectl describe nodes

# 3. Check pod events
kubectl describe pod <pod-name>

# 4. Check logs
kubectl logs <pod-name>
aws logs tail /aws/eks/vinay-dev-eks-cluster/cluster --follow
```

---

## 📊 Documentation Map

```
START HERE
    ↓
IMPLEMENTATION_SUMMARY.md
├── Overview of implementation
├── How to deploy (quick version)
└── Quick command reference
    ↓
Choose your path:
├─ If deploying → DEPLOYMENT_CHECKLIST.md
│  ├── Pre-deployment checks
│  ├── Deployment steps
│  ├── Verification steps
│  └── Ongoing operations
│
├─ If learning → EKS_CLUSTER_SETUP.md
│  ├── Architecture explained
│  ├── Configuration details
│  ├── Spot instance guide
│  ├── Cost analysis
│  ├── Security practices
│  ├── Monitoring guide
│  └── Troubleshooting
│
└─ If quick lookup → EKS_QUICK_REFERENCE.md
   ├── Quick commands
   ├── Common tasks
   ├── Scaling procedures
   ├── Cost estimation
   └── Tips & tricks
```

---

## 🔍 Finding Information

### By Topic
| Topic | Where to Find |
|-------|---------------|
| Deployment steps | DEPLOYMENT_CHECKLIST.md or EKS_CLUSTER_SETUP.md |
| Scaling nodes | EKS_QUICK_REFERENCE.md or EKS_CLUSTER_SETUP.md |
| Cost estimation | IMPLEMENTATION_SUMMARY.md or EKS_QUICK_REFERENCE.md |
| Spot instances | EKS_CLUSTER_SETUP.md or EKS_QUICK_REFERENCE.md |
| Security | EKS_CLUSTER_SETUP.md |
| Monitoring | EKS_CLUSTER_SETUP.md |
| Troubleshooting | EKS_QUICK_REFERENCE.md or EKS_CLUSTER_SETUP.md |
| kubectl commands | EKS_QUICK_REFERENCE.md |
| AWS CLI commands | EKS_QUICK_REFERENCE.md |
| Terraform commands | EKS_QUICK_REFERENCE.md |

### By Role
| Role | Read First | Then Read |
|------|-----------|-----------|
| **DevOps Engineer** | IMPLEMENTATION_SUMMARY.md | EKS_CLUSTER_SETUP.md |
| **Platform Engineer** | EKS_CLUSTER_SETUP.md | All docs for deep knowledge |
| **Cloud Architect** | IMPLEMENTATION_SUMMARY.md | EKS_CLUSTER_SETUP.md sections on architecture |
| **Operations** | DEPLOYMENT_CHECKLIST.md | EKS_QUICK_REFERENCE.md |
| **Developer** | EKS_QUICK_REFERENCE.md | Relevant sections from other docs |

---

## 🚨 Important Notes

### Before Deploying
1. ✅ Review `aws_infra/dev/locals.tf` - understand the configuration
2. ✅ Read DEPLOYMENT_CHECKLIST.md - ensure prerequisites are met
3. ✅ Follow deployment checklist - don't skip steps
4. ✅ Have AWS credentials configured - check with `aws sts get-caller-identity`
5. ✅ Budget conscious? - Review cost section first

### During Deployment
1. ⏱️ Expected time: 15-20 minutes for Terraform + cluster creation
2. 📺 Monitor progress - don't interrupt the process
3. 📝 Keep notes - save important outputs (endpoint, OIDC ARN)
4. ✋ Be patient - cluster creation is the longest step (~10-15 min)

### After Deployment
1. ✅ Verify all nodes are Ready - use `kubectl get nodes`
2. ✅ Check system pods - use `kubectl get pods -n kube-system`
3. ✅ Save outputs - run `terraform output` to capture information
4. ✅ Configure monitoring - set up CloudWatch alarms
5. ✅ Document changes - keep runbooks updated

### Spot Instance Considerations
- ⚠️ Can be interrupted with 2-minute notice
- 🎯 Use multiple instance types for better availability
- 🛡️ Implement pod disruption budgets for critical workloads
- 💰 Saves 70-90% on compute costs
- 📊 Monitor interruption rates

---

## 📞 Support

### Getting Help
1. **Quick answer?** → Check EKS_QUICK_REFERENCE.md
2. **Specific error?** → Search EKS_CLUSTER_SETUP.md troubleshooting section
3. **Can't find it?** → Check DEPLOYMENT_CHECKLIST.md troubleshooting section
4. **Still stuck?** → Review cluster logs and AWS console

### Log Files
- **Cluster logs**: `/aws/eks/vinay-dev-eks-cluster/cluster`
- **Node logs**: Access via SSM Session Manager
- **Application logs**: Use `kubectl logs`

### Resources
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

## 📝 Document Versions

| Document | Version | Last Updated | Purpose |
|----------|---------|--------------|---------|
| IMPLEMENTATION_SUMMARY.md | 1.0 | 2024 | Implementation overview |
| DEPLOYMENT_CHECKLIST.md | 1.0 | 2024 | Deployment checklist |
| EKS_CLUSTER_SETUP.md | 1.0 | 2024 | Comprehensive guide |
| EKS_QUICK_REFERENCE.md | 1.0 | 2024 | Quick reference |

---

## ✨ What You Get

With this implementation, you have:

### ✅ Infrastructure as Code
- Complete Terraform configuration
- Locals-based organization
- Modular, reusable design
- Version controlled setup

### ✅ Cost Optimization
- Spot instances as primary node group
- Multi-type strategy for availability
- ~50% savings vs all on-demand
- Cost monitoring guidance

### ✅ Security
- KMS encryption for cluster data
- Private subnet deployment
- Automatic security group management
- IRSA support
- IMDSv2 enforcement
- CloudWatch audit logging

### ✅ High Availability
- Multi-AZ deployment
- Multiple instance types
- Auto-scaling configured
- Managed add-ons
- Failover strategies documented

### ✅ Comprehensive Documentation
- 4 detailed guides
- Quick reference
- Deployment checklist
- Troubleshooting guides
- Examples and customization tips

### ✅ Production Ready
- Security best practices
- Monitoring capabilities
- Disaster recovery planning
- Maintenance procedures
- Operations runbooks

---

## 🎓 Learning Path

### Day 1: Understanding
1. Read IMPLEMENTATION_SUMMARY.md (15 min)
2. Review cluster configuration in `aws_infra/dev/locals.tf` (15 min)
3. Read EKS_CLUSTER_SETUP.md "Architecture Overview" (15 min)
4. Understand spot instances (EKS_CLUSTER_SETUP.md section) (15 min)

### Day 2: Deployment
1. Follow DEPLOYMENT_CHECKLIST.md pre-deployment phase (20 min)
2. Execute deployment phase (20 min for preparation, 15-20 min for terraform)
3. Follow post-deployment verification (30 min)

### Day 3: Operations
1. Learn kubectl commands (EKS_QUICK_REFERENCE.md) (20 min)
2. Learn scaling procedures (EKS_QUICK_REFERENCE.md) (15 min)
3. Set up monitoring (EKS_CLUSTER_SETUP.md section) (20 min)
4. Learn troubleshooting (EKS_QUICK_REFERENCE.md) (20 min)

### Ongoing: Reference
- Use EKS_QUICK_REFERENCE.md for daily operations
- Refer to EKS_CLUSTER_SETUP.md for deep dives
- Update DEPLOYMENT_CHECKLIST.md for future deployments

---

## 🏁 Next Steps

1. **📖 Read** IMPLEMENTATION_SUMMARY.md to understand what was created
2. **✅ Follow** DEPLOYMENT_CHECKLIST.md for step-by-step deployment
3. **⚙️ Review** configuration in `aws_infra/dev/locals.tf`
4. **🚀 Deploy** the infrastructure using Terraform
5. **✨ Verify** everything is working with kubectl
6. **📊 Monitor** your cluster and manage costs

---

**Welcome to your EKS cluster! 🎉**

Questions? See the appropriate documentation file above.

---

**Last Updated**: 2024  
**Cluster Version**: 1.34  
**Region**: ap-south-1  
**Status**: Ready for Deployment