# Deploy a Basic Workload using the Fruit Smoothie Ratings Application

This application is provided by Microsoft Learning and is used as part of a self-paced Kubernetes training [workshop](https://docs.microsoft.com/en-us/learn/modules/aks-workshop/). You may find reviewing that workshop helpful as it presents some alternative deployment options and features using different architecture requirements. The application consists of a web frontend, an API service and a MongoDB database.

Because the infrastructure has been deployed in a private AKS cluster setup with private endpoints for the container registry and other components, you will need to perform the application container build and the publishing to the Container Registry from the Dev Jumpbox in the Hub VNET, connecting via the Bastion Host service. If your computer is connected to the hub network, you may be able to just use that as well. The rest of the steps can be performed on your local machine by using AKS Run commands which allow access into private clusters using RBAC. This will help with improving security and will provide a more user-friendly way of editing YAML files.

## Prepare your Jumpbox VM with tools (run from local machine) // validate this step because of previous error

* Add a rule in the Firewall to allow internet access to the VM's private IP. Verify VM's private IP and update if necessary

   ```bash
   az network firewall network-rule create --collection-name 'VM-egress' --destination-ports '*' --firewall-name 'vnet-ESLZ-firewall' --name 'Allow-Internet' --protocols Any --resource-group 'ESLZ-HUB' --action Allow --dest-addr '*' --priority 201 --source-addresses '10.0.3.4/32'
   ```
* Add a rule in the Firewall to allow internet access to the your VM or computer's  IP. Verify VM's private IP and update if necessary

   ```bash
   az network firewall network-rule create --collection-name 'VM-egress' --destination-ports '*' --firewall-name 'AZFW' --name 'Allow-Internet' --protocols Any --resource-group 'ESLZ-HUB' --action Allow --dest-addr '*' --priority 201 --source-addresses '<your vm or computer's ip>'
   ```
## Connecting to the Bastion Host

1. Use Bastion Host to connect to the jumpbox.
2. Enter the username and password. If you have used a public key, then select upload private key (corresponding to the public key) to connect.
3. Once you connect ensure you permit the site to read the content of your clipboard

* Clone it on the jumpbox.

   ```bash
   git clone https://github.com/Azure/AKS-Landing-Zone-Accelerator
   ```

* Run the script below to install the required tools (Az CLI, Docker, Kubectl, Helm etc). Navigate to "AKS-Landing-Zone-Accelerator/Scenarios/AKS-Secure-Baseline-PrivateCluster/Terraform/04-Network-Hub" folder.

   ```bash
   cd AKS-Landing-Zone-Accelerator/Scenarios/AKS-Secure-Baseline-PrivateCluster/Terraform/04-Network-Hub
   chmod +x script.sh
   sudo ./script.sh
   ```

* Login to Azure

   ```bash
   TENANTID=<tenant id>
   az login -t $TENANTID --debug
   ```

* Ensure you are connected to the correct subscription

   ```bash
   az account set --subscription <subscription id>
   ```

## Connect the Container Registry Private link to the Hub network

Since the Container registry can only be accessed via private link, we need to connect it to the network where jumpbox or whichever computer we are using to create the container images resides. We already added the container registry to the spoke network where the cluster resides using terraform.

1. Go to Azure portal

2. Find the Private DNS zone created for acr. This should be in the landing zone resource group (ESLZ-SPOKE for example)

   ![Location of private link for acr](../media/acr-privatelink-location.png)

3. Click on **Virtual network links** in the left blade under **Settings**

4. Click on **+ Add** in the in the top left of the next screen

5. enter a name for the link eg *hub_to_acr*

6. Select the hub virtual network for the **Virtual network** field

7. Click on **OK** at the bottom

## Provide yourself Access to Create Secrets in your Key vault

1. Go to the Azure portal and find your Key Vault. This should be in the landing zone resource group (ESLZ-SPOKE for example)
2. You should see your pod-identity-example managed identity  as well as the azurekeyvaultsecrets identity. The pod identity will provide pods access to the pull secrets from the keyvault. The azurekeyvaultsecrets identity will be used by the keyvault driver. If either of these are missing, perhaps you are missing a step.
3. Click on **Access policies** under **Settings** in the left blade![add access policy](../media/add-access-policy-acr.png)
4. Select the required access policies ![add access policy](../media/add-access-policy-acr2.png)
5. Under **Select principal** click on the **None selected** link and select the user group(s) you created for this to provide you and everyone in the group access to the Key vault
6. Click **Select** at the bottom of the the screen
7. **Important**: Click **Save** at the top of the next screen to save the changes ![add access policy](../media/add-access-policy-acr2.png)

## Build Container Images

Clone the required repos to the Dev Jumpbox:

1. The Ratings API repo

```bash
cd ..
git clone https://github.com/MicrosoftDocs/mslearn-aks-workshop-ratings-api.git
```

2. The Ratings Web repo
//Note on this step I had to login into github with a personal access token called AKS terraform


```bash
git clone https://github.com/MicrosoftDocs/mslearn-aks-workshop-ratings-web.git
```

Navigate to each of the application code directories, build and tag the containers with the name of your Azure Container Registry and push the images to ACR. // Make sure it is the correct ACR

```bash
# enter the name of your ACR below
SPOKERG=<resource group name for spoke>
ACRNAME=$(az acr show --name <ACR NAME> --resource-group $SPOKERG --query "name" --output tsv)
cd mslearn-aks-workshop-ratings-api
sudo docker build . -t $ACRNAME.azurecr.io/ratings-api:v1
cd ../mslearn-aks-workshop-ratings-web
sudo docker build . -t $ACRNAME.azurecr.io/ratings-web:v1
```

Log into ACR

```bash
sudo az acr login -n $ACRNAME
```

Push the images into the container registry. Ensure you are logged into the Azure Container Registry, you should show a successful login from the command above.

```bash
sudo docker push $ACRNAME.azurecr.io/ratings-api:v1
sudo docker push $ACRNAME.azurecr.io/ratings-web:v1
```

To verify they have been pushed run the following commands:

```bash
az acr repository show -n $ACRNAME --image ratings-api:v1
az acr repository show -n $ACRNAME --image ratings-web:v1
```

Create the secret in key vault. You may use anything you'd like for the username and password for the MongoDB database but this needs to match what you will use when you create the helm chart in the next steps.

**Note:** Passwords with special characters in a connection string might break the connection because of wrong encoding.

**Note:** Ensure you have access to create passwords in keyvault by going to the Key vault in Azure Portal, clicking on Access Policies and Add Access Policy. **Don't forget to hit "Save" after adding yourself or user group to Key vault access**

```bash
# update keyvault name, username and password before running the command below
KEYVAULTNAME=$(az keyvault show --name <key vault name> --resource-group $SPOKERG --query "name" --output tsv)
PGUSERNAME=<postgres db user name>
PGPASSWORD=<postgres db password>
az keyvault secret set --name mongodburi --vault-name $KEYVAULTNAME --value "mongodb://$PGUSERNAME:$PGPASSWORD@ratings-mongodb.ratingsapp:27017/ratingsdb"
```

# The following Steps can be performed using AKS Run Commands from your local machine provided you have the correct permissions.

## Deploy the database into the cluster

The following steps can be performed using AKS Run Commands from your local machine provided you have the correct permissions.

Ensure the AKS run commands are working as expected.
```bash
# create environment variable for cluster and its resource group name
ClusterRGName=<cluster resource group name>
ClusterName=<AKS cluster name>
```

```bash
az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl get nodes"
```

On the Kubernetes cluster, create a namespace for the Ratings Application.

```bash
az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl create namespace ratingsapp"
```

The MongoDB backend application is installed using Helm. Your username and password must be the same username and password using in the connection string secret that was created in Key vault in the previous step.

```bash
az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "helm repo add bitnami https://charts.bitnami.com/bitnami && helm install ratings bitnami/mongodb --namespace ratingsapp --set auth.username=$PGUSERNAME,auth.password=$PGPASSWORD,auth.database=ratingsdb"
```

## Deploy the workload into the cluster

We need to deploy the key vaults secret add on somehwere before this step, it is in the original markdown file but not this new one

In this section, you will be manipulating some of the deployment yaml files, replacing some entries related with Azure Key Vault, Azure Container Registry and Azure Active Directory references like ClientID, TenantID etc.

All files will be under the following folder: "Scenarios/AKS-Secure-Baseline-PrivateCluster/Apps/RatingsApp"

You will have to carefully update the following files:

- [api-secret-provider-class.yaml](../Apps/RatingsApp/api-secret-provider-class.yaml)
- [1-ratings-api-deployment.yaml](../Apps/RatingsApp/1-ratings-api-deployment.yaml)
- [3a-ratings-web-deployment.yaml](../Apps/RatingsApp/3a-ratings-web-deployment.yaml)
- [4-ratings-web-service.yaml](../Apps/RatingsApp/4-ratings-web-service.yaml)

### Deploy workload

Navigate to "Scenarios/AKS-Secure-Baseline-PrivateCluster/Apps/RatingsApp" folder.

1. Updating **api-secret-provider-class.yaml**

   Update the **"api-secret-provider-class.yaml"** file to reflect the correct value for the following items:

   - Key Vault name
   - Client ID for the AKS Key Vault Add-on
   - Tenant ID for the subscription.

   > If you don't have the Client ID, you can find it by going to the Key vault and clicking on **Access Policies** in the left blade. Find the identity that starts with "azurekeyvaultsecrets", then look for the resource by searching for the name in the search bar at the top. When you click on the resource, you will find the Client ID on the right side of the screen.

   Deploy the edited yaml file.

   ```bash
   az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl apply -f api-secret-provider-class.yaml -n ratingsapp" --file api-secret-provider-class.yaml
   ```

1. Updating **1-ratings-api-deployment.yaml**

   Update the **"1-ratings-api-deployment.yaml"** file to reflect the correct name for the Azure Container Registry. Deploy the file.

   ```bash
      az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl apply -f 1-ratings-api-deployment.yaml -n ratingsapp" --file 1-ratings-api-deployment.yaml
   ```

1. Ensure the ratings-api deployment was successful.

   If you don't get a running state then it is likely that the pod was unable to get the secret from Key vault. This may be because the username and password of the db doesn't match the connection string that was created in Key vault or because the proper access to the Key vault wasn't granted to the azuresecret identity.
   ```bash
   az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl get pods -n ratingsapp"
   ```
   You can troubleshoot container creation issues by running

   ```bash
   az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl describe pod <pod name> -n ratingsapp"
   az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl logs <pod name> -n ratingsapp"
   ```

1. Updating **2-ratings-api-service.yaml**

   Deploy the "2-ratings-api-service.yaml" file.

   ```bash
   az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl apply -f 2-ratings-api-service.yaml -n ratingsapp" --file 2-ratings-api-service.yaml
   ```
1. Updating **3a-ratings-web-deployment.yaml**

   Update the **"3a-ratings-web-deployment.yaml"** file to reflect the correct name for the Azure Container Registry. Deploy the file.

   ```bash
   az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl apply -f 3a-ratings-web-deployment.yaml -n ratingsapp" --file 3a-ratings-web-deployment.yaml
   ```

1. Deploy the "4-ratings-web-service.yaml" file.

   ```bash
   az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl apply -f 4-ratings-web-service.yaml -n ratingsapp" --file 4-ratings-web-service.yaml
   ```


## **(Optional)** Deploy the Ingress without support for HTTPS

This step is optional. If you would like to go straight to using https which is the secure option, skip this section and go straight to the **Update the Ingress to support HTTPS traffic** section.

It is important to first configure the NSG for the Application Gateway to accept traffic on port 80 if using the HTTP option. Run the following command to allow HTTP.

```bash
   APPGWSUBNSG=<Name of NSG for AppGwy>
   az network nsg rule create -g $SPOKERG --nsg-name $APPGWSUBNSG -n AllowHTTPInbound --priority 1000 \
      --source-address-prefixes '*' --source-port-ranges '*' \
      --destination-address-prefixes '*' --destination-port-ranges 80 --access Allow \
      --protocol Tcp --description "Allow Inbound traffic through the Application Gateway on port 80"
```

1. Deploy the **"5-ratings-web-ingress.yaml"** file.

   ```bash
   az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl apply -f 5-http-ratings-web-ingress.yaml -n ratingsapp" --file 5-http-ratings-web-ingress.yaml
   ```

1. Get the ip address of your ingress controller

   ```bash
   az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl get ingress -n ratingsapp"
   ```

### Check your deployed workload

1. Copy the ip address displayed, open a browser, navigate to the IP address obtained above from the ingress controller and explore your website

   ![deployed workload](../media/deployed-workload.png)

It is important to delete the rule that allows HTTP traffic to keep the cluster safe since we have completed the test.

```bash
   az network nsg rule delete -g $SPOKERG --nsg-name $APPGWSUBNSG -n AllowHTTPInbound
```
**the optional steps end here**

## Deploy the Ingress with HTTPS support
**Please note: This section is still in development**

A fully qualified DNS name and a certificate are needed to configure HTTPS support on the the front end of the web application. You are welcome to bring your own certificate and DNS if you have them available, however a simple way to demonstrate this is to use a self-signed certificate with an FQDN configured on the IP address used by the Application Gateway.

**Objectives**

1. Configure the Public IP address of your Application Gateway to have a DNS name. It will be in the format of customprefix.region.cloudapp.azure.com
2. Create a certificate using the FQDN and store it in Key Vault.

### Creating Public IP address for your Application Gateway

1. Find your application gateway in your landing zone resource group and click on it. By default it should be in the spoke resource group.

2. Click on the *Frontend public IP address*

   ![front end public ip address](../media/front-end-pip-link.png)

3. Click on configuration in the left blade of the resulting page.

4. Enter a unique DNS name in the field provided and click **Save**.

   ![creating nds](../media/dns-created.png)

### Create the self-signed certificate using Lets Encrypt

We are going to use Lets Encrypt and Cert-Manager to provide easy to use certificate management for the application within AKS. Cert-Manager will also handle future certificate renewals removing any manual processes.

1. First of all, you will need to install cert-manager into your cluster.

```bash
   az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.8.0/cert-manager.yaml"
```
First of all this will create a new namespace called cert-manager which is where all of the resources for cert-manager will be kept. This will then go ahead and download some CRDs (CustomResourceDefinitions) which provides extra functionality in the cluster for the creation of certificates.

We will then proceed to test this certificate process with a staging certificate to begin with, before moving on to deploying a production certificate.

2. Edit the 'certificateIssuer.yaml' file and include your email address. This will be used for certificate renewal notifications.

Deploy certificateIssuer.yaml

```bash
   az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl apply -f certificateIssuer.yaml -n ratingsapp" --file certificateIssuer.yaml
```

3. Edit the '5-https-ratings-web-ingress.yaml' file with the FQDN of your host that you created earlier on the public IP of the Application Gateway.

Deploy 5-https-ratings-web-ingress.yaml

```bash
   az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl apply -f 5-https-ratings-web-ingress.yaml -n ratingsapp" --file 5-https-ratings-web-ingress.yaml

```

After updating the ingress, A request will be sent to letsEncrypt to provide a 'staging' certificate. This can take a few minutes. You can check on the progress by running the below command. When the status Ready = True. You should be able to browse to the same URL you configured on the PIP of the Application Gateway earlier.

```bash
   az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl get certificate -n ratingsapp"
```

If you notice the status is not changing after a few minutes, there could be a problem with your certificate request. You can gather more information by running a describe on the request using the below command.

```bash
   az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl get certificaterequest -n ratingsapp"
   az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl describe certificaterequest <certificaterequestname> -n ratingsapp"
```

Upon navigating to your new FQDN you will see you receive a certificate warning because it is not a production certificate. If you have got this far, continue to the next step to remediate this issue.
![deployed workload https](../media/deployed-workload-https.png)

4. Edit the 'certificateIssuer.yaml' file and replace the following:

    Change the metadata name to letsencrypt-prod
    Change the server to https://acme-v02.api.letsencrypt.org/directory
    change the privateKeySecretRef to letsencrypt-prod

Re-apply the updated file

```bash
   az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl apply -f certificateIssuer.yaml -n ratingsapp" --file certificateIssuer.yaml
```

5. The next step is to change the ingress to point to the production certificateIssuer. At the moment it is still pointing to the old staging issuer.

Edit '5-https-ratings-web-ingress.yaml' and replace the following values:

    cert-manager.io/issuer: letsencrypt-prod

Re-apply the updated file

```bash
   az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl apply -f 5-https-ratings-web-ingress.yaml -n ratingsapp" --file 5-https-ratings-web-ingress.yaml
```


Now you can access the website using using your FQDN. When you navigate to the website using your browser you might see a warning stating the destination is not safe. Give it a few minutes and this should clear out. However, for production you want to use Certified Authority (CA) certificates.

![deployed workload https more secure](../media/deployed-workload-https-secure.png)


## Next Step

:arrow_forward: [Cleanup](./08-cleanup.md)
