## Create the Hub Network

This folder contains the ARM templates for deploying the below Azure resources:
* Log Analytics Workspace
* Virtual Network (Hub)
* Azure Firewall
* Azure Bastion Host
* Virtual Machine

>*In the Hub-Spoke topology, all Azure resources which are shared by spoke VNETs will be deployed in Hub VNET. Eg: Firewall, Bastion.. All Spoke VNETs will be connected to the Hub VNET using VNET peering.*
---
### How to deploy the templates
>Before executing these templates, ensure that you are connected to your Azure subscription using AZ CLI or PowerShell and a Resource Group has been created for these new deployments. 

```bash
az login --tenant <tenant id>
HUB_RESOURCEGROUP=aks-eslz-arm
az group create --location eastus --name $HUB_RESOURCEGROUP
```
#### The templates should be deployed in the below order:

>Ensure that the parameter files in the Templates folders are customized as per your naming standard. These files can be found in the folders called **Templates** within the various directors in this scenario.

Navigate to "Enterprise-Scale-for-AKSmain/Scenarios/AKS-Secure-Baseline-Modular/ARM/Infrastructure-Deployment/Hub/Parameters" folder
```bash
cd Scenarios/AKS-Secure-Baseline-PrivateCluster/ARM/Infrastructure-Deployment/Hub/Parameters
```
## Deploy the Hub
* Deploy **Log Analytics Workspace**
> [!NOTE]
> You can check the various arm template files to see the resources that would be deployed by the following deployment groups by checking out the files in the appropriate folder shown in the deployment steps below.
```bash
az deployment group create --name LogAnalytics --resource-group $HUB_RESOURCEGROUP --template-file ../Templates/aks-eslz-la.template.json --parameters @aks-eslz-la.parameters.json
```
* Deploy Hub **Virtual Network**
```bash
az deployment group create --name Hub --resource-group $HUB_RESOURCEGROUP --template-file ../Templates/aks-eslz-hub.template.json --parameters @aks-eslz-hub.parameters.json
```
* Deploy **Azure Firewall**
```bash
az deployment group create --name Firewall --resource-group $HUB_RESOURCEGROUP --template-file ../Templates/aks-eslz-firewall.template.json --parameters @aks-eslz-firewall.parameters.json
```
* Deploy **Azure Bastion Host**
```bash
az deployment group create --name Bastion --resource-group $HUB_RESOURCEGROUP --template-file ../Templates/aks-eslz-bastion.template.json --parameters @aks-eslz-bastion.parameters.json
```


### Setup optional VM within the Hub virtual network to connect with Private Cluster
**Optional Components** : For management of resources in private cluster, we're providing the sample for a VM creation

* Update <ins>Network Policies for AzureManagementSubnet</ins>
```bash
az network vnet subnet update --disable-private-endpoint-network-policies true --name AzureManagementSubnet --resource-group $HUB_RESOURCEGROUP --vnet-name vnet_hub_arm 
```

* Deploy **Virtual Machine**
```bash
az deployment group create --name VirtualMachine --resource-group $HUB_RESOURCEGROUP --template-file ../Templates/aks-eslz-virtualmachine.template.json --parameters @aks-eslz-virtualmachine.parameters.json
```

## Optional Connectivity to Virtual-Machine (Through Visual studio code)

In case you're looking to connect to VM through VS code -
As your hub network has been setup and you have a vm you can use to connect to the resources in the private cluster you are about to build.

To easily modify manifest files, you will connect to the control plane using Remote - SSH VS code extension. An SSH tunnel will be used to connect to the server-dev-linux virtual machine to run everything from the remote vm connected using your local vs code. In order to support this method you will need to go to the vs code extension marketplace and install Remote - SSH (https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh).

Prerequisites
To get started, you need to have done the following steps:

1. Install an OpenSSH compatible SSH client (PuTTY is not supported). https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse
2. Install Visual Studio Code.

When the Remote-SSH vs code extension is installed you should see the following icon in the lower left screen of your vs code windows

![https://github.com/Azure/Enterprise-Scale-for-AKS/blob/main/Scenarios/AKS-Secure-Baseline-PrivateCluster/media/remote-ssh.png](https://github.com/Azure/Enterprise-Scale-for-AKS/blob/main/Scenarios/AKS-Secure-Baseline-PrivateCluster/media/remote-ssh.png)


To access and further lockdown the server-dev-linux vm change the `source_address_prefix` variable in the terraform.tfvars file to the public ip address that your local computer is using. The default value for `source_address_prefix` is `*` which means any inbound connection using port 22 will be able to hit the vm. To find the public IP address of your local machine use the following link : 

**whatismypublicip.com**

**Generate keys with ssh-keygen command**

To generate your private key that will be installed on your local machine and the public key to be placed of the server-dev-linux vm use the ssh-keygen command running on an elevated shell (admin shell).

The following command will created an 4096 bit RSA key pair (must use at a minimum 2048 bit) : ***ssh-keygen -t rsa -b 4096***. 

The private key will be placed in the `C:\Users\User\.ssh\id_rsa` directory on your local machine. The public key will be placed in the `~/.ssh/id_rsa.pub` directory. You will take the contents of the id_rsa.pub file, copy it & you can in place of the password if required.

### Next step

:arrow_forward: [Creation of Spoke Network & its respective Components](./02-Setup-Spoke.md)
