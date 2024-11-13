# Scenario: creating a backup of an AKS cluster

## Introduction

This scenario shows how to create a backup of an existing AKS cluster and then use it to restore to a new cluster.

## Steps to follow

1. Deploy the AKS Landing Zone by following the steps in folder `Scenarios/AKS-Landing-Zone`.
2. Provide the required input parameters in the `Scenarios/AKS-Backup/terraform.tfvars` file.
3. Run the current Terraform templates to create a backup of the AKS cluster and a new cluster for restore:

```sh
cd Scenarios/AKS-Backup
terraform init
terraform apply
```

4. Deploy a kubernetes deployment and persistent volumes to the original AKS cluster.

```sh
kubectl apply -f ./kubernetes/deploy_disk_lrs.yaml
kubectl apply -f ./kubernetes/deploy_disk_zrs_sc.yaml
```

5. Trigger the backup of the AKS cluster on the azure portal through Vault backup.
6. Watch for the resources created in the backup resource group (disk snapshots and blobs in the backup storage account).
7. Trigger the restore operation to the new AKS cluster using the backup created in the previous step.