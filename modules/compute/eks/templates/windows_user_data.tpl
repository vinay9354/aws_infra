<powershell>
[string]$EKSBootstrapScriptFile = "$env:ProgramFiles\Amazon\EKS\Start-EKSBootstrap.ps1"
& $EKSBootstrapScriptFile -EKSClusterName "${cluster_name}" -Base64ClusterServiceToken "${cluster_auth_base64}" -APIServerEndpoint "${cluster_endpoint}" ${bootstrap_extra_args} 3>&1 4>&1 5>&1 6>&1
</powershell>
