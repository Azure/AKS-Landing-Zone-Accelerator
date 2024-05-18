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

# Build images and push to ACR
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
COSMOSDB_CONN_ST=<your cosmosdb connection string> # get this from Cosmosdb -> Settings -> Keys


# Deploy the namespace
cd ../../k8s
kubectl apply -f namespace.yaml

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

# Deploy the containers
kubectl apply -f nginx-ingress.yaml # enabled by the webapp routing feature
kubectl apply -f dataprep.yaml
kubectl apply -f frontend.yaml
kubectl apply -f auth.yaml
kubectl apply -f carts.yaml
kubectl apply -f products.yaml
kubectl apply -f orders.yaml

# set context of your kubectl to the namespace we are using simpleecom 
kubectl config set-context --current --namespace=simpleecom

# Get ingress's public ip address
kubectl get ingress

# Go to browser and enter this address to Load the product catalog into your database: http://<your ingress ip address>/prepdata/send_data

# Go on browser and enter the address to test out the app: http://<your ingress ip address>. You need to sign up first by clicking on Registration page.

# NOW lets use managed identity

# First update the service account with correct tenantid and client id
sed -i "s/<tenant-id>/${TENANTID}/g" svc-account.yaml
sed -i "s/<client-id>/${CLIENT_ID}/g" svc-account.yaml

# deploy the service account
kubectl apply -f svc-account.yaml

# eable the use of the service account on your pods
sed -i "s|false|true|g" auth.yaml
sed -i "s|false|true|g" carts.yaml
sed -i "s|false|true|g" orders.yaml
sed -i "s|false|true|g" products.yaml

sed -i "s| #||g" auth.yaml
sed -i "s| #||g" carts.yaml
sed -i "s| #||g" orders.yaml
sed -i "s| #||g" products.yaml

# Get your pod to use default credentials instead of Cosmosdb connection string by switching the ASPNETCORE_ENVIRONMENT env variable from Development to Non-dev. This will allow the use of the managed identity we configured earlier to autheticate to the data plane of cosmosdb. Safer than using secrets. Thanks for AKS workload identity, only pods that need access to the database will have access to this service account. So frontend and dataprep, which dont need access to the database wont have access to cosmosdb.
# When using workload identity, the pods can only handle data plane operations, so stuff like creating
# database and collections on cosmosdb are not allowed. We expect that the IT team would have set this 
# up for you anyway. But for demo purposes we started by using the Development mode with the connection
# string so that our code can setup the database for you. Going forward the pods wont have access 
# to do this anymore.
sed -i "s|Development|Non-dev|g" auth.yaml
sed -i "s|Development|Non-dev|g" carts.yaml
sed -i "s|Development|Non-dev|g" orders.yaml
sed -i "s|Development|Non-dev|g" products.yaml

# Redeploy the pods so that they now use the service account's workload identity
kubectl apply -f auth.yaml
kubectl apply -f carts.yaml
kubectl apply -f products.yaml
kubectl apply -f orders.yaml

# Make sure the pods restarted. If they didnt delete the deployments and redeploy

