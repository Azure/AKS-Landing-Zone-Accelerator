# Deploy a Basic Workload using the Fruit Smoothie Ratings Application

This application is provided by Microsoft Learning and is used as part of a self-paced Kubernetes training [workshop](https://docs.microsoft.com/en-us/learn/modules/aks-workshop/).  You may find reviewing that workshop helpful as it presents some alternative deployment options and features using different architecture requirements. The application consists of a web frontend, an API service and a MongoDB database.

Because the infrastructure has been deployed in a secure manner, only the API server to the AKS Cluster is accessible outside of the private network.  You will need to perform the majority of the application deployment from the Dev Jumpbox in the Hub VNET, connect via the Bastion Host service. If your computer is connected to the hub network, you may be able to just use that as well.

## Connecting to the Bastion Host

1. Log into Azure portal and find the virtual machine you created in the create hub network step. It should be in the *escs-hub-rg-dev* resource group if you used the default naming convention
2. Click on **Connect** at the top of the screen and select **Bastion**
3. Click on the **Use Bastion** button
4. Enter the username and password. It should be in the terraform.tfvars file in the Network Hub folder
5. Click on the **Connect** button. 

Once you connect ensure you permit the site to read the content of your clipboard

Install the following applications:

2. AZ CLIto 

   ```
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   ```

2. Docker

   ```
   sudo apt install docker.io
   ```

   

3. [Kubernetes CLI](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)

4. [Helm]([Helm | Installing Helm](https://helm.sh/docs/intro/install/))

Once connected, install the Azure CLI and log into Azure. You must be a member of the appropriate
group (AKS App Dev Users, AKS Operations) to access the cluster. 

```
az login -t <tenant id>
```

**NOTE**: When you run az login, do not attempt to copy the code from the jump box as entering ctrl+c to copy it may cancel the login process. Instead, manually enter the code into https://www.microsoft.com/devicelogin page.

ensure you are connected to the correct subscription

```
az account set --subscription <subscription id>
```

OPTIONAL: If you need to log in with a service account:

```
az login --service-principal --username "${applicationId}" --password "${password}" --tenant "${tenantID}"
```

## Connect the Container Registry Private link to the Hub network

Since the Container registry can only be accessed via private link, we need to connect it to the network where jumpbox or whichever computer we are using to create the container images resides. We already added the container registry to the spoke network where the cluster resides using terraform. 

1. Find the ....
2. 

## Build Container Images

Set your environmental variables

```
AKSCLUSTERNAME=aks-escs
AKSRESOURCEGROUP=escs-lz01-rg-aks
```

Clone the required repos to the Dev Jumpbox:

1. This repo. Feel free to use your forked repo as well.
```
git clone https://github.com/Azure/Enterprise-Scale-for-AKS
```
2. The Ratings API repo
```
git clone https://github.com/MicrosoftDocs/mslearn-aks-workshop-ratings-api.git
```
3. The Ratings Web repo
```
git clone https://github.com/MicrosoftDocs/mslearn-aks-workshop-ratings-web.git
```

Navigate to each of the application code directories, build and tag the containers with the name of your Azure Container Registry and push the images to ACR.

```
sudo docker build . -t <acrname>.azurecr.io/ratings-api:v1
sudo docker build . -t <acrname>.azurecr.io/ratings-web:v1
```

Log into ACR

```
az acr login
```

Push the images into the container registry. Ensure you are logged in u

```
sudo docker push <acrname>.azurecr.io/ratings-api:v1
sudo docker push <acrname>.azurecr.io/ratings-web:v1
```



Create the secret in keyvault if you havent already

```
az keyvault secret set --name mongodburi --vault-name acr78860-akscs --value "mongodb://<username>:Awesomepassword2@ratings-mongodb.ratingsapp:27017/ratingsdb"

az keyvault secret set --name mongodburi --vault-name kv78860-akscs --value "mongodb://dbadmin:Awesomepassword2@ratings-mongodb.ratingsapp:27017/ratingsdb"

helm install ratings bitnami/mongodb --namespace ratingsapp --set auth.username=dbadmin,auth.password=Awesomepassword2,auth.database=ratingsdb
```

## Deploy the workload unto the cluster

You can deploy the workload into the cluster using your local computer since this is not a private cluster. This is not a very secure option. For better security, use a private cluster. We have a private cluster scenario in this repository. We are using a non private cluster for training purposes and for cases where you may not want to use a private cluster. It is easier to perform the following steps using your local computer since, it would be easy to modify the deployment files as needed. 

Get the connection credentials for the cluster:

```
az aks get-credentials --name $AKSCLUSTERNAME --resource-group $AKSRESOURCEGROUP
```



On the Kubernetes cluster, create a namespace for the Ratings Application. 

```
kubectl create namespace ratingsapp
```

The MongoDB backend application is installed using Helm. You may use anything you'd like for the username and password for the MongoDB database, however that needs to be reflected in the connection string that is placed in Key Vault.

```
helm repo add bitnami https://charts.bitnami.com/bitnami

helm install ratings bitnami/mongodb --namespace ratingsapp --set auth.username=<username>,auth.password=<password>,auth.database=ratingsdb
```

Navigate to "/Scenarios/Secure-Baseline/Apps/RatingsApp" folder. 
```
cd ../Apps/RatingsApp
```
Update the "api-secret-provider-class.yaml" file to reflect the correct Key Vault name, Client ID for the AKS Key Vault Add-on and the Tenant ID for the subscription.  Deploy the edited yaml file.

Update the "1-ratings-api-deployment.yaml" file to reflect the correct name for the Azure Container Registry.  Deploy the file.

Deploy the "2-ratings-api-service.yaml" file.

Update the "3-ratings-web-deployment.yaml" file to reflect the correct name for the Azure Container Registry. Deploy the file. 

Deploy the "4-ratings-web-serivce.yaml" file.

Deploy the "5a-ratings-web-ingress.yaml" file.

Browse to the IP address of the external IP for the Application Gateway.

