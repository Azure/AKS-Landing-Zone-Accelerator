# AKS Landing Zone Accelerator

Azure Landing Zone Accelerators are an architectural approach and a reference implementation that enables effective construction and operationalization of landing zones on Azure, at scale. This approach aligns with the Azure roadmap and the Cloud Adoption Framework for Azure.

AKS Landing Zone Accelerator represents the strategic design path and target technical state for an Azure Kubernetes Service (AKS) deployment. This solution provides an architectural approach and reference implementation to prepare landing zone subscriptions for a scalable Azure Kubernetes Service (AKS) cluster. For the architectural guidance, check out [AKS Landing Zone Accelerator](https://docs.microsoft.com/azure/cloud-adoption-framework/scenarios/aks/enterprise-scale-landing-zone) in Microsoft Docs.

Below is a picture of what a golden state looks like and open source software like flux and traefik integrate well within the AKS ecosystem.

![Golden state platform foundation with AKS landingzone highlighted in red](./media/aks-eslz-architecture.png)

The AKS Landing Zone Accelerator is only concerned with what gets deployed in the landing zone subscription highlighted by the red box in the picture above. It is assumed that an appropriate platform foundation is already setup which may or may not be the [official ESLZ](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/enterprise-scale/architecture) platform foundation. This means that policies and governance should already be in place or should be setup after this implementation and are not a part of the scope this reference implementaion. The policies applied to management groups in the hierarchy above the subscription will trickle down to the AKS Landing Zone Accelerator landing zone subscription.

---

## Choosing a Deployment Model

The reference implementations are spread across three repos that all build on top of the [AKS Secure Baseline](https://docs.microsoft.com/azure/architecture/reference-architectures/containers/aks/secure-baseline-aks) and Azure Landing Zones.

1. This one
1. The [Bicep AKS Accelerator](https://github.com/Azure/Aks-Construction)
1. The [Baseline Automation Module](https://github.com/Azure/aks-baseline-automation)

### This repo

In this repo, you get access to step by step guide covering various customer [scenarios](./Scenarios) that can help accelerate the development and deployment of AKS clusters that conform with AKS Landing Zone Accelerator best practices and guidelines. This is a good starting point if you are **new** to AKS or IaC. Each scenario aims to represent common customer experiences with the goal of accelerating the process of developing and deploying conforming AKS clusters using Infrastructure-As-Code (IaC). They also provide a step by step learning experience for deploying AKS in an actual Enterprise environment. Most scenarios will eventually have a **Terraform** and **Bicep** version. 

Use [this repo](https://github.com/Azure/AKS-Landing-Zone-Accelerator/tree/main/Scenarios/AKS-Secure-Baseline-PrivateCluster) if you would like step by step guidance on how to deploy secure and well architected AKS clusters using our scenario based model and/or you are new to AKS or IaC. This model promotes a separation of duties, modularized IaC so you can pick and choose components you want to build with your cluster and has implementations in ARM, Terraform and Bicep. It is the best starting point for people new to Azure or AKS.

### Bicep AKS Accelerator

A flexible templating approach using Bicep that enables multiple scenarios using a Web based tool. It provides tangible artifacts to **quickly** enable AKS deployments through CLI or in your CI/CD pipeline.

Driving the configuration experience is a [wizard](https://azure.github.io/Aks-Construction/?default=es) to guide your decision making, it provides presets for the main Azure Landing Zone deployment modes (Sandbox, Corp & Online). The output of this wizard experience are the parameters and CLI commands to immediately deploy using our maintained Bicep template to deploy your customized AKS environment in one step.

Use [this repo](https://github.com/Azure/Aks-Construction) if you would like to use a guided experience to rapidly create your environment with a maintained Bicep template based on the architecture of the AKS Secure Baseline.

### Baseline Automation Module

This reference implementation demonstrates recommended ways to automate the deployment of the components composing a typical AKS solution. This repository includes information about separation of duties (different teams managing different parts of the deployment process), CI/CD and GitOps best practices. 

Use [this repo](https://github.com/Azure/aks-baseline-automation) if you would like to learn how to quickly setup and get access to templates to help setup your own DevOps environments for AKS workloads. 

## Next Steps to implement AKS Landing Zone Accelerator
Pick one of two options below

### Follow a scenario driven tutorial within this repo

Pick one of the scenarios below to get started on a reference implementation. For the AKS secure baseline with non-private cluster, use the [AKS baseline](https://github.com/mspnp/aks-baseline) reference implementation.

:arrow_forward: [AKS Secure Baseline in a Private Cluster](./Scenarios/AKS-Secure-Baseline-PrivateCluster)

:arrow_forward: [Azure Policy initiative for AKS Landing Zone Accelerator (Brownfield scenario)](./Scenarios/Azure-Policy-ES-for-AKS)

:arrow_forward: [Backup Restore using Open source tool Velero](./Scenarios/Backup-Restore)

### Or leverage one of the Landing Zone Accelerator implementations from our other repos

:arrow_forward: [Bicep AKS Accelerator](https://github.com/Azure/Aks-Construction#getting-started)
:arrow_forward: [Baseline Automation Module](https://github.com/Azure/aks-baseline-automation)

