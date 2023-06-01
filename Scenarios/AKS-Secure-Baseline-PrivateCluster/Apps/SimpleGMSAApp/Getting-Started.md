# Deploy a  Simple GMSA Integrated Workload

This application is provided by Microsoft through the [GMSA on AKS PowerShell Module](https://learn.microsoft.com/virtualization/windowscontainers/manage-containers/gmsa-aks-ps-module). The manifest for this application has been modified to support ingress using Azure private load balancer. After setting up GMSA, the instructions will ask you perform a deployment that grabs the sample application through the PowerShell module. Do not deploy the application through the PowerShell module and please follow the steps below.

Because the infrastructure has been deployed in a private AKS cluster setup with private endpoints for the container registry and other components, you will need to perform the application container build and the publishing to the Container Registry from the Domain Controller in the Hub VNET, connecting via the Bastion Host service. If your computer is connected to the hub network, you may be able to just use that as well. The rest of the steps can be performed on your local machine by using AKS Run commands which allow access into private clusters using RBAC. This will help with improving security and will provide a more user-friendly way of editing YAML files.

## Note on the resource constraints in the workload manifest

The values used for CPU and memory represent the minimums to run a Windows application with GMSA. Windows applications require higher memory thresholds than Linux applications. You should adjust these values when running your own application in this cluster.

## Connecting to the Bastion Host

Follow the instructions [here](https://learn.microsoft.com/azure/bastion/bastion-connect-vm-rdp-windows) to connect to your Domain Controller deployed through the reference architecture via Bastion using RDP or instructions [here](https://learn.microsoft.com/azure/bastion/bastion-connect-vm-ssh-windows) to connect via SSH. 

## Prepare your Jumpbox VM with tools (run from local machine)

* Install az cli for windows. You can find latest version [here](https://learn.microsoft.com/cli/azure/install-azure-cli-windows?tabs=azure-cli)
* After installing az cli you will need to install aks add-on. Run az aks install-cli to add support for kubelogin and kubectl.

* Login to Azure

```Powershell
$TENANTID=<tenant id>
az login -t $TENANTID --use-device-code --debug
```

* Ensure you are connected to the correct subscription

```Powershell
az account set --subscription <subscription id>
   ```

* Get AKS credentials.

```Powershell
az aks get-credentials -n <aks cluster name> -g <resource group>
```

* Validate you can query AKS cluster.

```Powershell
kubectl get ns
```

## Setup GMSA on your AKS cluster

- Follow the steps [here](https://learn.microsoft.com/virtualization/windowscontainers/manage-containers/gmsa-aks-ps-module) to setup GMSA on your cluster. These commands will need to be run on your domain controller or on a domain joined virtual machine (the Windows VM jumpbox from the previous step). Follow all instructions on pages, _gMSA on AKS PowerShell Module_ and _Configure gMSA on AKS with PowerShell Module_. You may optionally follow the instructions on _Validate gMSA on AKS with PowerShell Module_, but it is not required for setup. 
- For the keyvault used in the setup, use the keyvault deployed as apart of this reference implementation. The module will check if a keyvault with that name exists before creating the secret with the GMSA credentials. 
- For the managed identity used in the setup, use the managed identity deployed as apart of this reference implementation. The module will check if a managed identity with that name exists before creating a new one. 

## Setup Group Managed Service Account (GMSA) Integration

* Before enabling GMSA on your AKS cluster, you will need to  make the following updates to your architecture:

    1. Update the DNS server on the hub and spoke VNETs to from Azure Default to Custom. The IP address will be the IP address of your domain controller (your jumpbox). Reboot all virtual machines, VM Scale Sets, and your domain controller after performing this action.

    2. Add your login identity to Key Vault access policy. Assign Secret Management (Get, List, Set, Delete, Recover). This is needed during GMSA setup.


## Common Issues

1. If you are running these commands on your domain controller that is a Windows Server machine, you may have trouble
installing the [Kubernetes CLI (kubectl)](https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/) and [kubelogin](https://github.com/Azure/kubelogin). The error would mention "Install-AzAksKubectl". If so, you will need to manually install both following the links above.

## How to validate your GMSA integration before deployment

1. To validate that your cluster is successfully retrieving your GMSA, go into your domain controller local server menu, go to Tools and select Event Viewer. Look under ActiveDirectory events. Look at the contents of the most recent events for a message that says "A caller successfully fetched the password of a group managed service account." The IP address of the caller should match one of your AKS cluster IPs.

## Import simple GMSA application to your container registry

To run the application container image, you will first need to import the Windows Server 2019 LTSC image to your Azure Container Registry that was deployed as a part of the reference implementation. Once this image is imported, you will reference it in the workload's manifest file rather than the public image from Microsoft Container Registry. 

```PowerShell
# enter the name of your ACR below
$SPOKERG=<resource group name for spoke>
$ACRNAME=$(az acr show --name <ACR NAME> --resource-group $SPOKERG --query "name" --output tsv)
```

Import the Windows Server 2019 LTSC image into your container registry.

```PowerShell
az acr import -n $ACRNAME --source mcr.microsoft.com/windows/servercore/iis:windowsservercore-ltsc2019
```

To verify that the image has been imported:

```PowerShell
 az acr repository show -n $ACRNAME --image windows/servercore/iis:windowsservercore-ltsc2019
 ```

## Deploy workload without support for HTTPS

Navigate to "aks-baseline-windows/Scenarios/AKS-Secure-Baseline-PrivateCluster/Apps/SimpleGMSAAPP/manifests" folder.

1. Create a namespace for your application by running ``` kubectl create namespace simpleapp ``` 
2. Update the [manifest file](manifests/deployment_sampleapp.yml) for the sample application with your GMSA name (look for **< GMSA Credential Spec Name >** in the manifest) and application container registry name (Look for **< Registry Name >** in the manifest).
3. Run ``` kubectl apply -f deployment_sampleapp.yml -n simpleapp ```

### Check your deployed workload

1. Verify Deployment by executing the following commands on your jumpbox:

```Powershell
kubectl get deployment -n simpleapp
kubectl get pods -n simpleapp
kubectl describe service -n simpleapp
```
2. Copy the ip address displayed by running ``` kubectl describe ingress -n simpleapp ``` on your jumpbox, open a browser, navigate to the IP address obtained above from the ingress controller and explore your website.

## How to Validate Your GMSA Integration after Deployment

1. Check the status of your pods by running ``` kubectl get pods -n simpleapp``` on your jumpbox. If the status is *Running*, you're good to go. If the status of your pods is *CrashLoopBackOff*, run ``` kubectl logs <pod name> ``` to debug. This status likely means that your credential spec file is misconfigured or the cluster permissions to your KeyVault are misconfigured. An example credential spec can be found [here](https://learn.microsoft.com/virtualization/windowscontainers/manage-containers/manage-serviceaccounts#create-a-credential-spec). When you look through your credential spec file, ensure that the DnsName, NetBiosName and GroupManagedServiceAccounts match the values from your domain controller. 
2. To check if the container is connected to the domain your GMSA is running under, run the following commands:
To login to the pod running your workload:
```Powershell
kubectl get pods -n simpleapp
kubectl exec -it "pod name" powershell
```
```Powershell
nltest /sc_verify:lzacc.com
```
## Deploy the Ingress with HTTPS support

**Please note: This section is still in development**

A fully qualified DNS name and a certificate are needed to configure HTTPS support on the the front end of the web application. You are welcome to bring your own certificate and DNS if you have them available, however a simple way to demonstrate this is to use a self-signed certificate with an FQDN configured on the IP address used by the Application Gateway.

**Objectives**

1. Configure the Public IP address of your Application Gateway to have a DNS name. It will be in the format of customPrefix.region.cloudapp.azure.com
2. Create a certificate using the FQDN and store it in Key Vault.

### Creating Public IP address for your Application Gateway

1. Find your application gateway in your landing zone resource group and click on it. By default it should be in the spoke resource group.

2. Click on the *Frontend public IP address*

3. Click on configuration in the left blade of the resulting page.

4. Enter a unique DNS name in the field provided and click **Save**.

### Create the self-signed certificate using Lets Encrypt

We are going to use Lets Encrypt and Cert-Manager to provide easy to use certificate management for the application within AKS. Cert-Manager will also handle future certificate renewals removing any manual processes.

1. First of all, you will need to install cert-manager into your cluster.

```bash
   az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.8.0/cert-manager.yaml"
```

First of all this will create a new namespace called cert-manager which is where all of the resources for cert-manager will be kept. This will then go ahead and download some CRDs (CustomResourceDefinitions) which provides extra functionality in the cluster for the creation of certificates.

We will then proceed to test this certificate process with a staging certificate to begin with, before moving on to deploying a production certificate.

2.Edit the 'certificateIssuer.yaml' file and include your email address. This will be used for certificate renewal notifications.

Deploy certificateIssuer.yaml

```PowerShell
   az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl apply -f certificateIssuer.yaml -n default" --file certificateIssuer.yaml
```

1. Edit the `deployment_sampleapp.yml` Ingress section with the FQDN of your host that you created earlier on the public IP of the Application Gateway.

Deploy deployment_sampleapp.yml

```PowerShell
   az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl apply -f deployment_sampleapp.yml"

```

After updating the ingress, A request will be sent to letsEncrypt to provide a 'staging' certificate. This can take a few minutes. You can check on the progress by running the below command. When the status Ready = True. You should be able to browse to the same URL you configured on the PIP of the Application Gateway earlier.

```PowerShell
   az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl get certificate"
```

If you notice the status is not changing after a few minutes, there could be a problem with your certificate request. You can gather more information by running a describe on the request using the below command.

```PowerShell
   az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl get certificaterequest"
   az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl describe certificaterequest <certificaterequestname>"
```

Upon navigating to your new FQDN you will see you receive a certificate warning because it is not a production certificate. If you have got this far, continue to the next step to remediate this issue.

4. Edit the 'certificateIssuer.yaml' file and replace the following:

    Change the metadata name to letsencrypt-prod
    Change the server to <https://acme-v02.api.letsencrypt.org/directory>
    change the privateKeySecretRef to letsencrypt-prod

Re-apply the updated file

```PowerShell
   az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl apply -f certificateIssuer.yaml" --file certificateIssuer.yaml
```

5. The next step is to change the ingress to point to the production certificateIssuer. At the moment it is still pointing to the old staging issuer.

Edit 'deployment_sampleapp.yml' and replace the following values:

    cert-manager.io/issuer: letsencrypt-prod

Re-apply the updated file

```PowerShell
   az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl apply -f deployment_sampleapp.yml"
```

Now you can access the website using using your FQDN. When you navigate to the website using your browser you might see a warning stating the destination is not safe. Give it a few minutes and this should clear out. However, for production you want to use Certified Authority (CA) certificates.


# Next Steps
:arrow_forward: [Create the ingress configuration for GMSA](../../Terraform/09-ingress-config.md)
  