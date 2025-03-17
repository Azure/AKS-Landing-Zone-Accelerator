param subnetName string = 'servicespe'
param privateDNSZoneACRName string = 'privatelink${environment().suffixes.acrLoginServer}'
param acrName string = 'eslzacr${uniqueString('acrvws', uniqueString(subscription().id, utcNow()))}'
param vnetSpokeName string = 'VNet-SPOKE'
param spokeResourceGroupMainRegion string 
param spokeResourceGroupSecondaryRegion string


resource privateDNSZoneACR 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  scope: resourceGroup(spokeResourceGroupMainRegion)
  name: privateDNSZoneACRName
}

resource privateDNSZoneSecondaryACR 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  scope: resourceGroup(spokeResourceGroupSecondaryRegion)
  name: privateDNSZoneACRName
}
resource servicesSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  scope: resourceGroup(spokeResourceGroupMainRegion)
  name: '${vnetSpokeName}/${subnetName}'
}

resource servicesSecondarySubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  scope: resourceGroup(spokeResourceGroupSecondaryRegion)
  name: '${vnetSpokeName}/${subnetName}'
}
// Global Container Registry
module containerRegistry 'br/public:avm/res/container-registry/registry:0.1.1' = {
  scope: resourceGroup(resourceGroup().name)
  name: acrName
  params: {
    name: acrName
    location: resourceGroup().location
    acrAdminUserEnabled: true
    publicNetworkAccess: 'Disabled'
    acrSku: 'Premium'
    privateEndpoints: [
      {
        privateDnsZoneResourceIds: [
          privateDNSZoneACR.id
        ]
        subnetResourceId: servicesSubnet.id
      }
      {
        privateDnsZoneResourceIds: [
          privateDNSZoneSecondaryACR.id
        ]
        subnetResourceId: servicesSecondarySubnet.id
      }
    ]
  }
}



// Output the container registry ID for reference
output containerRegistryId string = containerRegistry.outputs.name
