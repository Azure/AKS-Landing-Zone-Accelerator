# AKS Landing Zone Accelerator

**Enterprise-scale for AKS has now been renamed AKS Landing Zone Accelerator. Please bare with us as we complete the transition. If you find any inconsistencies in the repository regarding the name change, please submit an issue to help us make the necessary improvements.**

Enterprise-scale is an architectural approach and a reference implementation that enables effective construction and operationalization of landing zones on Azure, at scale. This approach aligns with the Azure roadmap and the Cloud Adoption Framework for Azure.

Enterprise-scale for AKS represents the strategic design path and target technical state for an Azure Kubernetes Service (AKS) deployment. This solution provides an architectural approach and reference implementation to prepare landing zone subscriptions for a scalable Azure Kubernetes Service (AKS) cluster. For the architectural guidance, check out [Enterprise-scale for AKS](https://docs.microsoft.com/azure/cloud-adoption-framework/scenarios/aks/enterprise-scale-landing-zone) in Microsoft Docs.

Below is a picture of what a golden state looks like and open source software like flux and traefik integrate well within the AKS ecosystem.

![Golden state platform foundation with AKS landingzone highlighted in red](./media/aks-eslz-architecture.png)

The enterprise-scale for AKS is only concerned with what gets deployed in the landing zone subscription highlighted by the red box in the picture above. It is assumed that an appropriate platform foundation is already setup which may or may not be the [official ESLZ](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/enterprise-scale/architecture) platform foundation. This means that policies and governance should already be in place or should be setup after this implementation and are not a part of the scope this reference implementaion. The policies applied to management groups in the hierarchy above the subscription will trickle down to the Enterprise-scale for AKS landing zone subscription.

---

## Choosing a Deployment Model

The reference implementation is provided by three repos that all build on top of the [AKS Secure Baseline](https://docs.microsoft.com/azure/architecture/reference-architectures/containers/aks/secure-baseline-aks).

1. This one
1. The [Bicep AKS Accelerator](https://github.com/Azure/Aks-Construction)
1. The [CAF-Terraform-Landingzones AKS construction set](https://github.com/Azure/caf-terraform-landingzones-starter/tree/starter/enterprise_scale/construction_sets/aks/online/aks_secure_baseline) reference implementation.

### This repo

In this repo, you get access to various customer [scenarios](./Scenarios) that can help accelerate the development and deployment of AKS clusters that conform with Enterprise-Scale for AKS best practices and guidelines. Each scenario aims to represent common customer experiences with the goal of accelerating the process of developing and deploying conforming AKS clusters using Infrastructure-As-Code (IaC). They also provide a step by step learning experience for deploying AKS in an actual Enterprise environment. Each scenario will eventually have a Terraform, ARM and Bicep version. They will also include GitHub Actions CI/CD pipelines to help automate deployment and management of these clusters and the workload that run in them.

Use this repo is you would like step by step guidance on how to deploy secure and well architected AKS clusters using our scenario based model. This model promotes a separation of duties, modularized IaC so you can pick and choose components you want to build with your cluster and has implementations in ARM, Terraform and Bicep. It is the best starting point for customers new to Azure or AKS.

### Bicep AKS Accelerator

A flexible templating approach using Bicep that enables multiple scenarios using a Web based tool. It provides tangible artifacts to **quickly** enable AKS deployments through CLI or in your CI/CD pipeline.

Driving the configuration experience is a [wizard](https://azure.github.io/Aks-Construction/?default=es) to guide your decision making, it provides presets for the main Enterprise-Scale deployment modes (Sandbox, Corp & Online). The output of this wizard experience are the parameters and CLI commands to immediately deploy using our maintained Bicep template to deploy your customized AKS environment in one step.
[Pipeline examples](https://github.com/Azure/Aks-Construction#devops---github-actions) are provided that show best practices for your AKS Infrastructure as Code deployments.

Use this repo if you would like to use a guided experience to rapidly create your environment with a maintained Bicep template based on the architecture of the AKS Secure Baseline.

### CAF Terraform Landingzones

A [reference implementation](https://github.com/Azure/caf-terraform-landingzones-starter/tree/starter/enterprise_scale/construction_sets/aks/online/aks_secure_baseline) for Enterprise-Scale for AKS using CAF terraform module that abstracts away the need for writing terraform code and makes use of the Rover devcontainer.

This reference implementation is great for customers who want to use an advanced and well thought out model for using terraform modules and/or are familiar with CAF terraform modules or want to get familiar with it.

## Steps of Implementation for Enterprise-Scale for AKS

A deployment of AKS-hosted workloads typically requires a separation of duties and lifecycle management in different areas, such as prerequisites, the host network, the cluster infrastructure, the shared services and finally the workload itself. This reference implementation is no different. Also, be aware that our primary purpose is to illustrate the topology and decisions involved in the deployment of an AKS cluster. We feel a "step-by-step" flow will help you learn the pieces of the solution and will give you insight into the relationship between them. Ultimately, lifecycle/SDLC management of your cluster and its dependencies will depend on your situation (organizational structures, standards, processes and tools), and will be implemented as appropriate for your needs.

### AKS Backup & Restore

A terraform module (code accelerator) to deploy and use Open source tool Velero, for Backup & Restore of AKS stateful applications. 

**Coming Soon!** Perform Backup for Persistent Volume of AKS clusters using [Azure Backup](https://azure.microsoft.com/en-us/updates/akspvbackupprivatepreview/)

### Next step

Pick one of the scenarios below to get started on a reference implementation

:arrow_forward: [AKS Secure Baseline](./Scenarios/Secure-Baseline)

:arrow_forward: [AKS Secure Baseline in a Private Cluster](./Scenarios/AKS-Secure-Baseline-PrivateCluster)

:arrow_forward: [Azure Policy initiative for Enterprise Scale for AKS (Brownfield scenario)](./Scenarios/Azure-Policy-ES-for-AKS)

:arrow_forward: [Backup Restore using Open source tool Velero](./Scenarios/Backup-Restore)

### Other two repos

:arrow_forward: [Bicep AKS Accelerator](https://github.com/Azure/Aks-Construction#getting-started)

:arrow_forward: [CAF Terraform landingzones](https://github.com/Azure/caf-terraform-landingzones-starter/tree/starter/enterprise_scale/construction_sets/aks/online/aks_secure_baseline)
