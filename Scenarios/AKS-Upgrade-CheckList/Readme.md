# AKS Upgrade Check List

## Introduction

The objective of this document is to provide the checks and the issues that might happen when upgrading an AKS cluster.

## 1. Infrastructure related issues

SPN issue (Akshay Nimbalkar have more details)

### 1. Issue: All cached container images are removed during upgrade.
**Solution:** No magic solution.

### 2. Issue : insufficient computer (CRP) quota

https://learn.microsoft.com/en-us/troubleshoot/azure/azure-kubernetes/upgrading-or-scaling-does-not-succeed#cause-1-cluster-is-in-a-failed-state

## 2. Networking related issues

### 1. Issue: AKS Subnet is full.
**Explanation:** During cluster upgrade, AKS will providion one or more Surge Node (or also known as Buffer) VMs and deploy pods into it. This means more IP adresses will be consumed from the cluster Subnet. Which may result in IP exhaustion issue, i.e Subnet is running out of available IPS.
**Solution:** Consider migration to a bigger Subnet range.

### 2. Issue: AKS has no access to microsoft registries
**Explanation:** During cluster restarts/version upgrades/node updates/scaling operations , AKS would need to provision or reimage the cluster nodes , and that requires creating/updating virtual machines in the virtual machine scaleset of the nodepool.
During upgrades , AKS would cordon and drain the existing nodes (one by one or based on a custom percentage) , create surge nodes to host the evacuated pods , upgrade the old nodes , and eventually deletes the surge nodes.
that process requires bootstrapping VMs into AKS nodes and that is realised using custom scripts hosted in microsoft registires. if access to those registries is blocked the upgrade would fail after multiple retries.  
**Solution:** Before launching the upgrade check that egress traffic towards microsoft registries (mcr.microsoft.com) is allowed on the following components if you're using any of them:
- Network security group attached to the AKS subnet
- route table associated with the AKS subnet : verify that the registry URL is not blocked by your proxy or firewall solution
- in case you're using a custom DNS on the VNET embedding the AKS subnet , make sure that micosoft and azure domains are being forwarded to Azure DNS resolver 168.63.129.16  
Please refer to this link for more details  https://learn.microsoft.com/en-us/azure/aks/outbound-rules-control-egress   

## 3. Kubernetes versions related issues

### 1. Kubernetes API versions might be deprecated.
whenever you try to upgrade the AKS version , there is a checklist generated on the portal once you select the target version and it contains all the deprecated Kube APIs 

### 2. Cgroup level changes
**Explanation:** upgrading from any AKS version to 1.25.X might cause various issues due to default activation of cgroup V2 instead of cgroup v1 on the nodes.
the main detected issues are the following :
#### 1. Issue: Higher memory consumption.
the migration from cgroup V1 to cgroup V2 causes higher memory consumption on the pods which leads to memory issues on the hosting nodes  , this is due to application runtimes incompatibility with cgroupV2
#### 2. Issue: Applications crashing with no obvious exist code
the migration from cgroup V1 to cgroup V2 may cause applications to crash and puts the pods in a crashloopbackoff status  , this is also due to application runtimes incompatibility with cgroupV2
**Solution:** please refer to this link for knwon compatible application runtimes https://kubernetes.io/docs/concepts/architecture/cgroups/



## 4. Applications related issues

### 1. Issue : fail to drain a node due to poddisruptionbudget constraint 

https://learn.microsoft.com/en-us/troubleshoot/azure/azure-kubernetes/error-code-poddrainfailure
