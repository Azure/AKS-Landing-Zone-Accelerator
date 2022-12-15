// This BICEP template creates a VNET with 2 subnets, an Azure Container Regitry and an AKS cluster with Virtual nodes enabled
// and necessary RBAC role assignments on ACR and subnets. 


param aksname string = 'demo-aks02'
param acrname string = 'demoacr09836'
param vnetname string = 'demo-vnet'
param location string = 'eastus'

//Create ACR
 resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: acrname
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
  }
}

//Create VNET & Subnets
resource virtualNetwork_aks 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: vnetname
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.100.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'aci-subnet'
        properties: {
          addressPrefix: '10.100.0.0/24'
        }
      }
      {
        name: 'aks-subnet'
        properties: {
          addressPrefix: '10.100.1.0/24'
        }
      }
    ]
  }
}

//Create AKS Cluster
resource managedCluster_resource 'Microsoft.ContainerService/managedClusters@2022-06-02-preview' = {
  name: aksname
  location: location
  sku: {
    name: 'Basic'
    tier: 'Paid'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: '1.23.5'
    dnsPrefix: '${aksname}-dns'
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: 1
        vmSize: 'Standard_DS2_v2'
        osDiskSizeGB: 128
        osDiskType: 'Managed'
        kubeletDiskType: 'OS'
        vnetSubnetID: resourceId('Microsoft.Network/virtualNetworks/subnets',virtualNetwork_aks.name, 'aks-subnet')
        maxPods: 110
        type: 'VirtualMachineScaleSets'
        enableAutoScaling: false
        orchestratorVersion: '1.23.5'
        enableNodePublicIP: false
        mode: 'System'
        osType: 'Linux'
        osSKU: 'Ubuntu'
        enableFIPS: false
      }
    ]
    servicePrincipalProfile: {
      clientId: 'msi'
    }
    addonProfiles: {
      aciConnectorLinux: {
        enabled: true
        config: {
          SubnetName: 'aci-subnet'
        }
      }
      httpApplicationRouting: {
        enabled: false
      }
      
    }
    enableRBAC: true
    nodeResourceGroup: 'MC_${aksname}_${location}'
    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'azure'
      loadBalancerSku: 'Standard'
      serviceCidr: '10.200.0.0/18'
      dnsServiceIP: '10.200.0.10'
      dockerBridgeCidr: '172.17.0.1/16'
      outboundType: 'loadBalancer'
      serviceCidrs: [
        '10.200.0.0/18'
      ]
      ipFamilies: [
        'IPv4'
      ]
    }
    disableLocalAccounts: false
  }
}

//Assign Network Contributor Role on vnet/subnet
resource NwcontributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: '4d97b98b-1d4f-4787-a291-c67834d212e7'
}
resource vnetRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(resourceGroup().id, managedCluster_resource.id, NwcontributorRoleDefinition.id)
  scope: virtualNetwork_aks
  properties: {
    roleDefinitionId: NwcontributorRoleDefinition.id
    //principalId: aciConnectorManagedIdentity.properties.principalId
    principalId: managedCluster_resource.properties.addonProfiles.aciConnectorLinux.identity.objectId
    principalType: 'ServicePrincipal'
  }
}

//Assign acrPull Role on ACR
resource acrPullRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
}
resource acrRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(resourceGroup().id, containerRegistry.id, acrPullRoleDefinition.id)
  scope: containerRegistry
  properties: {
    roleDefinitionId: acrPullRoleDefinition.id
    principalId: managedCluster_resource.properties.identityProfile.kubeletidentity.objectId
    principalType: 'ServicePrincipal'
  }
}

output aks_object string = managedCluster_resource.identity.principalId
output aciConnectorManagedIdentity string = managedCluster_resource.properties.addonProfiles.aciConnectorLinux.identity.objectId
