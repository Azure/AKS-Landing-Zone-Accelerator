## Configure Permissions and add required packages

In order to enable and manage AKS Fleet Manager, configure the following permissions for the Entra ID group you created at the start of this levelup.

```bash

aksAdminsGroupId=$(az ad group show --group AKSCADMs --query id -o tsv)

az role assignment create --assignee-object-id $aksAdminsGroupId --role 'Azure Kubernetes Fleet Manager RBAC Cluster Admin' --scope 'subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RGNAME}'

# Ensure you have installed Azure CLI to version 2.53.1 or later

az upgrade

# Add the fleet extension

az extension add --name fleet

# Install the kubectl and kubelogin packages

az aks install-cli

```

## Set environment variables

```bash
export SUBSCRIPTION_ID=<subscription_id>
export GROUP=$RGNAME
export FLEET=<your_fleet_name> #Keep the value of this lowercase
```

## Configure Fleet

There are 2 options when configuring Fleet - With or without a hub. Hubless fleet allows you to perform update orchestration across multiple clusters. Fleet with a hub allows you to perform application deployment across multiple clusters and multi-cluster load balancing, on top of update orchestration. In this example, we will be configuring Fleet with a hub which may take slightly longer due to the requirement of creating a new hub cluster.

In this example we will be configuring a lot of the defaults, however there are additional parameters you can pass in production environments such as managed identity support and private cluster networking.

```bash
az fleet create --resource-group ${GROUP} --name ${FLEET} --location eastus --enable-hub
```

Set environment variables for the member clusters

``bash
export MEMBER_NAME_1=${FIRSTCLUSTERNAME} #Ensure this value is lowercase
export MEMBER_CLUSTER_ID_1=/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${GROUP}/providers/Microsoft.ContainerService/managedClusters/${FIRSTCLUSTERNAME}

export MEMBER_NAME_2=${SECONDCLUSTERNAME} #Ensure this value is lowercase
export MEMBER_CLUSTER_ID_2=/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${GROUP}/providers/Microsoft.ContainerService/managedClusters/${SECONDCLUSTERNAME}
```

Add both clusters as members to the fleet hub.

```bash
az fleet member create --resource-group ${GROUP} --fleet-name ${FLEET} --name ${MEMBER_NAME_1} --member-cluster-id ${MEMBER_CLUSTER_ID_1}

az fleet member create --resource-group ${GROUP} --fleet-name ${FLEET} --name ${MEMBER_NAME_2} --member-cluster-id ${MEMBER_CLUSTER_ID_2}
```

You can run the following command to check that both members have been added as members successfully.

```bash
az fleet member list --resource-group ${GROUP} --fleet-name ${FLEET} -o table
```

#Access the API of the Fleet resource

```bash
az fleet get-credentials --resource-group ${GROUP} --name ${FLEET}
```

Create the namespace to synchronise to other clusters in the fleet
```bash
kubectl create namespace fleet-namespace
```

Apply the ClusterResourcePlacement which will tell the hub cluster to deploy the namespaces to the member clusters.

```bash
kubectl apply -f - <<EOF
apiVersion: placement.kubernetes-fleet.io/v1beta1
kind: ClusterResourcePlacement
metadata:
  name: crp
spec:
  resourceSelectors:
    - group: ""
      kind: Namespace
      version: v1
      name: fleet-namespace
  policy:
    placementType: PickAll
EOF
```

You can check the status of the CRP by using the following command

```bash
kubectl describe clusterresourceplacement crp
```

Finally you can log in to one of the member clusters and check if the namespace is present

```bash
az aks get-credentials -n $SECONDCLUSTERNAME -g $GROUP
kubectl get ns
```

