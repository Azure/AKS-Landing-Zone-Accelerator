# Configuring a backup for an AKS cluster

## Introduction

This architectural pattern describes how to configure a backup for an AKS cluster.

## Deploying the resources using Terraform

To deploy the Terraform configuration files, run the following commands:

```sh
terraform init

terraform plan -out tfplan

terraform apply tfplan
```

The following resources will be created.

## Cleanup resources

To delete the creates resources, run the following command:

```sh
terraform destroy -auto-approve
```

## More readings

https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/data_protection_backup_instance_kubernetes_cluster
