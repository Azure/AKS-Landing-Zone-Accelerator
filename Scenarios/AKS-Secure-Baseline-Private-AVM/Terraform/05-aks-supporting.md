# Create resources that support AKS

The following will be created:

* Azure Container Registry
* Azure Key Vault
* Private Link Endpoints for ACR and Key Vault
* Related DNS settings for private endpoints
* A managed identity

Navigate to "/Scenarios/AKS-Secure-Baseline-PrivateCluster/Terraform/" folder

```bash
cd ./05-AKS-supporting
```

Review "input.tf" and update the variable values as required. Once the files are updated, deploy using terraform cli.

# [CLI](#tab/CLI)

```terracli
terraform init
terraform plan -out main.tfplan
terraform apply main.tfplan -auto-approve
```

:arrow_forward: [Creation of AKS & enabling Addons](./06-aks-cluster.md)
