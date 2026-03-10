targetScope = 'subscription'

@description('Resource group name for the Istio mesh scenario.')
param rgName string = 'AKS-Istio-Mesh-RG'

@description('Location for all resources.')
param location string = deployment().location

@description('Name of the virtual network.')
param vnetName string = 'istio-mesh-vnet'

@description('Address prefixes for the VNet.')
param vnetAddressPrefixes array = ['10.10.0.0/16']

@description('AKS subnet address prefix.')
param aksSubnetPrefix string = '10.10.1.0/24'

@description('Name of the AKS cluster.')
param aksClusterName string = 'aks-istio-mesh'

@description('Kubernetes version.')
param kubernetesVersion string = '1.30'

@description('VM size for the AKS system node pool.')
param vmSize string = 'Standard_DS4_v2'

@description('Entra ID admin group object ID for AKS RBAC.')
param aksAdminsGroupId string

@description('Istio revision to install (e.g., asm-1-27).')
param istioRevision string = 'asm-1-27'

@description('Enable Istio internal ingress gateway.')
param enableIstioInternalIngress bool = true

@description('Enable Istio external ingress gateway.')
param enableIstioExternalIngress bool = false

// ===================== //
// Resource Group        //
// ===================== //

module rg 'br/public:avm/res/resources/resource-group:0.4.3' = {
  name: rgName
  params: {
    name: rgName
    location: location
  }
}

// ===================== //
// Networking            //
// ===================== //

module nsgAks 'br/public:avm/res/network/network-security-group:0.5.2' = {
  scope: resourceGroup(rg.name)
  name: 'nsg-aks-istio'
  params: {
    name: 'nsg-aks-istio'
    location: location
  }
}

module vnet 'br/public:avm/res/network/virtual-network:0.7.2' = {
  scope: resourceGroup(rg.name)
  name: vnetName
  params: {
    name: vnetName
    location: location
    addressPrefixes: vnetAddressPrefixes
    subnets: [
      {
        name: 'aks-subnet'
        addressPrefix: aksSubnetPrefix
        networkSecurityGroupResourceId: nsgAks.outputs.resourceId
      }
    ]
  }
}

// ===================== //
// Log Analytics         //
// ===================== //

module workspace 'br/public:avm/res/operational-insights/workspace:0.15.0' = {
  scope: resourceGroup(rg.name)
  name: 'istio-la-workspace'
  params: {
    name: 'istio-la-workspace'
    location: location
  }
}

// ===================== //
// AKS with Istio        //
// ===================== //

var istioIngressGateways = concat(
  enableIstioInternalIngress
    ? [
        {
          enabled: true
          mode: 'Internal'
        }
      ]
    : [],
  enableIstioExternalIngress
    ? [
        {
          enabled: true
          mode: 'External'
        }
      ]
    : []
)

module aksCluster 'br/public:avm/res/container-service/managed-cluster:0.12.0' = {
  scope: resourceGroup(rg.name)
  name: aksClusterName
  params: {
    name: aksClusterName
    location: location
    skuName: 'Base'
    skuTier: 'Standard'
    kubernetesVersion: kubernetesVersion
    aadProfile: {
      enableAzureRBAC: true
      managed: true
      adminGroupObjectIDs: [
        aksAdminsGroupId
      ]
    }
    enableRBAC: true
    disableLocalAccounts: true
    enableOidcIssuerProfile: true
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
    }
    networkPlugin: 'azure'
    networkDataplane: 'cilium'
    primaryAgentPoolProfiles: [
      {
        name: 'systempool'
        count: 3
        enableAutoScaling: true
        minCount: 2
        maxCount: 5
        vmSize: vmSize
        mode: 'System'
        osType: 'Linux'
        vnetSubnetResourceId: vnet.outputs.subnetResourceIds[0]
      }
    ]
    // Istio Service Mesh add-on
    serviceMeshProfile: {
      mode: 'Istio'
      istio: {
        revisions: [
          istioRevision
        ]
        components: {
          ingressGateways: istioIngressGateways
        }
      }
    }
    // Monitoring
    omsAgentEnabled: true
    monitoringWorkspaceResourceId: workspace.outputs.resourceId
    azurePolicyEnabled: true
    // CSI drivers
    enableKeyvaultSecretsProvider: true
    enableSecretRotation: true
    // Web app routing (disabled - Istio handles ingress)
    webApplicationRoutingEnabled: false
    managedIdentities: {
      systemAssigned: true
    }
  }
}

// ===================== //
// Outputs               //
// ===================== //

@description('AKS cluster name.')
output aksClusterName string = aksCluster.outputs.name

@description('AKS cluster resource group.')
output aksResourceGroup string = rg.name

@description('OIDC issuer URL for workload identity.')
output oidcIssuerUrl string = aksCluster.outputs.?oidcIssuerUrl ?? ''

@description('Log Analytics workspace resource ID.')
output workspaceResourceId string = workspace.outputs.resourceId
