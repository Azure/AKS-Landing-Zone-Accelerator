# Build Intelligent Apps on AKS Challenge

Create CICD pipeline to automate OpenAI web application deployment to AKS.

Assumption is that infrastructure, setting variables and keyvault secrets were done following OpenAI Scenario  steps in [README.md](../AKS-OpenAI-CogServe-Redis-Embeddings/README.md)

## Create GitHub Identity Federated with AAD

Simplest way to create template for Github workflow is to use AKS **Automated deployments** wizard.
It will create Github identity federated with AAD and grant to it required permissions to AKS and ACR

Fork `AKS-Landing-Zone-Accelerator` repo and use wizard option to "Deploy an application" pointing it to your fork and selecting provisioned ACR and AKS

## Update GitHub workflow for Kustomize steps
Once deployment wizard is finished it will create PR with sample github flow that could be updated to match the steps required to run Kustomize

- Add variables section and specify all variables that were queried from deployment 
- Add Repo secret `CLIENT_ID` to value retrieved during infrastructure setup
- Add step to prepare `.env` file with all replacement variables 
- Add step to bake Kubernetes manifest from Kustomize files
- Modify deployment step to refer to Kustomize built manifest


If you would like to see completed workflow - it could be found in the following repo in the [workflows folder](../../.github/workflows/deploy-openai-embeddings-app.yaml)
