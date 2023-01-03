# Azure Kubernetes Service on Azure Stack HCI or Windows Server

AKS-HCI makes our popular Azure Kubernetes Service (AKS) available on-premises. It fulfils the key need for an on-premises App Platform in the Azure hybrid cloud stack that goes from bare metal all the way into Azure-connected experiences in the cloud.

AKS-HCI is a turn-key solution for Administrators to easily deploy, manage lifecycle of, and secure Kubernetes clusters in datacenters and edge locations, and developers to run and manage modern applications – all in an Azure-consistent manner. Complete end-to-end support and servicing from Microsoft – as a single vendor – makes this is a robust Kubernetes application platform that customers can trust with their production workloads.

AKS-HCI is an Azure service that is hybrid by design. It leverages our experience with AKS, follows the AKS design patterns and best-practices, and uses code directly from AKS. This means that you can use AKS-HCI to develop applications on AKS and deploy them unchanged on-premises. It also means that any skills that you learn with AKS on Azure Stack HCI are transferable to AKS as well. With Azure Arc capability built-in, you can manage your fleet of clusters centrally from Azure, deploy applications and apply configuration using GitOps-based configuration management, view and monitor your clusters using Azure Monitor for containers, enforce threat protection using Azure Defender for Kubernetes, apply policies using Azure Policy for Kubernetes, and run Azure services like Arc-enabled Data Services on premises.

No matter how you choose to deploy AKS-HCI – wizard-driven workflow in [Windows Admin Center (WAC)](https://learn.microsoft.com/azure-stack/aks-hci/setup) or [PowerShell](https://learn.microsoft.com/azure-stack/aks-hci/kubernetes-walkthrough-powershell) – your cluster is ready to host workloads in less than an hour. Under the hood, the deployment takes care of everything that’s required to bring up Kubernetes and run applications. This includes core Kubernetes, container runtime, networking, storage, and security, and operators to manage underlying infrastructure. Scaling the cluster up or down by adding/removing nodes and cluster-updates/upgrades are equally quick and easy. So is ongoing local management through WAC or PowerShell.

AKS-HCI is the best platform for running .Net Core and Framework applications – whether your applications are based on Linux or Windows. The infrastructure required to run containers is included and fully supported. For Windows, AKS-HCI offers an industry-leading solution with advanced features like GMSA non-domain joined hosts, Active Directory integration, and WAC based application deployment, migration, and management. We want to ensure that AKS-HCI remains the best destination for Windows containers.

Customers are using AKS-HCI to run cloud-native workloads, modernize legacy Windows workloads, and/or Arc-enabled Data Services on-premises. As more and more Azure services become available to be run on-premises, AKS-HCI will continue to be the industry-leading and preferred destination.

## Next

* If you have no hardware, To deploy AKS on Azure Stack HCI in an Azure VM try out our [eval guide](https://docs.microsoft.com/en-us/azure-stack/aks-hci/aks-hci-evaluation-guide)

* If you already have a configured cluster. Try out the [Jumpstart guide](https://azurearcjumpstart.io/azure_arc_jumpstart/azure_arc_k8s/aks_stack_hci/aks_hci_powershell/).  The commands described in this scenario should be run on the management computer or in a host server in a cluster
