# Configuring a backup for an AKS cluster

## Introduction

This architectural pattern describes how to configure a backup for an AKS cluster.

## 1. Deploying the origin AKS cluster

There are two options, creating a new AKS cluster or using an existing one. If you are using an existing AKS cluster, you can skip this step.

The first step is to deploy the AKS landing zone. Follow the instructions in the [AKS Secure Baseline Private Cluster](../AKS-Secure-Baseline-PrivateCluster) scenario.

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
