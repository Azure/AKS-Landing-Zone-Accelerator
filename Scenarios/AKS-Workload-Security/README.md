### Articles in the Workload Security Scenario

Next Reads:

:arrow_forward: [Deploy Open Service Mesh](./OSM/README.md)

## Overview

The topics described in these scenarios will provide guidance on how to protect workloads running on an AKS cluster. Depending on your workload's needs there could be a variety of ways to enhance their security. Microsoft has developed and/or partnered with communities working in open-source to provide projects that can help elevate the security posture of workloads running in Kubernetes and the AKS service. Below are topics to consider to further enhance the security of your workloads.

### Service Mesh

A [Service Mesh](https://en.wikipedia.org/wiki/Service_mesh) provides a way to make communications between service endpoints in your Kubernetes cluster secure by encrypting the communications by way of a proxy. This can be beneficial in several ways, first you can offload the need of your applications having to negotiate encryption as part of its code base, secondly a service mesh provides a single operational control experience to provide security policies and transport security observability across your whole cluster.

[OSM (Open Service Mesh)](openservicemesh.io), is an open-source service mesh, that is integrated with the AKS service as a [managed AKS add-on](https://learn.microsoft.com/en-us/azure/aks/open-service-mesh-about) providing a free fully supported service mesh experience.
