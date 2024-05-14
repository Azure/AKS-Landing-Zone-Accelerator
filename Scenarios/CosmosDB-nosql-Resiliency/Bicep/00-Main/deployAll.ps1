# Deploy the whole scenario

# Change values to suit your preferences
$region1 = "swedencentral"
$region2 = "westeurope"
$tenantDomainName = "xxxxx.onmicrosoft.com"
$aksAdminsGroup = "AKSClusterAdmins"

################################
################################
# Main Deployment - don't change
################################
################################

$dateCode = (Get-Date).ToString("yyyyMMddhhmmss")

# Login to AZ Subscription and create required AKS admin group + membership
Write-Host "`nLogging into AAD tenant and creating AKS admins group...."
#az login -t $tenantDomainName
$currentUserGuid = az ad signed-in-user show --query id -o tsv  
az ad group create --display-name AKSClusterAdmins --mail-nickname AKSClusterAdmins --description "Members who can administer AKS Clusters"
$aksAdminsGroupId = az ad group show --group AKSClusterAdmins --query id -o tsv
az ad group member add --group $aksAdminsGroup --member-id $currentUserGuid

##############################################
# Create CosmosDB & VNet with private endpoint
##############################################
Set-Location ..\01-Database
Write-Host "`nCreating Cosmos Database...."
az deployment sub create -n $("Database-$dateCode") -l $region1 -f main.bicep -p parameters.json
$cosmosDbVnetResourceId = az deployment sub show -n $("Database-$dateCode") --query properties.outputs.cosmosDbVnetResourceId.value -o tsv
$cosmosDbName = az deployment sub show -n $("Database-$dateCode") --query properties.outputs.cosmosDbName.value -o tsv

#############################################################
# Create supporting resources (Azure Container Registry etc.)
#############################################################
Set-Location ..\02-AKS-Supporting
Write-Host "`nCreating supporting resources...."
az deployment sub create -n $("SupportingServices-$dateCode")  -l $region1 -f main.bicep -p parameters.json
$acrName = az deployment sub show -n $("SupportingServices-$dateCode") --query properties.outputs.acrName.value -o tsv

#############################################
# Create an AKS cluster in the primary region
#############################################
Set-Location ..\03-AKSCluster-Region1
Write-Host "`nCreating AKS Cluster in region 1...."
az deployment sub create -n $("AKSRegion1-$dateCode") -l $region1 -f main.bicep -p parameters.json -p cosmosDbVnetResourceId=$cosmosDbVnetResourceId -p aksAdminsGroupId=$aksAdminsGroupId
$aksClusterVnetRegion1ResourceId = az deployment sub show -n $("AKSRegion1-$dateCode") --query properties.outputs.aksClusterVnetRegion1ResourceId.value -o tsv
# Attaching AKS to an ACR does not currently seem possible using the AKS AVM, so use the command line instead.
Write-Host "`nAttaching primary AKS cluster to the container registry...."
az aks update -n aksclusterRegion1 -g AKSClusterRegion1 --attach-acr $acrName

#############################################
# Create an AKS cluster in the secondry region
#############################################
Set-Location ..\04-AKSCluster-Region2
Write-Host "`nCreating AKS Cluster in region 2...."
az deployment sub create -n $("AKSRegion2-$dateCode") -l $region2 -f main.bicep -p parameters.json -p cosmosDbVnetResourceId=$cosmosDbVnetResourceId -p aksAdminsGroupId=$aksAdminsGroupId
$aksClusterVnetRegion2ResourceId = az deployment sub show -n $("AKSRegion2-$dateCode") --query properties.outputs.aksClusterVnetRegion2ResourceId.value -o tsv
# Attaching AKS to an ACR does not currently seem possible using the AKS AVM, so use the command line instead.
Write-Host "`nAttaching secondry AKS cluster to the container registry...."
az aks update -n aksclusterRegion2 -g AKSClusterRegion2 --attach-acr $acrName

################################################
# Link private DNS Zone to each AKS Cluster VNet
################################################
Set-Location ..\05-InternalDNS
Write-Host "`nLinking private DNS Zone to each AKS Cluster VNet...."
az deployment sub create -n $("DNS-$dateCode") -l $region1 -f main.bicep -p parameters.json -p cosmosdbname=$cosmosDbName -p aksClusterVnetRegion1ResourceId=$aksClusterVnetRegion1ResourceId -p aksClusterVnetRegion2ResourceId=$aksClusterVnetRegion2ResourceId

#########################################
# Setup workload identity for aksCluster1
#########################################
Set-Location ..\06-WorkloadIdentity
az deployment sub create -n $("WorkloadIdentity-$dateCode") -l $region1 -f main.bicep -p parameters.json
$workloadIdentityId = az deployment sub show -n $("WorkloadIdentity-$dateCode") --query properties.outputs.workloadIdentityId.value -o tsv
az aks get-credentials --name aksclusterRegion1 --resource-group AKSClusterRegion1 --overwrite-existing
kubectl config use-context  aksclusterRegion1

$aksServiceAccount = @"
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    azure.workload.identity/client-id: "$workloadIdentityId"
  name: "workload-identity-sa"
  namespace: "default"
"@

$aksServiceAccount | kubectl apply -f -

$region1OIDCIssuer = az aks show --resource-group AKSClusterRegion1 --name AKSClusterRegion1 --query "oidcIssuerProfile.issuerUrl" -o tsv
az identity federated-credential create --name workloadFederatedIdentity --identity-name WorkloadIdentity --resource-group WorkloadIdentity --issuer $region1OIDCIssuer --subject system:serviceaccount:"default":"workload-identity-sa" --audience api://AzureADTokenExchange

##############################################
# End
##############################################
Set-Location ..\00-Main

















####################################################
# Helpful links and scripts to troubleshoot failures
####################################################

# To test DNS is working from inside an AKS cluster, run the following commands:
# kubectl run -it --rm aks-ssh --namespace default --image=debian:stable
# apt-get update -y
# apt-get install dnsutils -y
# host -a www.github.com  (should return a public IP)
# host -a <your-cosmosdbname>.documents.azure.com (should return 10.0.1.4)

# Troubleshoot DNS not working
# https://learn.microsoft.com/en-us/troubleshoot/azure/azure-kubernetes/connectivity/troubleshoot-dns-failure-from-pod-but-not-from-worker-node

# Workload identity setup
# https://learn.microsoft.com/en-us/azure/aks/workload-identity-deploy-cluster

# Longer workload identity setup lab
# https://techcommunity.microsoft.com/t5/microsoft-developer-community/lab-guide-aks-workload-identity/ba-p/3728630

######################
# Workload testing pod
######################
# $sampleApplication = @"
# apiVersion: v1
# kind: Pod
# metadata:
#   name: testpod
#   namespace: "default"
#   labels:
#     azure.workload.identity/use: "true"  # Required, only the pods with this label can use workload identity
# spec:
#   serviceAccountName: "workload-identity-sa"
#   containers:
#     - image: debian:stable
#       name: debianstable
#       command: ["/bin/bash", "-c"]
#       args: ["while true; do echo 'Sleeping for 1 hour'; sleep 3600; done"]
# "@

# $sampleApplication | kubectl apply -f -
# kubectl exec -it testpod -- /bin/sh
