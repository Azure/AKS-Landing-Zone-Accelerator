# Blue Green Deployment for AKS

This architectural pattern describes how to properly implement a Blue-Green deployment of an AKS cluster that follows the guiding tenets of the [Azure Well-Architected Framework](https://learn.microsoft.com/azure/architecture/framework/). For Blue Green deployment at the application level, refer to [this article](https://learn.microsoft.com/azure/architecture/example-scenario/blue-green-spring/blue-green-spring).
The main purpose of this pattern is to provide a reliable and high availability solution when performing the following tasks:

- Kubernetes version update
- Node pool update, like change VM size
- AKS networking changes
- Kubernetes Operators or Platform components changes like: Service Mesh, DAPR, Ingress Gateway, OPA, etc.

In the above mentioned scenario the desired outcome is to apply these changes without affecting the applications and/workloads hosted in the AKS cluster.
This pattern is also at the basis for the mission critical deployment of workloads on AKS, the main difference is that in that scenario, the resiliency and AKS distribution in multiple regions are the main drivers and elements of the solution.

The proposed pattern comes also with a Reference Architecture document in the Azure architecture center [Blue-green deployment for AKS](https://learn.microsoft.com/azure/architecture/reference-architectures/containers/blue-green-deployment-for-aks/blue-green-deployment-for-aks).
Deploy this scenario using the step by step guidance by clicking on the link below:

:arrow_forward: [Terraform](blue-green-deployment.md)
