# Deploying the Workload
A suggested example workload for the cluster is detailed in this MS Learning Workshop https://docs.microsoft.com/en-us/learn/modules/aks-workshop/. 

To deploy this workload, you will need to be able to access the Azure Container Registry that was deployed as part of the supporting infrastructure for AKS.  The container registry was configured to only be accessible from a build agent on the private network. 

If you use the Dev Server for this, the following tools must be installed:
1. Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
For complete instuctions visit https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt
2. Docker CLI
apt install docker.io

You will need to clone the following repos:

1. The public repo for the Fruit Smoothie API.  
git clone https://github.com/MicrosoftDocs/mslearn-aks-workshop-ratings-api.git

2. The public repo for the Fruit Smootie Web Frontend:
git clone https://github.com/MicrosoftDocs/mslearn-aks-workshop-ratings-web.git

3. This repo!

/Enterprise-Scale-for-AKS/Scenarios/Secure-Baseline/Terraform/08-Workload$ 


Once the Azure CLI is installed, log into Azure. You must be a member of the appropriate
group (AKS App Dev Users, AKS Operations) to access the cluster:

az login

If you need to log in with a serice account:

az login --service-principal --username "${applicationId}" --password "${password}" --tenant "${tenantID}"

Get the connection credentials for the cluster:

az aks get-credentials --name MyManagedCluster --resource-group MyResourceGroup

az aks get-credentials --name aks-escs -g escs-lz01-rg-aks

Install the kubectl CLI:

az aks install-cli



----------------

kubectl create namespace ratingsapp

az acr build --resource-group escs-lz01-rg --registry acr60273 --image ratings-api:v1 .
az acr build --resource-group escs-lz01-rg --registry acr60273 --image ratings-web:v1 .

docker build . -t acr60273.azurecr.io/ratings-api:v1
docker build . -t acr60273.azurecr.io/ratings-web:v1

docker push acr60273.azurecr.io/ratings-api:v1

az aks update --name aks-escs --resource-group escs-lz01-rg-aks --attach-acr acrescs

helm repo add bitnami https://charts.bitnami.com/bitnami

helm install ratings bitnami/mongodb --namespace ratingsapp --set auth.username=dbadmin,auth.password=Passw0rd1,auth.database=ratingsdb

kubectl create secret generic mongosecret --namespace ratingsapp --from-literal=MONGOCONNECTION="mongodb://dbadmin:Passw0rd1@ratings-mongodb.ratingsapp:27017/ratingsdb"

kubectl apply --namespace ratingsapp -f 1-ratings-api-deployment.yaml
kubectl apply --namespace ratingsapp -f 2-ratings-api-service.yaml

kubectl apply --namespace ratingsapp -f 3-ratings-web-deployment.yaml
kubectl apply --namespace ratingsapp -f 4-ratings-web-service.yaml

https://raw.githubusercontent.com/Azure/application-gateway-kubernetes-ingress/master/docs/examples/aspnetapp.yaml -o aspnetapp.yaml






