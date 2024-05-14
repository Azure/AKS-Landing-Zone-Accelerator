region1=swedencentral
region2=eastus
deploymentName=all-in-one

currentUserGuid = az ad signed-in-user show --query id -o tsv  
az ad group create --display-name AKSClusterAdmins --mail-nickname AKSClusterAdmins --description "Members who can administer AKS Clusters"
$aksAdminsGroupId = az ad group show --group AKSClusterAdmins --query id -o tsv
az ad group member add --group $aksAdminsGroup --member-id $currentUserGuid

az deployment sub create -n $deploymentName -l $region1 -region2 --secondLocation $region2 -f main.bicep -p parameters.json

FIRSTOIDCISSUERURL=$(az deployment sub show --name $deploymentName --query properties.outputs.firstoidcIssuerUrl.value -o tsv) && echo "The OIDC Issue URL is: $FIRSTOIDCISSUERURL"
SECONDOIDCISSUERURL=$(az deployment sub show --name $deploymentName --query properties.outputs.secondoidcIssuerUrl.value -o tsv) && echo "The OIDC Issue URL is: $SECONDOIDCISSUERURL"
workloadIdentityId=(az deployment sub show -n $deploymentName  --query properties.outputs.workloadIdentityResourceId.value -o tsv)
IDNAME=$(az deployment sub show --name $deploymentName --query properties.outputs.workloadIdentityName.value -o tsv) && echo "The identity name  is: $IDNAME"
CLIENT_ID=$(az deployment sub show --name $deploymentName --query properties.outputs.workloadIdentityClientId.value -o tsv) && echo "The identity client id is: $CLIENT_ID"
RGNAME=$(az deployment sub show --name $deploymentName --query properties.outputs.resourceGroupName.value -o tsv) && echo "The resource group name is: $RGNAME"


az identity federated-credential create --name aksfederatedidentity --identity-name $IDNAME --resource-group $RGNAME --issuer $FIRSTOIDCISSUERURL --subject system:serviceaccount:simpleecom:serversa
az identity federated-credential create --name aksfederatedidentity --identity-name $IDNAME --resource-group $RGNAME --issuer $FIRSTOIDCISSUERURL --subject system:serviceaccount:simpleecom:serversa