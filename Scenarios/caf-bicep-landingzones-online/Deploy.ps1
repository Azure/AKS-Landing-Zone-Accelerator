Parameters(
[string]$RG_NAME    
)

az deployment sub create --location '' --template-file './deploy.bicep' --parameters '@./Modules/virtualNetwork/vnet.parameters.json'