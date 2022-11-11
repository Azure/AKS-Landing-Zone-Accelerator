resource managedCluster_resource 'Microsoft.ContainerService/managedClusters@2022-06-02-preview' = {
  name: 'demo-aks'
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
    dnsPrefix: '${managedClusters_name}-dns'
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
    nodeResourceGroup: 'MC_${managedClusters_name}_${location}'
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
