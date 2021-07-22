

az deployment sub create --location 'uksouth' --template-file './deploy.bicep' --parameters '@./modules/virtualNetwork/vnet.parameters.json' '@./modules/DdosProtectionPlans/ddos.parameters.json'