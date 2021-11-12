## Setup AKS and its Addons

This folder contains the ARM templates for deploying AKS resource

### How to deploy the templates
>Before executing this template, ensure that you are connected to your Azure subscription using AZ CLI or PowerShell and a Resource Group has been created for these new deployments. 
> We also need to ensure that all resources are configured in Hub & Deployment

```bash
# login if you haven't already
# az login --tenant <tenant id>
AKS_RESOURCEGROUP=aks-eslz-arm
```


Navigate to "Enterprise-Scale-for-AKSmain/Scenarios/AKS-Secure-Baseline-Modular/ARM/Infrastructure-Deployment/Supporting-components/Parameters" folder
```bash
cd ../../../AKS-Deployment
```

<br/>

* Deploy **AKS**
```bash
az deployment group create --name AKS_Deployment --resource-group $AKS_RESOURCEGROUP --template-file aks-eslz-aks.template.json --parameters @aks-eslz-aks.parameters.json
```
## Enabling Addons
 > **Pod Identity** - Azure Active Directory pod-managed identities uses Kubernetes primitives to associate managed identities for Azure resources and identities in Azure Active Directory (AAD) with pods

>> Pod Identities
```bash
az feature register --name EnablePodIdentityPreview --namespace Microsoft.ContainerService
```
>> Install the aks-preview extension
```bash
az extension add --name aks-preview
```

>> Update the extension to make sure you have the latest version installed
```bash
az extension update --name aks-preview
```
>> Use az aks get-credentials to sign in to your AKS cluster
```bash
az aks get-credentials --resource-group $AKS_RESOURCEGROUP --name aks-eslz1
```
>> Update an existing AKS cluster with Azure CNI to include pod-managed identity.
```bash
az aks update -g $AKS_RESOURCEGROUP -n aks-eslz1 --enable-pod-identity
```
> **Application Gateway Addon** - The Application Gateway Ingress Controller (AGIC) is a Kubernetes application, which makes it possible for Azure Kubernetes Service (AKS) customers to leverage Azure's native Application Gateway L7 load-balancer to expose cloud software to the Internet.
```bash
az aks enable-addons -n aks-eslz1 -g $AKS_RESOURCEGROUP -a ingress-appgw --appgw-id $(az network application-gateway show -n app_gateway -g $AKS_RESOURCEGROUP -o tsv --query "id")
```

> **Enable CSI**

```bash
az feature register --namespace "Microsoft.ContainerService" --name "AKS-AzureKeyVaultSecretsProvider"
```
>> It takes a few minutes for the status to show Registered. Verify the registration status by using the az feature list command
```bash
 az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/AKS-AzureKeyVaultSecretsProvider')].{Name:name,State:properties.state}"
 ```
>> When ready, refresh the registration of the Microsoft.ContainerService resource provider by using the az provider register command
```bash
 az provider register --namespace Microsoft.ContainerService
```

>> Install the aks-preview extension
```bash
 az extension add --name aks-preview
```
>> Update the extension to make sure you have the latest version installed
```bash
 az extension update --name aks-preview
```

>> To upgrade an existing AKS cluster with Secrets Store CSI Driver capability, use the az aks enable-addons command with the addon azure-keyvault-secrets-provider
```bash
 az aks enable-addons --addons azure-keyvault-secrets-provider --name aks-eslz1 --resource-group $AKS_RESOURCEGROUP
```

## Log into cluster

To deploy workload, we need to log into the AKS cluster. However, since this is a private cluster we are unable to log in directly using our command line interface because private clusters are only accessible from computers within the virtual network of the cluster or peered networks. To get access to the cluster we have to log into the jumpbox virtual machine that we setup at the last step of the hub setup stage.

### Setup Prerequisites for the new VM
* Install Azure CLI in the new VM
1. Go to Azure portal and click on the VM that was created in the previous step.
1. Click on **Connect** at the top left of the overview page of the vm 
1. Select **Bastion**
1. Click on the **Use Bastion** button
1. Enter the username and password and click on the **Connect** button. The username and password can be found in the parameters file that was used to create the VM 
1. Install az CLI
    ```bash
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    ```
* Install kubectl CLI

Follow the instructions here: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/ to install kubectl CLI in the new VM

### Update host file to point the private link URL to the IP address of the endpoint setup for the cluster
The next step is to update the host file of the virtual machine so that the *az aks get-credentials* command points to the ip address of the private endpoint of the cluster.

1. Find the resource group where the private endpoint was setup in Azure portal. The name of the resource group usually starts with MC_ + the name of the AKS cluster resource group. 
1. Click on the private endpoint setup for the AKS cluster. In this case it is called kube-apiserver
1. Click on **DNS configuration** in the left pane
1. Copy the IP address in the resulting page and save it somewhere
1. Go back to the Bastion tab and log into Azure
    ```bash
    az login -t <tenant id>
    ```
1. Attempt to log into the cluster
    ```bash
    az aks get-credentials -g $AKS_RESOURCEGROUP -n <aks cluster name>
    ```
    it will prompt you log in
1. Log in follow the instructions
1. Attempt to get nodes
    ```bash
    kubectl get nodes
    ```
    It will show you an error stating that it can't find the host located at the private link address. Copy the private link address and save it somewhere
1. Modify the host file using nano
    ```bash
    sudo nano /etc/hosts
    ```
1. Navigate to the bottom of the hosts file and enter a new line:
    1. Copy and paste the IP address for the private endpoint
    1. Leave a space
    1. Copy and paste the private link address

    Your result should look like the picture below
    ![Updated hosts file](../media/updated-host-file.png)
1. Enter **Ctrl + Q** to exit and then enter **Y** to save the changes
1. Attempt to get nodes again and this time it should work
    ```bash
    kubectl get nodes
    ```
---
## Deploy Workload
:arrow_forward: [Workload Deployment](https://github.com/Azure/Enterprise-Scale-for-AKS/blob/main/Scenarios/AKS-Secure-Baseline-PrivateCluster/Terraform/08-workload.md)
