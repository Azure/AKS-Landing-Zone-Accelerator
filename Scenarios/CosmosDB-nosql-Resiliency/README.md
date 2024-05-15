region1=swedencentral
region2=eastus
deploymentName=SimpleEcom
aksnamespace=simpleecom

currentUserGuid=$(az ad signed-in-user show --query id -o tsv ) 
az ad group create --display-name AKSClusterAdmins --mail-nickname AKSClusterAdmins --description "Members who can administer AKS Clusters"
$aksAdminsGroupId = az ad group show --group AKSClusterAdmins --query id -o tsv
az ad group member add --group $aksAdminsGroup --member-id $currentUserGuid

az deployment sub create -n $deploymentName -l $region1   -f main.bicep -p parameters.json -p secondLocation=$region2 -p aksAdminsGroupId=$aksAdminsGroupId -p resourceGroupName=SimpleEcomRGGGG

RGNAME=$(az deployment sub show --name $deploymentName --query properties.outputs.resourceGroupName.value -o tsv) && echo "The resource group name is: $RGNAME"
<!-- RGNAMECLUSTERTWO=$(az deployment sub show --name $deploymentName --query properties.outputs.rgSecondClusterName.value -o tsv) && echo "The resource group name is: $RGNAME" -->

ACRNAME=$(az deployment sub show --name $deploymentName --query properties.outputs.acrName.value -o tsv) && echo "The ACR name is: $ACRNAME"

FIRSTCLUSTERNAME=$(az deployment sub show --name $deploymentName --query properties.outputs.firstAKSCluseterName.value -o tsv) && echo "The first cluster's name is: $FIRSTCLUSTERNAME"

SECONDCLUSTERNAME=$(az deployment sub show --name $deploymentName --query properties.outputs.secondAKSCluseterName.value -o tsv) && echo "The second clusters name is: $SECONDCLUSTERNAME"

az aks update -n $FIRSTCLUSTERNAME -g $RGNAME --attach-acr $ACRNAME
az aks update -n $SECONDCLUSTERNAME -g $RGNAME --attach-acr $ACRNAME

FIRSTOIDCISSUERURL=$(az deployment sub show --name $deploymentName --query properties.outputs.firstoidcIssuerUrl.value -o tsv) && echo "The OIDC Issue URL is: $FIRSTOIDCISSUERURL"
SECONDOIDCISSUERURL=$(az deployment sub show --name $deploymentName --query properties.outputs.secondoidcIssuerUrl.value -o tsv) && echo "The OIDC Issue URL is: $SECONDOIDCISSUERURL"
workloadIdentityId=$(az deployment sub show -n $deploymentName  --query properties.outputs.workloadIdentityResourceId.value -o tsv) && echo "The workloadIdentityId is: $workloadIdentityId"
IDNAME=$(az deployment sub show --name $deploymentName --query properties.outputs.workloadIdentityName.value -o tsv) && echo "The identity name  is: $IDNAME"
CLIENT_ID=$(az deployment sub show --name $deploymentName --query properties.outputs.workloadIdentityClientId.value -o tsv) && echo "The identity client id is: $CLIENT_ID"


az identity federated-credential create --name aksfederatedidentity --identity-name $IDNAME --resource-group $RGNAME --issuer $FIRSTOIDCISSUERURL --subject system:serviceaccount:simpleecom:serversa
az identity federated-credential create --name aksfederatedidentity --identity-name $IDNAME --resource-group $RGNAME --issuer $FIRSTOIDCISSUERURL --subject system:serviceaccount:simpleecom:serversa

