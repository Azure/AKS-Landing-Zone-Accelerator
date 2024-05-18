```bash
region1=eastus
region2=swedencentral
deploymentName=SimpleEcomsss
aksnamespace=simpleecom
RGNAME=SimpleEcomRGROUPS

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

ACRNAME=$(az deployment sub show --name $deploymentName --query properties.outputs.acrName.value -o tsv) && echo "The ACR name is: $ACRNAME"

cosmosDbName=$(az deployment sub show --name $deploymentName --query properties.outputs.cosmosDbName.value -o tsv) && echo "The Cosmosdb name is: $cosmosDbName"


FIRSTCLUSTERNAME=$(az deployment sub show --name $deploymentName --query properties.outputs.firstAKSCluseterName.value -o tsv) && echo "The first cluster's name is: $FIRSTCLUSTERNAME"

SECONDCLUSTERNAME=$(az deployment sub show --name $deploymentName --query properties.outputs.secondAKSCluseterName.value -o tsv) && echo "The second clusters name is: $SECONDCLUSTERNAME"

# attach your acr to the aks clusters
az aks update -n $FIRSTCLUSTERNAME -g $RGNAME --attach-acr $ACRNAME
az aks update -n $SECONDCLUSTERNAME -g $RGNAME --attach-acr $ACRNAME


echo $ACRNAME
echo $cosmosDbName
echo $FIRSTCLUSTERNAME
echo $SECONDCLUSTERNAME


# Get the information required to create the federated identity crdentials
FIRSTOIDCISSUERURL=$(az deployment sub show --name $deploymentName --query properties.outputs.firstoidcIssuerUrl.value -o tsv) && echo "The first OIDC Issuer URL is: $FIRSTOIDCISSUERURL"
SECONDOIDCISSUERURL=$(az deployment sub show --name $deploymentName --query properties.outputs.secondoidcIssuerUrl.value -o tsv) && echo "The second OIDC Issuer URL is: $SECONDOIDCISSUERURL"
workloadIdentityId=$(az deployment sub show -n $deploymentName  --query properties.outputs.workloadIdentityResourceId.value -o tsv) && echo "The workloadIdentityId is: $workloadIdentityId"
IDNAME=$(az deployment sub show --name $deploymentName --query properties.outputs.workloadIdentityName.value -o tsv) && echo "The identity name  is: $IDNAME"
OBJECT_ID=$(az deployment sub show --name $deploymentName --query properties.outputs.workloadIdentityObjectId.value -o tsv) && echo "The identity object id is: $OBJECT_ID"
CLIENT_ID=$(az deployment sub show --name $deploymentName --query properties.outputs.workloadIdentityClientId.value -o tsv) && echo "The identity client id is: $CLIENT_ID"

# create federated credentials for both clusters using the same MI
az identity federated-credential create --name aksfederatedidentity --identity-name $IDNAME --resource-group $RGNAME --issuer $FIRSTOIDCISSUERURL --subject system:serviceaccount:simpleecom:serversa
az identity federated-credential create --name aksfederatedidentityreg2 --identity-name $IDNAME --resource-group $RGNAME --issuer $SECONDOIDCISSUERURL --subject system:serviceaccount:simpleecom:serversa

# Grant your managed identity access to read cosmosdb data. Scope / means you are granting it access to the entire cosmosdb instance
az cosmosdb sql role assignment create \
    --resource-group $RGNAME \
    --account-name $cosmosDbName  \
    --role-definition-name "Cosmos DB Built-in Data Contributor" \
    --principal-id $OBJECT_ID \
    --scope /

# enable webapp routing addon. 
az aks approuting enable --resource-group $RGNAME --name $FIRSTCLUSTERNAME
az aks approuting enable --resource-group $RGNAME --name $SECONDCLUSTERNAME

# connect to the first cluster
az aks get-credentials -n $FIRSTCLUSTERNAME -g $RGNAME
# az aks get-credentials -n $SECONDCLUSTERNAME -g $RGNAME

# Deploy the images to ACR
cd ../simpleecomapp/src

az acr build --registry $ACRNAME --image frontend:v1 --file frontend/Dockerfile frontend
az acr build --registry $ACRNAME  --image dataprep:v1 --file prepdata/Dockerfile prepdata
az acr build --registry $ACRNAME  --image auth:v1 --file Simpleecom.Auth/Dockerfile .
az acr build --registry $ACRNAME  --image carts:v1 --file Simpleecom.Cart.API/Dockerfile .
az acr build --registry $ACRNAME  --image orders:v1 --file Simpleecom.Orders.API/Simpleecom.Orders.API/Dockerfile .
az acr build --registry $ACRNAME  --image products:v1 --file Simpleecom.Products.API/Dockerfile .

az acr repository list --name $ACRNAME --output table # make sure you have 6 images


###########################################################
#  MATT YOU MIGHT NEED HELP WITH EVERYTHING BELOW HERE SO MAYBE STOP HERE AND MOVE ON TO ADDING THE FLEET MANAGER TO THE 04 MODULE ALONG WITH AKSCLUSTERREGION2. YOU CAN USE REGION2 AS THE REGION FOR THE FLEET MANAGER AND USE THE REGION2'S NETWORK 
# AS ITS NETWORK IF THAT WORKS

# deploy the codes (make sure you update your manifest files first with correct tenant, and clientid in svc-account and acr in the deployment files)

TENANTID=<your Azure tenant id>

COSMOSDB_URI=https://cosmosdbqes3guu77ovag.documents.azure.com:443/

COSMOSDB_CONN_ST=""

# update deployment files with correct acr name
sed -i "s/<acr-name>/${ACRNAME}/g" auth.yaml
sed -i "s/<acr-name>/${ACRNAME}/g" carts.yaml
sed -i "s/<acr-name>/${ACRNAME}/g" dataprep.yaml
sed -i "s/<acr-name>/${ACRNAME}/g" orders.yaml
sed -i "s/<acr-name>/${ACRNAME}/g" products.yaml
sed -i "s/<acr-name>/${ACRNAME}/g" frontend.yaml

# update deployment files with correct conn string
sed -i "s|<cosmosdb-conn-string>|${COSMOSDB_CONN_ST}|g" auth.yaml
sed -i "s|<cosmosdb-conn-string>|${COSMOSDB_CONN_ST}|g" carts.yaml
sed -i "s|<cosmosdb-conn-string>|${COSMOSDB_CONN_ST}|g" orders.yaml
sed -i "s|<cosmosdb-conn-string>|${COSMOSDB_CONN_ST}|g" products.yaml


# update deployment files with correct cosmosdb endpoint
sed -i "s|<cosmosdb endpoint>|${COSMOSDB_URI}|g" auth.yaml
sed -i "s|<cosmosdb endpoint>|${COSMOSDB_URI}|g" carts.yaml
sed -i "s|<cosmosdb endpoint>|${COSMOSDB_URI}|g" orders.yaml
sed -i "s|<cosmosdb endpoint>|${COSMOSDB_URI}|g" products.yaml

# now lets use managed identity
sed -i "s|false|true|g" auth.yaml
sed -i "s|false|true|g" carts.yaml
sed -i "s|false|true|g" orders.yaml
sed -i "s|false|true|g" products.yaml

sed -i "s| #||g" auth.yaml
sed -i "s| #||g" carts.yaml
sed -i "s| #||g" orders.yaml
sed -i "s| #||g" products.yaml

sed -i "s|Development|Non-dev|g" auth.yaml
sed -i "s|Development|Non-dev|g" carts.yaml
sed -i "s|Development|Non-dev|g" orders.yaml
sed -i "s|Development|Non-dev|g" products.yaml




# update the service account with correct tenantid and client id
sed -i "s/<tenant-id>/${TENANTID}/g" svc-account.yaml
sed -i "s/<client-id>/${CLIENT_ID}/g" svc-account.yaml

sed -i "s/<acr-name>/${ACRNAME}/g" products.yaml

sed -i "s/<acr-name>/${ACRNAME}/g" frontend.yaml



alias k=kubectl
kubectl apply -f namespace.yaml
kubectl apply -f nginx-ingress.yaml
kubectl apply -f svc-account.yaml
kubectl apply -f frontend.yaml
kubectl apply -f auth.yaml


kubectl delete -f auth.yaml
kubectl apply -f auth.yaml





FIRSTCLUSTERNAME=aksclusterRegion1
SECONDCLUSTERNAME=aksclusterRegion2
RGNAME=SimpleEcomRGROUPSs
az aks get-credentials -n $FIRSTCLUSTERNAME -g $RGNAME
cd ../../k8s
kubectl apply -f .
kubectl apply -f .








