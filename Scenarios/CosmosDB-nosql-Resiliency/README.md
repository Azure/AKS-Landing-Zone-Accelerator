```bash
region1=eastus
region2=swedencentral
deploymentName=SimpleEcoms
aksnamespace=simpleecom
RGNAME=SimpleEcomRGROUP

currentUserGuid=$(az ad signed-in-user show --query id -o tsv ) 
az ad group create --display-name AKSCADMs --mail-nickname AKSCADMs --description "Members who can administer AKS Clusters"
aksAdminsGroupId=$(az ad group show --group AKSCADMs --query id -o tsv)
az ad group member add --group $aksAdminsGroup --member-id $currentUserGuid

# make sure your env variables were configured properly
echo "deplyment name is :" && echo $deploymentName
echo "region 1 is :" && echo $region1
echo "region 2 is: " && echo $region2
echo "aks admin group id is: " && echo $aksAdminsGroupId
echo "main rg name is: " && echo $RGNAME

cd Scenarios/CosmosDB-nosql-Resiliency/Bicep


az deployment sub create -n $deploymentName -l $region1   -f main.bicep -p parameters.json -p secondLocation=$region2 -p aksAdminsGroupId=$aksAdminsGroupId -p resourceGroupName=$RGNAME

# get required env variables for remaining steps

RGNAME=$(az deployment sub show --name $deploymentName --query properties.outputs.resourceGroupName.value -o tsv) && echo "The resource group name is: $RGNAME"
<!-- RGNAMECLUSTERTWO=$(az deployment sub show --name $deploymentName --query properties.outputs.rgSecondClusterName.value -o tsv) && echo "The resource group name is: $RGNAME" -->

ACRNAME=$(az deployment sub show --name $deploymentName --query properties.outputs.acrName.value -o tsv) && echo "The ACR name is: $ACRNAME"

cosmosDbName=$(az deployment sub show --name $deploymentName --query properties.outputs.cosmosDbName.value -o tsv) && echo "The ACR name is: $cosmosDbName"


FIRSTCLUSTERNAME=$(az deployment sub show --name $deploymentName --query properties.outputs.firstAKSCluseterName.value -o tsv) && echo "The first cluster's name is: $FIRSTCLUSTERNAME"

SECONDCLUSTERNAME=$(az deployment sub show --name $deploymentName --query properties.outputs.secondAKSCluseterName.value -o tsv) && echo "The second clusters name is: $SECONDCLUSTERNAME"

# attach your acr to the aks clusters
az aks update -n $FIRSTCLUSTERNAME -g $RGNAME --attach-acr $ACRNAME
az aks update -n $SECONDCLUSTERNAME -g $RGNAME --attach-acr $ACRNAME


# create federated credentials for both clusters using the same MI
FIRSTOIDCISSUERURL=$(az deployment sub show --name $deploymentName --query properties.outputs.firstoidcIssuerUrl.value -o tsv) && echo "The OIDC Issue URL is: $FIRSTOIDCISSUERURL"
SECONDOIDCISSUERURL=$(az deployment sub show --name $deploymentName --query properties.outputs.secondoidcIssuerUrl.value -o tsv) && echo "The OIDC Issue URL is: $SECONDOIDCISSUERURL"
workloadIdentityId=$(az deployment sub show -n $deploymentName  --query properties.outputs.workloadIdentityResourceId.value -o tsv) && echo "The workloadIdentityId is: $workloadIdentityId"
IDNAME=$(az deployment sub show --name $deploymentName --query properties.outputs.workloadIdentityName.value -o tsv) && echo "The identity name  is: $IDNAME"
workloadIdentityObjectId
OBJECT_ID=$(az deployment sub show --name $deploymentName --query properties.outputs.workloadIdentityObjectId.value -o tsv) && echo "The identity client id is: $CLIENT_ID"
CLIENT_ID=$(az deployment sub show --name $deploymentName --query properties.outputs.workloadIdentityClientId.value -o tsv) && echo "The identity client id is: $CLIENT_ID"

az identity federated-credential create --name aksfederatedidentity --identity-name $IDNAME --resource-group $RGNAME --issuer $FIRSTOIDCISSUERURL --subject system:serviceaccount:simpleecom:serversa
az identity federated-credential create --name aksfederatedidentity --identity-name $IDNAME --resource-group $RGNAME --issuer $FIRSTOIDCISSUERURL --subject system:serviceaccount:simpleecom:serversa

# Grant your managed identity access to read cosmosdb data
az cosmosdb sql role assignment create \
    --resource-group $RGNAME \
    --account-name  \
    --role-definition-name "Cosmos DB Built-in Data Contributor" \
    --principal-id $OBJECT_ID \
    --scope /

# enable webapp routing addon. (MATT if you can make this webapp routing enabled within bicep please make the change in the 03 and 04 folders. The current webApplicationRoutingEnabled: true glag he used isnt working)
az aks approuting enable --resource-group $RGNAME --name $FIRSTCLUSTERNAME
az aks approuting enable --resource-group $RGNAME --name $SECONDCLUSTERNAME

# Deploy the images to ACR
cd ../simpleecomapp/src

az acr build --registry $ACRNAME --image frontend:v1 --file frontend/Dockerfile frontend
az acr build --registry $ACRNAME  --image dataprep:v1 --file prepdata/Dockerfile prepdata
az acr build --registry $ACRNAME  --image auth:v1 --file Simpleecom.Auth/Dockerfile .
az acr build --registry $ACRNAME  --image carts:v1 --file Simpleecom.Cart.API/Dockerfile .
az acr build --registry $ACRNAME  --image orders:v1 --file Simpleecom.Orders.API/Simpleecom.Orders.API/Dockerfile .
az acr build --registry $ACRNAME  --image products:v1 --file Simpleecom.Products.API/Dockerfile .


###########################################################
#  MATT YOU MIGHT NEED HELP WITH EVERYTHING BELOW HERE SO MAYBE STOP HERE AND MOVE ON TO ADDING THE FLEET MANAGER TO THE 04 MODULE ALONG WITH AKSCLUSTERREGION2. YOU CAN USE REGION2 AS THE REGION FOR THE FLEET MANAGER AND USE THE REGION2'S NETWORK 
# AS ITS NETWORK IF THAT WORKS

# deploy the codes (make sure you update your manifest files first with correct tenant, and clientid in svc-account and acr in the deployment files)
az aks get-credential -n $FIRSTCLUSTERNAME -g $RGNAME
cd ../../k8s
kubectl apply -f .
kubectl apply -f .


```

ignore below

FIRSTCLUSTERNAME=aksclusterRegion1
SECONDCLUSTERNAME=aksclusterRegion2
workloadIdentityId=d8484a34-9fbe-43c1-894b-462112f36b33
IDNAME=aksWorkloadIdentity 
CLIENT_ID=46e4ed7c-ea0e-4cce-892a-6334f9b0ef10
ACRNAME=akssupportingxaz2lgqe2tj3o
RGNAME=SimpleEcomRGHHKJ
az aks update -n testytesttt -g $RGNAME --attach-acr $ACRNAME

az aks get-credential -n $FIRSTCLUSTERNAME -g $RGNAME





