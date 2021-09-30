## Azure Policy Initiative for Enterprise Scale for AKS
You can deploy our initiative to help audit and govern your AKS cluster to help ensure it is conforming with Enterprise Scale for AKS best practices. This is particularly useful for brownfield deployments to "audit" the cluster and identify improvment opportunities. 

#### Folder Structure:

    1. Policys Folder : This folder contains two json files one is the deployment file(akspolicydeploy.json) and parameter file(akspolicyparam.json). 
    2. azurepolicy.yml File : This is the yaml file which is used to deploy the Policys using the ADO Pipeline. Need to select this file when you are creating the Pipeline and Provide the Service Connection name in the Filed(azureResourceManagerConnection).

 ### Parameters :                                  

```
        1. Management Group Id : Provide the scope of the Management Group Id where the policys need to be present.             
        2. Log Analitics Id (Deploy_diagnostic_settings_AKS_to_Log_Analytics_workspace) : Provide the Log Analytics Workspace Id where the diagnostic settings Logs for the AKS Cluster is stored.                
        3. Effects: Each Policy contains individual Effects Parameters as per the policy name in the paramater file. There are allowed values present in the deployment file for each Effect parameter. As per the requirement provide the value in the Parameter.                                                         
```
### More details on this initiative to follow. 