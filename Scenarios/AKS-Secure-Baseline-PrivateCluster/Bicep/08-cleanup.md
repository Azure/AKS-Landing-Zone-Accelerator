# Cleanup

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
New-AzSubscriptionDeployment -TemplateFile .\main.bicep -TemplateParameterFile .\parameters-main.json -Location "CentralUS"
```