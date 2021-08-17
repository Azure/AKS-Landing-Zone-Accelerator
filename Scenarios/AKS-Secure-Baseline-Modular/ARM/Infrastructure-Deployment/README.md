# ARM templates for AKS infrastructure deployment
These files are the ARM templates used for deploying a supporting infrastructure for Azure Kubernetes Service (AKS). This reference implementation uses a standard hub-spoke model.

The templates are grouped under Hub and Spoke folders. Hub and Spoke can be from different subscriptions, but in this reference implementation, we assume that the Hub and Spoke VNETs are from same resource group in a subscription.

Ensure that you deploy the Azure resources in Hub folder before moving on to Spoke.

*Once the Infrastructure Deployment is completed, proceed on to [AKS deployment](https://github.com/Azure/Enterprise-Scale-for-AKS/tree/main/Scenarios/AKS-Secure-Baseline-Modular/ARM/AKS-Deployment).*
