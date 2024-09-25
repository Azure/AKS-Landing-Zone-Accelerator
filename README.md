# AKS Landing Zone Accelerator

Azure Landing Zone Accelerators are architectural guidance, reference architecture, reference implementations, and automation packaged to deploy workload platforms on Azure at Scale and aligned with industry-proven practices.

The AKS Landing Zone Accelerator represents the strategic design path and target technical state for an Azure Kubernetes Service (AKS) deployment. This solution provides an architectural approach and reference implementation to prepare subscriptions for a scalable Azure Kubernetes Service (AKS) cluster. For architectural guidance, check out the [AKS landing zone accelerator](https://learn.microsoft.com/azure/cloud-adoption-framework/scenarios/app-platform/aks/landing-zone-accelerator) in Microsoft Learn.

Below is a picture of what a golden state looks like, and open source software like flux and traefik integrate well within the AKS ecosystem.

![Golden state platform foundation with AKS landingzone highlighted in red](./media/aks-eslz-architecture.png)

The AKS Landing Zone Accelerator is only concerned with what gets deployed in the landing zone subscription highlighted by the red box in the picture above. It is assumed that an appropriate platform foundation is already setup which may or may not be the [official ESLZ](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/) platform foundation. This means that policies and governance should already be in place or should be setup after this implementation and are not a part of the scope this reference implementation. The policies applied to management groups in the hierarchy above the subscription will trickle down to the AKS Landing Zone Accelerator landing zone subscription. Having a platform foundation is not mandatory, it just enhances it. The modularized approach used in this program allows the user to pick and choose whatever portion is useful to them. You don't have to use all the resources provided by this program.

---

## Choosing a Deployment Model

The reference implementations are spread across two repos that all build on top of the [AKS baseline reference architecture](https://learn.microsoft.com/azure/architecture/reference-architectures/containers/aks/baseline-aks) and Azure Landing Zones.

1. This one. To Deploy our AKS Secure Baseline Scenario, Check out [AKS Secure Baseline](./Scenarios/AKS-Secure-Baseline-PrivateCluster/). Use [this repo](https://github.com/Azure/AKS-Landing-Zone-Accelerator/tree/main/Scenarios/AKS-Secure-Baseline-PrivateCluster) if you would like step by step guidance on how to deploy secure and well architected AKS clusters using our scenario based model and/or you are new to AKS or IaC. This model promotes a separation of duties, modularized IaC so you can pick and choose components you want to build with your cluster and has implementations in ARM, Terraform and Bicep. It is the best starting point for people new to Azure or AKS.
1. The [AKS Construction Helper](https://github.com/Azure/Aks-Construction), a flexible templating approach using Bicep that enables multiple scenarios using a Web based tool. It provides tangible artifacts to **quickly** enable AKS deployments through CLI or in your CI/CD pipeline.

:arrow_forward: [AKS Secure Baseline in a Private Cluster](./Scenarios/AKS-Secure-Baseline-Private-AVM/README.md)

▶️ [Running Azure ML workloads on a private AKS cluster](./Scenarios/AzureML-on-Private-AKS)

### Or leverage one of the Landing Zone Accelerator implementations from our other repos

:arrow_forward: [AKS Construction Helper](https://github.com/Azure/Aks-Construction#getting-started)
