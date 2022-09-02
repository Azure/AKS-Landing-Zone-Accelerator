# Blue Green Deployment for AKS

This architectural pattern describes how to properly implement a Blue-Green deployment of an AKS cluster that follows the guiding tenets of the [Azure Well-Architected Framework](https://docs.microsoft.com/en-us/azure/architecture/framework/). For Blue Green deployment at the application level, refer to [this article](https://docs.microsoft.com/en-us/azure/architecture/example-scenario/blue-green-spring/blue-green-spring).
The main purpose of this pattern is to provide a reliable and high availability solution when performing the following tasks:

- Kubernetes version update
- Node pool update, like change VM size
- AKS networking changes
- Kubernetes Operators or Platform components changes like: Service Mesh, DAPR, Ingress Gateway, OPA, etc.

In the above mentioned scenario the desidered outcome is to apply these changes without affecting the applications and/workloads hosted in the AKS cluster.
This pattern is also at the basis for the mission critical deployment of workloads on AKS, the main difference is that in that scenario, the resiliency and AKS distribution in multiple regions are the main drivers and elements of the solution.

The proposed pattern comes also with a Reference Architecture document located [here](./Deployment/bluegreen-aks-solution-content.md).
For guidance and steps to deploy the blue green pattern, refer to this page [Blue Green Deployment](../AKS-Secure-Baseline-PrivateCluster/Terraform/11-blue-green.md)