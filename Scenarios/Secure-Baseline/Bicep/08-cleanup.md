# Cleanup

To clean up run the below az cli \ Az PowerShell commands

# [CLI](#tab/CLI)

```azurecli
# Clean Up
az group delete -n ESLZ-HUB -y
az group delete -n ESLZ-SPOKE -y
# Delete Deployments
az deployment sub delete -n ESLZ-HUB-AKS
az deployment sub delete -n ESLZ-AKS-HUB-UDR
az deployment sub delete -n ESLZ-HUB-VM
az deployment sub delete -n ESLZ-Spoke-AKS
az deployment sub delete -n ESLZ-AKS-SPOKE-UDRNSG
az deployment sub delete -n ESLZ-AKS-Supporting
az deployment sub delete -n ESLZ-AKS-CLUSTER
```

# [PowerShell](#tab/PowerShell)

```azurepowershell
# Delete Resource Groups
Remove-AzResourceGroup -Name ESLZ-HUB
Remove-AzResourceGroup -Name ESLZ-SPOKE
# Delete Deployments
Remove-AzSubscriptionDeployment -Name ESLZ-HUB-AKS
Remove-AzSubscriptionDeployment -Name ESLZ-AKS-HUB-UDR
Remove-AzSubscriptionDeployment -Name ESLZ-HUB-VM
Remove-AzSubscriptionDeployment -Name ESLZ-Spoke-AKS
Remove-AzSubscriptionDeployment -Name ESLZ-AKS-SPOKE-UDRNSG
Remove-AzSubscriptionDeployment -Name ESLZ-AKS-Supporting
Remove-AzSubscriptionDeployment -Name ESLZ-AKS-CLUSTER
```