# Documentation to implement the ARM templates for deployment of AKS Construction Set

## Background

This is an implementation taking reference from [Azure Kubernetes Service (AKS) Fabrikam Drone Delivery](https://github.com/mspnp/aks-fabrikam-dronedelivery) & from Azure Baseline Architecture.
This implementation and document is meant to guide an interdisciplinary team or multiple distinct teams like networking, security and development through the process of getting this  baseline infrastructure deployed and understanding the components of it.

## Reference Architecture
This architecture is infrastructure focused, more so than on workload. It concentrates on the AKS cluster itself, including concerns with identity, post-deployment configuration, secret management, and network topologies.

<br/>
The material here is relatively dense. We strongly encourage you to dedicate time to walk through these instructions, with a mind to learning. We do NOT provide any "one click" deployment here. However, once you've understood the components involved and identified the shared responsibilities between your team and your great organization, it is encouraged that you build suitable, auditable deployment processes around your final infrastructure.

<br/>

![kubernetes-eslz-architecture](https://user-images.githubusercontent.com/50182145/129262042-6652bcac-bb2e-4e7d-a20b-92cc8271b0ec.jpg)

## Core architecture components

#### Azure platform

- AKS v1.19
  - System and User [node pool separation](https://docs.microsoft.com/azure/aks/use-system-pools)
  - [AKS-managed Azure AD](https://docs.microsoft.com/azure/aks/managed-aad)
  - Azure AD-backed Kubernetes RBAC (_local user accounts disabled_)
  - Managed Identities
  - Azure CNI
  - [Azure Monitor for containers](https://docs.microsoft.com/azure/azure-monitor/insights/container-insights-overview)
- Azure Virtual Networks (hub-spoke)
  - Azure Firewall managed egress
- Azure Application Gateway (WAF)
- AKS-managed Internal Load Balancers

<br/>

#### In-cluster components
- [Application Gateway Ingress Controller](https://docs.microsoft.com/en-us/azure/application-gateway/ingress-controller-overview)
- [Azure AD Pod Identity](https://docs.microsoft.com/azure/aks/use-azure-ad-pod-identity)
- [Secrets Store CSI Driver for Kubernetes](https://docs.microsoft.com/azure/aks/csi-secrets-store-driver)

<br/>

## Steps of Implementation for AKS Construction Set


A deployment of AKS-hosted workloads typically experiences a separation of duties and lifecycle management in the area of prerequisites, the host network, the cluster infrastructure, and finally the workload itself. This reference implementation is similar. Also, be aware our primary purpose is to illustrate the topology and decisions of a baseline cluster. We feel a "step-by-step" flow will help you learn the pieces of the solution and give you insight into the relationship between them. Ultimately, lifecycle/SDLC management of your cluster and its dependencies will depend on your situation (team roles, organizational standards, etc), and will be implemented as appropriate for your needs.

>We start with Infrastructure Deployments referenced in order listed below
 
1.1 [Creation of Hub Network & its respective Components](./Infrastructure-Deployment/Hub/README.md)

1.2 [Creation of Spoke Network & its respective Components](./Infrastructure-Deployment/Spoke/README.md)

1.3 [Creation of Shared-components](./Infrastructure-Deployment/Shared-Components/README.md)

1.4 [Creation of AKS & enabling Addons](./AKS-Deployment/README.md)
