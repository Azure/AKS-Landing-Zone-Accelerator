###############################################
# Remove ALL resources related to this scenario
###############################################

az group delete -g DNS -y

az group delete -g AKSClusterRegion1 -y
az group delete -g AKSClusterRegion1-networking -y

az group delete -g AKSClusterRegion2 -y
az group delete -g AKSClusterRegion2-networking -y

az group delete -g SupportingResources -y
az group delete -g DataStorage -y

az ad group delete --group AKSClusterAdmins