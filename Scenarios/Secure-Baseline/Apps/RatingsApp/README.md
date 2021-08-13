# Deploying the Workload
A suggested example workload for the cluster is detailed in this MS Learning Workshop https://docs.microsoft.com/en-us/learn/modules/aks-workshop/. 

To deploy this workload, you will need to be able to access the Azure Container Registry that was deployed as part of the supporting infrastructure for AKS.  The container registry was configured to only be accessible from a build agent on the private network. 

If you use the Dev Server for this, the following tools must be installed:
1. Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

2. Docker CLI
apt install docker.io

You will need to clone the following repos:

1. The public repo for the Fruit Smoothie API.  
git clone https://github.com/MicrosoftDocs/mslearn-aks-workshop-ratings-api.git

2. The public repo for the Fruit Smootie Web Frontend:
git clone https://github.com/MicrosoftDocs/mslearn-aks-workshop-ratings-web.git

3. This repo, for the application code  - /Enterprise-Scale-for-AKS/Scenarios/Secure-Baseline/Apps/RatingsApp









