# EKS Cluster Deployment Checklist

## Pre-Deployment Phase

### Prerequisites
- [ ] AWS Account with appropriate IAM permissions (AdministratorAccess or equivalent)
- [ ] AWS CLI v2.13.0+ installed and configured
  ```bash
  aws --version
  aws sts get-caller-identity
  ```
- [ ] Terraform v1.5.0+ installed
  ```bash
  terraform --version
  ```
- [ ] kubectl compatible with Kubernetes 1.34 installed
  ```bash
  kubectl version --client
  ```
- [ ] Git repository configured for infrastructure code
- [ ] SSH key pair available for any node SSH access (optional)

### Environment Setup
- [ ] AWS region set to `ap-south-1`
  ```bash
  export AWS_REGION=ap-south-1
  ```
- [ ] Terraform working directory: `aws_infra/dev`
- [ ] S3 bucket for Terraform remote state (if using backend)
- [ ] DynamoDB table for state locking (if using backend)
- [ ] VPC module already deployed (prerequisite)

### Configuration Review
- [ ] Review `aws_infra/dev/locals.tf` for EKS configuration
  - [ ] Cluster name: `vinay-dev-eks-cluster`
  - [ ] Kubernetes version: `1.34`
  - [ ] Spot node group enabled with proper instance types
  - [ ] On-demand node group configured correctly
  - [ ] All required add-ons listed
  - [ ] Tags properly configured
- [ ] Review node group scaling parameters
  - [ ] Spot nodes: Min=1, Max=5, Desired=2
  - [ ] On-demand nodes: Min=0, Max=3, Desired=1
- [ ] Verify security group rules allow proper communication
- [ ] Check VPC CIDR blocks for conflicts
- [ ] Review CloudWatch log retention settings (90 days default)

### Documentation Review
- [ ] Read `docs/EKS_CLUSTER_SETUP.md` completely
- [ ] Review `docs/EKS_QUICK_REFERENCE.md` for common operations
- [ ] Understand spot instance interruption handling
- [ ] Know how to scale node groups
- [ ] Understand pod scheduling with taints and labels

---

## Deployment Phase

### Terraform Initialization
- [ ] Navigate to dev directory
  ```bash
  cd aws_infra/dev
  ```
- [ ] Initialize Terraform
  ```bash
  terraform init
  ```
- [ ] Verify initialization completed without errors
  ```bash
  ls -la .terraform
  ```
- [ ] Check backend state is configured correctly (if applicable)
  ```bash
  terraform backend config
  ```

### Configuration Validation
- [ ] Validate Terraform syntax
  ```bash
  terraform validate
  ```
- [ ] Format check (optional but recommended)
  ```bash
  terraform fmt -check
  ```
- [ ] Review any warnings or errors
- [ ] Verify locals.tf is correctly structured
- [ ] Check module sources are correct
- [ ] Ensure all required variables are defined or have defaults

### Pre-Deployment Planning
- [ ] Create detailed terraform plan
  ```bash
  terraform plan -out=tfplan
  ```
- [ ] Review plan output for:
  - [ ] EKS cluster creation (aws_eks_cluster.this)
  - [ ] Managed node groups (aws_eks_node_group.this)
  - [ ] Security groups (aws_security_group)
  - [ ] IAM roles and policies (aws_iam_role, aws_iam_role_policy_attachment)
  - [ ] KMS key creation (aws_kms_key)
  - [ ] CloudWatch log group (aws_cloudwatch_log_group)
  - [ ] OIDC provider (aws_iam_openid_connect_provider)
  - [ ] Cluster add-ons (aws_eks_addon)
- [ ] Verify number of resources to be created (~50-80 resources)
- [ ] Check no unexpected deletions in the plan
- [ ] Save plan file: `tfplan`

### Backup and Documentation
- [ ] Create backup of current state (if state exists)
  ```bash
  terraform state pull > terraform.state.backup
  ```
- [ ] Document deployment start time
- [ ] Note any custom configuration from defaults
- [ ] Record decision log for any choices made

### Deployment Execution
- [ ] Execute Terraform apply
  ```bash
  terraform apply tfplan
  ```
- [ ] Monitor apply progress (15-20 minutes expected)
- [ ] Watch for any errors or warnings during creation
- [ ] Note the EKS cluster creation step (this is the longest, ~10-15 minutes)
- [ ] Monitor IAM role creation
- [ ] Watch security group creation
- [ ] Verify add-ons installation completes

### Post-Deployment Verification
- [ ] Apply completed successfully
  ```bash
  echo $?  # Should return 0
  ```
- [ ] No apply errors or failures recorded
- [ ] Verify Terraform state updated
  ```bash
  terraform state list | grep eks
  ```
- [ ] Check AWS console for:
  - [ ] EKS cluster shows "ACTIVE" status
  - [ ] Node groups show "ACTIVE" status
  - [ ] Nodes are "Ready" status
  - [ ] All add-ons installed successfully

---

## Post-Deployment Configuration

### kubectl Setup
- [ ] Update kubeconfig
  ```bash
  aws eks update-kubeconfig \
    --name vinay-dev-eks-cluster \
    --region ap-south-1
  ```
- [ ] Verify kubeconfig created
  ```bash
  ls -la ~/.kube/config
  ```
- [ ] Test kubectl connectivity
  ```bash
  kubectl cluster-info
  ```
- [ ] Verify cluster context
  ```bash
  kubectl config current-context
  ```

### Cluster Verification
- [ ] Get cluster information
  ```bash
  kubectl cluster-info dump
  ```
- [ ] Check cluster nodes
  ```bash
  kubectl get nodes
  ```
  - [ ] At least 2 nodes (1 spot + 1 on-demand) showing "Ready"
  - [ ] Nodes have correct labels (node-type, capacity-type)
  - [ ] Nodes have correct taints (if configured)

- [ ] Check system pods
  ```bash
  kubectl get pods -n kube-system
  ```
  - [ ] All core DNS pods running
  - [ ] aws-node pods running on all nodes
  - [ ] kube-proxy pods running on all nodes
  - [ ] ebs-csi-driver pods running (if enabled)

- [ ] Verify add-ons status
  ```bash
  aws eks describe-addons \
    --cluster-name vinay-dev-eks-cluster \
    --region ap-south-1
  ```
  - [ ] vpc-cni addon is ACTIVE
  - [ ] kube-proxy addon is ACTIVE
  - [ ] coredns addon is ACTIVE
  - [ ] ebs-csi-driver addon is ACTIVE

### Node Group Verification
- [ ] Check spot node group status
  ```bash
  aws eks describe-nodegroup \
    --cluster-name vinay-dev-eks-cluster \
    --nodegroup-name dev-spot-nodes-xxx \
    --region ap-south-1
  ```
  - [ ] Status shows "ACTIVE"
  - [ ] Desired capacity matches configuration (2)
  - [ ] Running nodes matches or approaches desired capacity

- [ ] Check on-demand node group status
  ```bash
  aws eks describe-nodegroup \
    --cluster-name vinay-dev-eks-cluster \
    --nodegroup-name dev-ondemand-nodes-xxx \
    --region ap-south-1
  ```
  - [ ] Status shows "ACTIVE"
  - [ ] Desired capacity matches configuration (1)

- [ ] Verify node group instances
  ```bash
  aws ec2 describe-instances \
    --filters "Name=tag:kubernetes.io/cluster/vinay-dev-eks-cluster,Values=owned" \
    --region ap-south-1
  ```
  - [ ] Correct number of instances running
  - [ ] Instances in "running" state
  - [ ] Correct security groups attached
  - [ ] Correct IAM instance profiles attached

### IAM and Security Verification
- [ ] Check cluster IAM role
  ```bash
  aws iam get-role --role-name eks-service-role-* 2>/dev/null || echo "Role not found"
  ```
- [ ] Check node IAM roles created
  ```bash
  aws iam list-roles | grep eks
  ```
- [ ] Verify security groups created
  ```bash
  aws ec2 describe-security-groups --filters "Name=group-name,Values=*eks*" --region ap-south-1
  ```
- [ ] Check security group rules
  - [ ] Cluster security group allows node communication
  - [ ] Node security group allows pod-to-pod communication
  - [ ] Proper egress rules configured

### KMS and Encryption Verification
- [ ] Check KMS key created
  ```bash
  terraform output eks_kms_key_id
  ```
- [ ] Verify key policy allows cluster usage
- [ ] Check CloudWatch logs encrypted (if applicable)
- [ ] Verify EBS volumes are encrypted
  ```bash
  aws ec2 describe-volumes --region ap-south-1 | grep -A5 Encrypted
  ```

### Network Verification
- [ ] Verify VPC resources
  ```bash
  terraform output vpc_id
  ```
- [ ] Check private subnets where nodes are deployed
  ```bash
  terraform output private_subnet_ids
  ```
- [ ] Verify NAT gateway is functional
  ```bash
  aws ec2 describe-nat-gateways --region ap-south-1
  ```
- [ ] Test outbound connectivity from pods
  ```bash
  kubectl run -it --image=amazonlinux:2 debug-pod -- /bin/bash
  # Inside pod: curl https://www.google.com
  ```

### Add-ons Configuration
- [ ] Verify VPC CNI configuration
  ```bash
  kubectl describe pod -n kube-system -l k8s-app=aws-node
  ```
- [ ] Check CoreDNS is resolving
  ```bash
  kubectl run -it --image=amazonlinux:2 debug -- nslookup kubernetes
  ```
- [ ] Verify EBS CSI driver (if needed)
  ```bash
  kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver
  ```

### OIDC Provider Verification
- [ ] Check OIDC provider created
  ```bash
  terraform output eks_oidc_provider_arn
  ```
- [ ] List OIDC providers
  ```bash
  aws iam list-open-id-connect-providers --region ap-south-1
  ```
- [ ] Verify OIDC provider configuration
  ```bash
  aws iam get-open-id-connect-provider \
    --open-id-connect-provider-arn <arn-from-output>
  ```

### CloudWatch Logging Setup
- [ ] Check log group created
  ```bash
  aws logs describe-log-groups \
    --log-group-name-prefix "/aws/eks/vinay-dev-eks-cluster" \
    --region ap-south-1
  ```
- [ ] View recent logs
  ```bash
  aws logs tail /aws/eks/vinay-dev-eks-cluster/cluster --since 1h --follow
  ```
- [ ] Verify all log types are enabled
  - [ ] api
  - [ ] audit
  - [ ] authenticator
  - [ ] controllerManager
  - [ ] scheduler

---

## Testing Phase

### Basic Workload Deployment
- [ ] Deploy test pod to spot nodes
  ```bash
  kubectl create deployment test-spot --image=nginx
  ```
- [ ] Verify pod scheduled on spot node
  ```bash
  kubectl get pod -o wide
  kubectl describe pod <pod-name>
  ```
- [ ] Deploy pod with on-demand node selector
  ```yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: test-ondemand
  spec:
    nodeSelector:
      node-type: ondemand
    containers:
    - name: app
      image: nginx:latest
  ```
- [ ] Verify pod scheduled correctly
- [ ] Test inter-pod communication
  ```bash
  kubectl exec -it <pod1> -- curl http://<pod2-ip>
  ```

### Networking Test
- [ ] Test DNS resolution
  ```bash
  kubectl run -it --image=amazon/amazon-aws-cli:latest test-dns -- /bin/bash
  nslookup kubernetes.default
  nslookup google.com
  ```
- [ ] Test external connectivity
  ```bash
  kubectl run -it --image=amazonlinux:2 test-external -- /bin/bash
  curl https://www.google.com
  ```
- [ ] Test service creation
  ```bash
  kubectl expose deployment test-spot --port=80 --type=ClusterIP
  kubectl get service
  ```

### Scaling Test
- [ ] Scale deployment up
  ```bash
  kubectl scale deployment test-spot --replicas=5
  ```
- [ ] Verify nodes scale up appropriately
  ```bash
  kubectl get nodes
  watch 'aws ec2 describe-instances --filters "Name=tag:kubernetes.io/cluster/vinay-dev-eks-cluster,Values=owned" --region ap-south-1 | grep running | wc -l'
  ```
- [ ] Scale deployment down
  ```bash
  kubectl scale deployment test-spot --replicas=1
  ```
- [ ] Verify nodes scale down (after cooldown period)

### Resource Monitoring
- [ ] Check node resource utilization
  ```bash
  kubectl top nodes
  ```
- [ ] Check pod resource usage
  ```bash
  kubectl top pods -A
  ```
- [ ] Verify resource requests are appropriate
  ```bash
  kubectl describe pod <pod-name> | grep -A 5 "Limits\|Requests"
  ```

### Spot Instance Behavior
- [ ] Monitor for spot interruptions (if applicable)
  ```bash
  watch 'aws ec2 describe-spot-instance-requests --region ap-south-1'
  ```
- [ ] Verify workload survives node termination
  ```bash
  # Simulate termination (optional, careful with production)
  kubectl drain <spot-node-name> --ignore-daemonsets --delete-emptydir-data
  ```

### Cleanup Test Resources
- [ ] Delete test deployments
  ```bash
  kubectl delete deployment test-spot
  kubectl delete pod test-ondemand
  kubectl delete service test-spot
  ```
- [ ] Verify resources cleaned up
  ```bash
  kubectl get pods --all-namespaces
  ```

---

## Documentation and Handover

### Documentation Tasks
- [ ] Update or create deployment runbook
- [ ] Document cluster access procedures
- [ ] Document scaling procedures
- [ ] Create troubleshooting guide for common issues
- [ ] Document cost monitoring approach
- [ ] Record cluster-specific configurations or customizations

### Access Management
- [ ] Configure RBAC if needed
- [ ] Add appropriate users to kubeconfig
- [ ] Document access procedures
- [ ] Set up IAM roles for service accounts (IRSA) examples
- [ ] Create service account for CI/CD systems

### Monitoring Setup (Optional but Recommended)
- [ ] Set up CloudWatch alarms for:
  - [ ] Cluster CPU utilization
  - [ ] Cluster memory utilization
  - [ ] Node count
  - [ ] Pod count
- [ ] Set up log aggregation (optional)
- [ ] Install metrics server (if not already present)
  ```bash
  kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
  ```
- [ ] Install Kubernetes Dashboard (optional)
  ```bash
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
  ```

### Cost Monitoring Setup
- [ ] Enable AWS Cost Explorer
- [ ] Create cost alerts
- [ ] Document expected monthly costs
- [ ] Set up cost anomaly detection
- [ ] Document cost optimization strategies used

### Backup and Disaster Recovery
- [ ] Plan backup strategy (consider Velero)
- [ ] Document disaster recovery procedures
- [ ] Test cluster recreation from code
- [ ] Document state file backup location
- [ ] Create disaster recovery runbook

---

## Ongoing Operations Checklist

### Weekly Tasks
- [ ] Review CloudWatch logs for errors
  ```bash
  aws logs filter-log-events \
    --log-group-name /aws/eks/vinay-dev-eks-cluster/cluster \
    --filter-pattern "ERROR"
  ```
- [ ] Check node status
  ```bash
  kubectl get nodes
  ```
- [ ] Monitor cluster cost trends
- [ ] Check for pending patches or updates

### Monthly Tasks
- [ ] Review and update documentation
- [ ] Analyze cost trends and optimization opportunities
- [ ] Review security group rules
- [ ] Check for deprecated APIs in use
- [ ] Verify backup/disaster recovery procedures
- [ ] Review add-on versions for updates
- [ ] Check CloudWatch log retention settings
- [ ] Analyze node utilization and scaling efficiency

### Quarterly Tasks
- [ ] Kubernetes version upgrade evaluation
- [ ] Node AMI version update
- [ ] Security audit of cluster and workloads
- [ ] Capacity planning review
- [ ] Cost optimization review
- [ ] Disaster recovery drill
- [ ] Review and update runbooks

### Annual Tasks
- [ ] Major version upgrade planning
- [ ] Full security audit
- [ ] Capacity projection for next year
- [ ] Contract/pricing review with AWS
- [ ] Complete cluster redesign evaluation
- [ ] Team training and certification updates

---

## Troubleshooting Quick Reference

### Nodes Not Ready
- [ ] Check CloudWatch logs
- [ ] Verify security groups allow communication
- [ ] Check IAM roles have required permissions
- [ ] SSH to node and check kubelet status
- [ ] Review node group events in AWS console

### Pods Not Scheduling
- [ ] Check pod events: `kubectl describe pod <pod-name>`
- [ ] Verify taints: `kubectl describe nodes | grep Taints`
- [ ] Check node resources: `kubectl top nodes`
- [ ] Verify node selectors match available nodes

### Connectivity Issues
- [ ] Test DNS: `kubectl run -it --image=amazonlinux:2 -- nslookup kubernetes`
- [ ] Check security groups
- [ ] Verify NAT gateway status
- [ ] Check route tables

### High Costs
- [ ] Review node utilization
- [ ] Check for unused instances
- [ ] Verify spot instances are being used
- [ ] Consider Reserved Instances for on-demand nodes
- [ ] Implement cluster autoscaler

---

## Sign-Off

- [ ] All checks completed
- [ ] Cluster ready for production workloads
- [ ] Documentation complete and accessible
- [ ] Team trained on cluster operations
- [ ] Monitoring and alerting configured
- [ ] Backup and disaster recovery procedures tested
- [ ] Cost monitoring in place
- [ ] Security review completed
- [ ] Handover to operations team (if applicable)

**Deployment Date**: _______________
**Deployed By**: _______________
**Reviewed By**: _______________
**Sign-off Date**: _______________

---

## Emergency Contacts

| Role | Name | Contact |
|------|------|---------|
| DevOps Lead | | |
| AWS TAM | | |
| Incident Commander | | |

## Useful References

- **AWS EKS Documentation**: https://docs.aws.amazon.com/eks/
- **Terraform Docs**: https://www.terraform.io/docs/
- **Kubernetes Docs**: https://kubernetes.io/docs/
- **Project Documentation**: `aws_infra/docs/`

---

**Last Updated**: 2024
**Cluster**: vinay-dev-eks-cluster
**Region**: ap-south-1
**Status**: Ready for Deployment