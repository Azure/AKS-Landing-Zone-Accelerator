# AKS landing zone accelerator - Secure Redis Cache for Bicep

## Getting Started

This section is organized using folders that match the steps outlined below. Make any necessary adjustments to the variables and settings within that folder to match the needs of your deployment.

### Prerequisites

1. Clone this repository
2. Install [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
3. Install [Bicep tools](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install)
4. Azure Subscription

### Steps

1. [Provision AKS cluster using Construction helper](https://azure.github.io/AKS-Construction/?deploy.deployItemKey=deployArmCli)
2. [Pull resource group and related information from the deployed AKS clusters to deploy the redis bicep via az cli](./02-redis.md)
3. [Deploy Workload](./03-workload.md)
