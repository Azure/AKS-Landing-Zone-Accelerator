# Enterprise Scale for AKS
Enterprise-scale is an architectural approach and a reference implementation that enables effective construction and operationalization of landing zones on Azure, at scale. This approach aligns with the Azure roadmap and the Cloud Adoption Framework for Azure.

Enterprise-scale for AKS represents the strategic design path and target technical state for an Azure Kubernetes Service (AKS) deployment. This solution provides an architectural approach and reference implementation to prepare landing zone subscriptions for a scalable Azure Kubernetes Service (AKS) cluster. For the architectural guidance, check out [Enterprise Scale for AKS](https://docs.microsoft.com/azure/cloud-adoption-framework/scenarios/aks/enterprise-scale-landing-zone) in Microsoft Docs.

# Enterprise Scale for AKS Reference Implementation
The reference implementation is split into two repos. This one and the [CAF-Terraform-Landingzones AKS construction set](https://github.com/Azure/caf-terraform-landingzones-starter/tree/starter/enterprise_scale/construction_sets/aks/online/aks_secure_baseline) reference implementation. Click on the link to get access to a reference implementation for Enterprise Scale for AKS using CAF terraform module that abstracts away having to manually write terraform code and makes use of the Rover devcontainer. This reference implemenation is great for customers familiar with CAF terraform modules or want to get familiar with it.

In this repo, you get access to various customer [scenarios](./Scenarios) that can help accelerate the development and deployment of AKS clusters that conform with Enterprise-Scale for AKS best practices and guidelines. Each scenario aims to represent common customer experiences with the goal of accelerating the process of deploying conforming AKS clusters using IaC. Each scenario will eventually have a Terraform, ARM and Bicep version. They will also include CI/CD pipelines to help automate deployment of these clusters and the workload that run in them.

Below is a picture of what a golden state looks like and it shows how open source software like flux and traefik integrate well within the AKS ecosystem.

![Golden state platform foundation with AKS landingzone highlighted in red](./media/aks-eslz-architecture.png)
The enterprise-scale for AKS is only concerned with what gets deployed in the landingzone subscription highlighted by the red box in the picture above. It is assumed that an appropriate platform foundation is already setup which may or may not be the [official ESLZ](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/enterprise-scale/architecture) platform foundation. The policies applied by the platform foundation would trickle down to the Enterprise-scale for AKS landingzone subscription.

### Next step
Pick one of the scenarios below to get started on a reference implementation

:arrow_forward: [AKS Secure Baseline](./Scenarios/Secure-Baseline)

:arrow_forward: [AKS Secure Baseline in a Private Cluster](./Scenarios/AKS-Secure-Baseline-PrivateCluster)


