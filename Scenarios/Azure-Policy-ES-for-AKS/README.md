### ARM Templates for Azure Policy Initiative for for ES AKS ###

The ARM Templates in this directory creates an Enterprise Scale secure baseline Policy Initiative consisting of selected default Azure policies related to Azure Kubernetes Services (AKS). 

This initiative  can be used to audit any brownfield environment to make sure that the AKS clusters comply with the Enterprise Scale best practices. With the enforcement mode set to “Default”, this initiative can be also used to enforce the prohibitive policies for new AKS clusters.  

This ARM template creates 2 resources. It first creates a policy initiative comprising of the default policies in the subscription. It then creates a Policy assignment resource, which assigns this newly created initiative to the subscription. 

Once the initiative is assigned, you can verify the compliance details from the Azure portal. 

Example:

![ES AKS Initiative Compliance Example:](./media/es-aks-initiative.png)
              

#### More details on these policies to follow