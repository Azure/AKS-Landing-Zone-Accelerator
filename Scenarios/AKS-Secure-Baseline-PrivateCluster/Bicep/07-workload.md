# Deploy a Basic Workload using the Fruit Smoothie Ratings Application

This application is provided by Microsoft Learning and is used as part of a self-paced Kubernetes training [workshop](https://docs.microsoft.com/en-us/learn/modules/aks-workshop/). You may find reviewing that workshop helpful as it presents some alternative deployment options and features using different architecture requirements. The application consists of a web frontend, an API service and a MongoDB database.

Because the infrastructure has been deployed in a secure manner, only the API server to the AKS Cluster is accessible outside of the private network.  You will need to perform the majority of the application deployment from the Dev Jumpbox in the Hub VNET, connect via the Bastion Host service. If your computer is connected to the hub network, you may be able to just use that as well.

## Prepare your Jumpbox VM with tools

1. Add a rule in the Firewall to allow internet access to the VM

```bash
az firewall command
```

## Connecting to the Bastion Host

1. Log into Azure portal and find the virtual machine you created in the create hub network step.
2. Click on **Connect** at the top of the screen and select **Bastion**
3. Click on the **Use Bastion** button
4. Enter the username and password. If you have used a public key, then select upload private key (corresponding to the public key) to connect.
5. Click on the **Connect** button.

Once you connect ensure you permit the site to read the content of your clipboard

1. Fork the repo and clone it on the jumpbox.

```bash
git clone https://github.com/Azure/Enterprise-Scale-for-AKS
```

2. Run the script to install required tools (Az CLI, Docker, Kubectl, Helm etc). Navigate to "/Scenarios/AKS-Secure-Baseline-PrivateCluster/Bicep/03-Network-Hub" folder
 
```bash
cd Scenarios/AKS-Secure-Baseline-PrivateCluster/Bicep/03-Network-Hub
curl -sL script.sh | sudo bash
```

3. Login to Azure

```bash
az login -t <tenant id>
```

4. Ensure you are connected to the correct subscription

```bash
az account set --subscription <subscription id>
```

## Build Container Images

Set your environmental variables

```
AKSCLUSTERNAME=aks-escs
AKSRESOURCEGROUP=escs-lz01-rg-aks
```

Clone the required repos to the Dev Jumpbox:

1. The Ratings API repo
```
git clone https://github.com/MicrosoftDocs/mslearn-aks-workshop-ratings-api.git
```
2. The Ratings Web repo
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
sudo az acr login -n <acrname>
```

Push the images into the container registry. Ensure you are logged in u

```
sudo docker push <acrname>.azurecr.io/ratings-api:v1
sudo docker push <acrname>.azurecr.io/ratings-web:v1
```

Create the secret in keyvault if you havent already. You may use anything you'd like for the username and password for the MongoDB database but this needs to match what you will use when you create the helm chat in the next steps.

```
az keyvault secret set --name mongodburi --vault-name <acr name> --value "mongodb://<username>:<password>@ratings-mongodb.ratingsapp:27017/ratingsdb"
```

## Deploy the database into the cluster

You can deploy the workload into the cluster using your local computer since this is not a private cluster. This is not a very secure option. For better security, use a private cluster. We have a private cluster scenario in this repository. We are using a non private cluster for training purposes and for cases where you may not want to use a private cluster. It is easier to perform the following steps using your local computer since, it would be easy to modify the deployment files as needed. 

Get the connection credentials for the cluster:

```
az aks get-credentials --name $AKSCLUSTERNAME --resource-group $AKSRESOURCEGROUP
```

Ensure you have access to the cluster

```
kubectl get nodes
```

![cluster access granted](../media/access-granted-to-cluster.png)

On the Kubernetes cluster, create a namespace for the Ratings Application. 

```
kubectl create namespace ratingsapp
```

The MongoDB backend application is installed using Helm. Your username and password must be the same username and password using in the connection string secret that was created in Key vault in the previous step.

```
helm repo add bitnami https://charts.bitnami.com/bitnami

helm install ratings bitnami/mongodb --namespace ratingsapp --set auth.username=<username>,auth.password=<password>,auth.database=ratingsdb
```

## Deploy the workload into the cluster

The steps below can be completed on your computer even if it is not connected to the cluster's virtual network. This makes it easier to tweak the yaml files for this demo. For a more secure AKS cluster, deploy a private cluster. Instructions on how to do that can be found in this repo.

On your computer, navigate to "/Scenarios/Secure-Baseline/Apps/RatingsApp" folder. 

```
cd ../../Apps/RatingsApp
```
Log into the cluster on your computer

```
az aks get-credentials -g $AKSRESOURCEGROUP -n $AKSCLUSTERNAME
```

Update the "api-secret-provider-class.yaml" file to reflect the correct Key Vault name, Client ID for the AKS Key Vault Add-on you saved earlier and the Tenant ID for the subscription.  

> If you don't have the Client ID, you can find it by going to the Key vault and clicking on **Access Policies** in the left blade. Find the identity that starts with "azurekeyvaultsecrets", then look for the resource by searching for the name in the search bar at the top. When you click on the resource, you will find the Client ID on the right side of the screen.

1. Deploy the edited yaml file.

```
kubectl apply -f api-secret-provider-class.yaml -n ratingsapp
```

2. Update the "1-ratings-api-deployment.yaml" file to reflect the correct name for the Azure Container Registry.  Deploy the file.

```
kubectl apply -f 1-ratings-api-deployment.yaml -n ratingsapp
```

3. Ensure the ratings-api deployment was successful. If you dont get a running state then it is likely that the pod was unable to get the secret from Key vault. This may be because the username and password of the db doesn't match the connection string that was created in Key vault or because the proper access to the Key vault wasn't granted to the azuresecret identity. 

   ![cluster access granted](../media/api-pod-deployed.png)

   You can troubleshoot container creation issues by running

   ```
   kubectl describe pod <pod name>
   ```

4. Deploy the "2-ratings-api-service.yaml" file.

5. ```
   kubectl apply -f 2-ratings-api-service.yaml -n ratingsapp
   ```

6. Update the "3a-ratings-web-deployment.yaml" file to reflect the correct name for the Azure Container Registry. Deploy the file. 

   ```
   kubectl apply -f 3a-ratings-web-deployment.yaml -n ratingsapp
   ```

7. Deploy the "4-ratings-web-service.yaml" file.

   ```
   kubectl apply -f 4-ratings-web-service.yaml -n ratingsapp
   ```

## (Optional) Deploy the Ingress using without support for HTTPS

This step is optional. If you would like to go straight to using https which is the secure option, skip this section and go straight to the **Update the Ingress to support HTTPS traffic** section.

1. Deploy the "5a-ratings-web-ingress.yaml" file.

   ```
   kubectl apply -f 5-http-ratings-web-ingress.yaml -n ratingsapp
   ```

2. Get the ip address of your ingress controller

   ```
   kubectl get ingress -n ratingsapp
   ```

### Allow access to the application gateway via port 80 

For the first deployment we are using http, so we need to access the workload at port 80. Follow the steps below to allow access to the application gateway via port 80.

1. Go to Azure portal and in the lz resource group you'll find the appgwSubnet NSG

   ![application gw nsg](../media/app-gw-nsg.png)

2. Click on the **Inbound rules** in the left blade

3. Add a new rule that allows access to the application gateway on port 80

4. Set the priority to 200. Your result should look like this

   ![application gw nsg](../media/allow-http-access.png)

5. Click on **Add**

### Check your deployed workload

1. Get the ip address of your ingress controller

   ```
   kubectl get ingress -n ratingsapp
   ```

2. Copy the ip address displayed, open a browser, navigate to that address and explore your website

   ![deployed workload](../media/deployed-workload.png)

After you are done testing the workload, go back to the NSG and disable the inbound rule you just created. 

## Update the Ingress to support HTTPS traffic

A fully qualified DNS name and a certificate are needed to configure HTTPS support on the the front end of the web application. You are welcome to bring your own certificate and DNS if you have them available, however a simple way to demonstrate this is to use a self-signed certificate with an FQDN configured on the IP address used by the Application Gateway. 

1. Configure the Public IP address of your Application Gateway to have a DNS name. It will be in the format of <customprefix>.<region>.cloudapp.azure.com
2. Create a certificate using the FQDN and store it in KeyVault. 

### Creating Public IP address for your Application Gateway

1. Find your application gateway in your landing zone resource group and click on it. By default is has the name *lzappgw*.

2. Click on the *Frontend public IP address* 

   ![front end public ip address](../media/front-end-pip-link.png)

3. Click on configuration in the left blade of the resulting page

4. Enter a unique DNS name in the field provided and click **Save**

   ![creating nds](../media/dns-created.png)

### Create the self signed certificate using openssl

Create the self signed certificate using openssl. Note that these steps need to be created by a computer within the hub or spoke network since the Key vault is private. Head back to your jump box and enter these commands.

```
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -out aks-ingress-tls.crt -keyout aks-ingress-tls.key -subj "/CN=ratingsappdns.westus2.cloudapp.azure.com/O=AKS-INGRESS-TLS"

openssl pkcs12 -export -out aks-ingress-tls.pfx -in aks-ingress-tls.crt -inkey aks-ingress-tls.key -passout pass:
```
Create the secret in Key vault

```
az keyvault certificate import -f aks-ingress-tls.pfx -n aks-ingress-tls --vault-name kv94640-akscs
```

### Redeploy the workload using HTTPS

Now that you have created the certificate in  Key vault you can switch back to your computer and redeploy the workload using HTTPS

1. Update the web-secret-class-provider.yaml with your keyvault name, user assigned identity for the keyvault add-on, the tenant ID and the user assigned identity. Deploy it.

   ```
   kubectl apply -f web-secret-provider-class.yaml -n ratingsapp
   ```

2. Delete the previous ratings-web deployment. 

   ```
    kubectl delete -f 3a-ratings-web-deployment.yaml -n ratingsapp
   ```

   Update the  "3b-ratings-web-deployment.yaml" file with the ACR name and redeploy the web application using the this file, which includes the necessary volume mounts to create the Kubernetes secret containing the certificate that will be used by the ingress controller.

   ```
   kubectl apply -f 3b-ratings-web-deployment.yaml -n ratingsapp
   ```

   Update the "5-https-ratings-web-ingress.yaml" file to use the FQDN that matches the certificate and application gateway public IP address.  Delete the previous ingress and redeploy the ingress with this file. 

   ```
   kubectl delete -f 5-http-ratings-web-ingress.yaml -n ratingsapp
   ```

   ```
   kubectl apply -f 5-https-ratings-web-ingress.yaml -n ratingsapp 
   ```

Now you can access the website using using your FQDN. When you navigate to the website using your browser you will see a warning stating the destination is not safe. This is because you are using a self signed certificate which we used for illustration purposes. Do not use a self signed certificate in production. Go ahead and proceed to the destination to get access to your deployment.

![deployed workload https](../media/deployed-workload-https.png)


## Next Step

:arrow_forward: [Cleanup](./08-cleanup.md)