Switch to the infrastruture folder

```bash
    cd infrastructure
```
```bash
    RGNAME=embedding-openai-rg
    LOCATION=eastus
    az group create -l $LOCATION -n $RGNAME
```

create the supporting resources (openai, storageaccount, translator, form reader)
```bash
 az deployment group create -g $RGNAME  --name intelligentappsdeployment --template-file intelligent-services.bicep --parameters parameters.json --parameters UniqueString=<your unique string>
```

get the openai api key from the created openai resource in the portal 

create the aks cluster and other supporting resources (acr, keyvault, etc). Get your signed in user information first which will be used to ensure you have access to the cluster.
```bash
SIGNEDINUSER=$(az ad signed-in-user show --query id --out tsv)
```

```bash
DEP=$(az deployment group create --name aksenvironmentdeployment -g $RGNAME  --parameters signedinuser=$SIGNEDINUSER api_key=<your openai key>  -f aks.bicep -o json)
```

KVNAME=$(echo $DEP | jq -r '.properties.outputs.kvAppName.value')
OIDCISSUERURL=$(echo $DEP | jq -r '.properties.outputs.aksOidcIssuerUrl.value')
AKSCLUSTER=$(echo $DEP | jq -r '.properties.outputs.aksClusterName.value')
EMBEDINGAPPID=$(echo $DEP | jq -r '.properties.outputs.idsuperappClientId.value')
TENANTID=$(az account show --query tenantId -o tsv)
ACRNAME=$(az acr list -g $RGNAME --query [0].name  -o tsv)



cd k8s
sed -i  "s/<identity clientID>/$EMBEDINGAPPID/" secret-provider-class.yaml
sed -i  "s/<kv name>/$KVNAME/" secret-provider-class.yaml
sed -i  "s/<tenant ID>/$TENANTID/" secret-provider-class.yaml

sed -i  "s/<identity clientID>/$EMBEDINGAPPID/" svc-accounts.yaml
sed -i  "s/<tenant ID>/$TENANTID/" svc-accounts.yaml

update the env-configmap.yaml file with the correct environment variables

log into the AKS cluster

```bash
az aks get-credentials -g $RGNAME -n aks-embedings-cluster
```

cd to the manifests folder
```bash
cd ../kubernetes
```

deploy the kubernetes resources
```
kubectl apply -f .
```



