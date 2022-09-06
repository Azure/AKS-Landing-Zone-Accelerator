# Blue Green Deployment

Here you find the details of the steps to deploy the blue green deployment pattern. The reference implementation is based on the existing secure baseline implementation with the addition of new data structure to add abstraction to manage multiple AKS clusters, in this case 2 AKS clusters, the blue and green, and additional supporting azure resources like: Application Gateway and Public DNS Zone.

The new introduced data structures are:

- Application Gateway map to deploy the blue and green Application Gateways, there is a one to one mapping between the AKS clusters and Application Gateways due to the adoption of the AGIC addon for AKS.
Below is data structure and related documentation. By default only the blue application gateway is deployed.

```
locals {
  Map of the aure application gateway to deploy
  appgws = {
    "appgw_blue" = {
      prefix used to configure uniques names and parameter values
      name_prefix="blue"
      Boolean flag that enable or disable the deployment of the specific application gateway
      appgw_turn_on=true
    },
    "appgw_green" = {
      name_prefix="green"
      appgw_turn_on=false
    }
  }
}
```

- The other map structure is dedicated to the AKS clusters. Below the data structure and related documentation. By default only the blue AKS cluster is deployed.

```
locals {
  Map of the AKS Clusters to deploy
  aks_clusters = {
    "aks_blue" = {
      prefix used to configure unique names and parameter values
      name_prefix="blue"
      Boolean flag that enable or disable the deployment of the specific AKS cluster
      aks_turn_on=true
      The kubernetes version to use on the cluster
      k8s_version="1.23.5"
      Reference Name to the Application gateway that need to be associated to the AKS Cluster with the AGIC add-on
      appgw_name="lzappgw-blue"
    },
    "aks_green" = {
      name_prefix="green"
      aks_turn_on=false
      k8s_version="1.23.8"
      appgw_name="lzappgw-green"
    }
  }
}
```

As part of the blue green deployment there is the configuration of 3 hostnames required to implement the pattern:
- Public facing hostname, the one used by the end users of the workloads/apps hosted into the clusters
- blue cluster hostname, that is dedicated for the internal validation
- green cluster hostname, that is dedicated for the internal validation

The tasks to test a blue green deployment can be summarized as follow:
1. T0: Blue Cluster is On, this means:
  - "blue cluster" and "blue app gateway" with aks_turn_on=true and appgw_turn_on=true
  - "green cluster" and "green app gateway" with aks_turn_on=false and appgw_turn_on=false
  - A record mapped with the PIP of the Blue Application Gateway
  This is where you end up if you follow the steps in the default scenario [Getting Started with the default values](../README.md)
2. T1: Green Cluster Deployment
  - "blue cluster" and "blue app gateway" with aks_turn_on=true and appgw_turn_on=true
  - "green cluster" and "green app gateway" with aks_turn_on=true and appgw_turn_on=true
  - A record mapped with the PIP of the Blue Application Gateway
3. T2: Sync K8S State between Blue and Green clusters
4. T3: Traffic Switch to the green cluster
  - "blue cluster" and "blue app gateway" with aks_turn_on=true and appgw_turn_on=true
  - "green cluster" and "green app gateway" with aks_turn_on=true and appgw_turn_on=true
  - A record mapped with the PIP of the Green Application Gateway
5. T4: Blue cluster is destroyed
  - "blue cluster" and "blue app gateway" with aks_turn_on=false and appgw_turn_on=false
  - "green cluster" and "green app gateway" with aks_turn_on=true and appgw_turn_on=true
  - A record mapped with the PIP of the Green Application Gateway

## T0: Blue Cluster is On. Deploy the AKS cluster

Follow the steps starting [here](./02-state-storage.md) to deploy the private cluster using the default values if you haven't already but do not deploy the workload (stage 08).
> :warning: Do not deploy the fruit smoothie application highlighted in step 08-workload.md
The default values are:

- in the file "Scenarios\AKS-Secure-Baseline-PrivateCluster\Terraform\05-Network-LZ\app-gateway.tf"
```
locals {
  appgws = {
    "appgw_blue" = {
      name_prefix="blue"
      appgw_turn_on=true
    },
    "appgw_green" = {
      name_prefix="green"
      appgw_turn_on=false
    }
  }
}

```

- in the file "Scenarios\AKS-Secure-Baseline-PrivateCluster\Terraform\07-AKS-cluster\aks-cluster.tf"

```
locals {
  aks_clusters = {
    "aks_blue" = {
      name_prefix="blue"
      aks_turn_on=true
      k8s_version="1.23.5"
      appgw_name="lzappgw-blue"
    },
    "aks_green" = {
      name_prefix="green"
      aks_turn_on=false
      k8s_version="1.23.5"
      appgw_name="lzappgw-green"
    }
  }
}

```

## Create Public DNS Record to publish and invoke endpoitns/apps hostend in the AKS Clusters

This stage is required only for the blue green deployment.

The following will be created:

* A Records

Navigate to "/Scenarios/AKS-Secure-Baseline-PrivateCluster/Terraform/08-DNS-Records" folder
```bash
cd ../08-DNS-Records
```

This deployment will need to reference data objects from the Spoke deployment and will need access to the pre-existing terraform state file. This data is stored in an Azure storage account accessible through an access key. This is a sensitive variable and should not be committed to the code repo.

Once again, a sample terraform.tfvars.sample file is included. Update the required variables, save it and rename it to **terraform.tfvars**.

Once the files are updated, deploy using Terraform Init, Plan and Apply.

```bash
terraform init -backend-config="resource_group_name=$TFSTATE_RG" -backend-config="storage_account_name=$STORAGEACCOUNTNAME" -backend-config="container_name=$CONTAINERNAME"
```

```bash
terraform plan
```

```bash
terraform apply
```

If you get an error about changes to the configuration, go with the `-reconfigure` flag option.

## Install the application

After the deployment if the Landing Zone, install a sample application to test the deployment. The sample application to use is stored in the file "Scenarios\AKS-Secure-Baseline-PrivateCluster\Terraform\07-AKS-cluster\sample-workload-for-agic-test.yaml".

```bash
az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl apply -f sample-workload-for-agic-test.yaml "
```

As an alternative you can run the kubectl command directly from the Linux jump box access of the BastionHost provisoned as part in the [hub network](./04-network-hub.md).

As prerequisite to check deployment of the sample application is required to configure the NSG associated to the Application Gateway.
In detail the NSG needs to accept traffic on port 80 if using the HTTP option. Run the following command to allow HTTP.

```bash
   APPGWSUBNSG=<Name of NSG for AppGwy>
   az network nsg rule create -g $SPOKERG --nsg-name $APPGWSUBNSG -n AllowHTTPInbound --priority 1000 \
      --source-address-prefixes '*' --source-port-ranges '*' \
      --destination-address-prefixes '*' --destination-port-ranges 80 --access Allow \
      --protocol Tcp --description "Allow Inbound traffic through the Application Gateway on port 80"
```

This configuration is only for testing purpose, for production workloads is trongly suggested to use HTTPS.

If you have deployed the public dns zone that is part of [AKS-Supporting](./06-aks-supporting.md), than you can test the deployment, executing an invocation to the sample app.

```bash
curl http://{hostname-app}.{public_domain}/
```

If the azure public dns zone is not attached to the domain, than is possible to test the app endpoint with the followwing command.

```bash
curl -H "Host: {hostname-app}.{public_domain}" http://{app-gateway-pip}/
```

## T1: Green Cluster Deployment

At this stage is required to perfor the following action to deploy the new green cluster in co-existence with the blue one.

1. Run again the flow mentioned [here](./05-network-lz.md), with the following configuration in the file "Scenarios\AKS-Secure-Baseline-PrivateCluster\Terraform\05-Network-LZ\app-gateway.tf"

```
locals {
  appgws = {
    "appgw_blue" = {
      name_prefix="blue"
      appgw_turn_on=true
    },
    "appgw_green" = {
      name_prefix="green"
      appgw_turn_on=true
    }
  }
}

```

2. Run the flow mentioned [here](./07-aks-cluster.md), with the following configuration in the file "Scenarios\AKS-Secure-Baseline-PrivateCluster\Terraform\07-AKS-cluster\aks-cluster.tf"

```
locals {
  aks_clusters = {
    "aks_blue" = {
      name_prefix="blue"
      aks_turn_on=true
      k8s_version="1.23.5"
      appgw_name="lzappgw-blue"
    },
    "aks_green" = {
      name_prefix="green"
      aks_turn_on=true
      k8s_version="1.23.5"
      appgw_name="lzappgw-green"
    }
  }
}

```

## T2: Sync K8S State between Blue and Green clusters

In our case, this means deploying the sample workload and related K8S resources in the green cluster.

```bash
az aks get-credentials --resource-group $ClusterRGName --name $GreenClusterName
az aks command invoke --resource-group $ClusterRGName --name $GreenClusterName  --command "kubectl apply -f sample-workload-for-agic-test.yaml "
```

after the deployment you can test the application with the following command.

```bash
curl -H "Host: {hostname-app-green}.{public_domain}" http://{app-gateway-pip}/
```

where app-gateway-pip is the public ip of the green appplication gateway. 
If the validation is ok, than the new cluster can be promoted as new production/stable cluster. Follow the instruction described in the [next section](#t3-traffic-switch-to-the-green-cluster).

## T3: Traffic Switch to the green cluster

In this step is required to update the DNS A Record in order to switch the traffic to the PIP assigned to the green cluster.
You need to run the flow describe [here](./09-dns-records.md) with the following variable in input.

```
arecords_apps_map = {
    "testapp" = {
      aks_active_prefix="green"
      record_name={your_app_hostname}
    }
}
```

Than you can test that the switch is performed with the following command.

```bash
curl http://{hostname-app}.{public_domain}/
```

If the validation is ok than you can move to the lasst step

## T4: Blue cluster is destroyed

At this stage you can destroy the blue AKS cluster and Application Gateway attached to it.
This means:

1. Run the flow mentioned [here](./07-aks-cluster.md), with the following configuration in the file "Scenarios\AKS-Secure-Baseline-PrivateCluster\Terraform\07-AKS-cluster\aks-cluster.tf"

```
locals {
  aks_clusters = {
    "aks_blue" = {
      name_prefix="blue"
      aks_turn_on=false
      k8s_version="1.23.5"
      appgw_name="lzappgw-blue"
    },
    "aks_green" = {
      name_prefix="green"
      aks_turn_on=true
      k8s_version="1.23.5"
      appgw_name="lzappgw-green"
    }
  }
}

```

2. Run again the flow mentioned [here](./05-network-lz.md), with the following configuration in the file "Scenarios\AKS-Secure-Baseline-PrivateCluster\Terraform\05-Network-LZ\app-gateway.tf"

```
locals {
  appgws = {
    "appgw_blue" = {
      name_prefix="blue"
      appgw_turn_on=false
    },
    "appgw_green" = {
      name_prefix="green"
      appgw_turn_on=true
    }
  }
}

```

## Next Step

:arrow_forward: [Cleanup](../AKS-Secure-Baseline-PrivateCluster/Terraform/09-cleanup.md)