@description('Required. Name of the Private DNS Zone.')
param name string

@description('Optional. The tags to be assigned the created resources.')
param tags object = {}

@description('Required. Prefix used for the name of deployment')
param prefix string

var deploymentNames = {
  dnsZoneGroupDeploymentName:  '${prefix}DnsZoneGroup-Deployment'
}
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: name
  location: 'Global'
  tags: tags  
}

module privateDnsZoneGroup 'privateDnsZoneGroup.module.bicep' = {
  name: deploymentNames.dnsZoneGroupDeploymentName
  params: {
     privateDnsZoneName: privateDnsZone.name
     privateDnsZoneResourceId: privateDnsZone.id
  }
}

output id string = privateDnsZone.id
