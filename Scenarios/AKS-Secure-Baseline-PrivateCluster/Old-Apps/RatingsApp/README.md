# Deploying the Workload

To deploy this workload, you will need to be able to access the Azure Container Registry that was deployed as part of the supporting infrastructure for AKS.  The container registry was configured to only be accessible from a build agent on the private network. 

If you use the Dev Server for this, the following tools must be installed:

1. Azure CLI

```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

2. Docker CLI

```bash
apt install docker.io
```

You will need to clone the following repos:

1. The public repo for the Fruit Smoothie API.

```bash
git clone https://github.com/MicrosoftDocs/mslearn-aks-workshop-ratings-api.git
```

2. The public repo for the Fruit Smoothie Web Frontend:

```bash
git clone https://github.com/MicrosoftDocs/mslearn-aks-workshop-ratings-web.git
```

3. This repo, for the application code  - /AKS-Landing-Zone-Accelerator/Scenarios/Secure-Baseline/Apps/RatingsApp
