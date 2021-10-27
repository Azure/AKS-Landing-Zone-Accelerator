## Steps of Implementation for AKS Construction Set
A deployment of AKS-hosted workloads typically experiences a separation of duties and lifecycle management in the area of prerequisites, the host network, the cluster infrastructure, and finally the workload itself. This reference implementation is similar. Also, be aware our primary purpose is to illustrate the topology and decisions of a baseline cluster. We feel a "step-by-step" flow will help you learn the pieces of the solution and give you insight into the relationship between them. Ultimately, lifecycle/SDLC management of your cluster and its dependencies will depend on your situation (team roles, organizational standards, tooling, etc), and must be implemented as appropriate for your needs.

## Accounting for Separation of Duties 
While the code here is located in one folder in a single repo, the steps are designed to mimic how an organization may break up the deployment of various Azure components across teams, into different code repos or have them run by different pipelines with specific credentials. 

## Keeping It As Simple As Possible
The code here is purposely written to avoid loops, complex variables and logic. In most cases, it is resource blocks, small modules and limited variables, with the goal of making it easier to determine what is being deployed and how they are connected. Resources are broken into separate files for future modularization or adjustments as needed by your organization. 

## Terraform State Management
In this example, state is stored in an Azure Storage account that was created out-of-band.  All deployments reference this storage account to either store state or reference variables from other parts of the deployment however you may choose to use other tools for state managment, like Terraform Cloud after making the necessary code changes.

## Getting Started 
This section is organized using folders that match the steps outlined below. Make any necessary adjustments to the variables and settings within that folder to match the needs of your deployment. 

1. Preqs - Clone this repo, install Azure CLI, install Terraform

2. [Creation of Azure Storage Account for State Management](./02-state-storage.md)

3. [Create or Import Azure Active Directory Groups for AKS Cluster Admins and AKS Cluster Users](./03-aad.md)

4. [Creation of Hub Network & its respective Components](./04-network-hub.md)
 
5. [Creation of Spoke Network & its respective Components](./05-network-lz.md)

6. [Creation of Supporting Components for AKS](./06-aks-supporting.md)

7. [Creation of AKS & enabling Addons](./07-aks-cluster.md)

8. [Deploy a Basic Workload](./08-workload.md)


