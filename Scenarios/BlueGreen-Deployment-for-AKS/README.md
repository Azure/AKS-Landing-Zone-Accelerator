# Blue Green Deployment for AKS
This scenario is dedicated to the blue green deployment at AKS level, the main purpose is to provide a reliable and high availability solution when:
- K8S version update
- NodePools update, like chnage VM size
- AKS netwroking changes
- Kubernetes Operators or Platform componennts changes like: Service Mesh, DAPR, Ingress Gateway, OPA, etc.

In the above mentioned scenario the desidered outcome is to apply these changes without affecting the applications and/workloads hosted in the AKS cluster.
This pattern is also at the basis for the mission critical deployment of workloads on AKS, the main difference is that in that scenario the resiliency and AKS distribution in multiple regions are the main drivers and elements of the solution.
The 

The proposed patter comes also wit a reference implementation in [Terraform](./Terraform/).