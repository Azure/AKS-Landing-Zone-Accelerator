# Create resources for the AKS Cluster

The following will be created:

* AKS Cluster with KeyVault, nginx and monitoring addons
* Log Analytics Workspace
* ACR Access to the AKS Cluster
* Updates to KeyVault access policy with AKS keyvault addon

Navigate to "/Scenarios/AKS-Secure-Baseline-PrivateCluster/Terraform/" folder

```bash
cd ./06-AKS-cluster
```

To create an AKS cluster that can use the Secrets Store CSI Driver, you must enable the AKS-AzureKeyVaultSecretsProvider feature flag on your subscription. Register the AKS-AzureKeyVaultSecretsProvider feature flag by using the az feature register command, as shown below

```bash
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/AKS-AzureKeyVaultSecretsProvider')].{Name:name,State:properties.state}"
```

if not enter the command below to enable it

```bash
az feature register --namespace "Microsoft.ContainerService" --name "AKS-AzureKeyVaultSecretsProvider"
```

It takes a few minutes for the status to show *Registered*. Verify the registration status by using the [az feature list](https://learn.microsoft.com/cli/azure/feature#az_feature_list) command:

```bash
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/AKS-AzureKeyVaultSecretsProvider')].{Name:name,State:properties.state}"
```

When ready, refresh the registration of the *Microsoft.ContainerService* resource provider by using the [az provider register](https://learn.microsoft.com/cli/azure/provider#az_provider_register) command:

```bash
az provider register --namespace Microsoft.ContainerService
```

There are a few additional Azure Providers and features that needs to be registered as well. Follow the same steps above for the following providers and features:

* Microsoft.ContainerService
* AKS-AzureKeyVaultSecretsProvider
* Microsoft.OperationsManagement
* Microsoft.OperationalInsights
* EncryptionAtHost

Here is a list with all required providers or features to be registered:

```bash
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.OperationsManagement
az provider register --namespace Microsoft.OperationalInsights
az feature register --namespace "Microsoft.ContainerService" --name "AKS-AzureKeyVaultSecretsProvider"
az feature register --namespace Microsoft.Compute --name EncryptionAtHost
```

> :warning: Don't move ahead to the next steps until all providers are registered.

There is a admin group you need to change in input.tf

    - Admin group which will grant the role "Azure Kubernetes Service Cluster Admin Role". The variable name is: admin-group-object-ids. 

## Deploy the cluster

Review "**input.tf**" file and update the variable values as required. Please make sure to update the Microsoft Entra ID group IDs with ones created in Step 02 and kubernetesVersion in the variables file. Once the files are updated, deploy using terraform cli

The Kubernetes community releases minor versions roughly every three months. AKS has it own supportability policy based in the community releases. Before proceeding with the deployment, check the latest version reviewing the [supportability doc](https://learn.microsoft.com/azure/aks/supported-kubernetes-versions). You can also check the latest version by using the following command:

```azurecli
az aks get-versions -l $REGION
```

# [CLI](#tab/CLI)

```terracli
terraform init
terraform plan -out main.tfplan
terraform apply main.tfplan -auto-approve
```

:arrow_forward: [Deploy a Basic Workload](./07-workload.md)
