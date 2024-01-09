# AKS landing zone accelerator - Private Cluster Scenario for Bicep

## Keeping It As Simple As Possible

The code here is purposely written to avoid loops, complex variables and logic. In most cases, it is resource blocks, small modules and limited variables, with the goal of making it easier to determine what is being deployed and how they are connected. Resources are broken into separate files for future modularization or adjustments as needed by your organization.

## Getting Started - Option 1: Manual Deploy

This section is organized using folders that match the steps outlined below. Make any necessary adjustments to the variables and settings within that folder to match the needs of your deployment.

1. Prerequisites: Clone this repo, install [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli), install [Bicep tools](https://learn.microsoft.com/azure/azure-resource-manager/bicep/install)
2. [Create or Import Microsoft Entra groups for AKS Cluster Admins and AKS Cluster Users](./02-eid.md)
3. [Creation of Hub Network & its respective Components](./03-network-hub.md)
4. [Creation of Spoke Network & its respective Components](./04-network-lz.md)
5. [Creation of Supporting Components for AKS](./05-aks-supporting.md)
6. [Creation of AKS & enabling Addons](./06-aks-cluster.md)
7. [Deploy a Basic Workload](./07-workload.md)

## Getting Started - Option 2: Fully Automated Deploy using GitHub Actions

This section can be followed instead of the "Getting Started" section above, if using GitHub. Follow these steps to have GitHub Actions deploy the templates automatically instead of manually following the steps above for a fully automated deployment of the same templates.

1. Prerequisites: Clone or Fork this repo to your own GitHub Account
2. [Deploy using GitHub Actions](./02a-DeployUsingGitHubActions.md)
