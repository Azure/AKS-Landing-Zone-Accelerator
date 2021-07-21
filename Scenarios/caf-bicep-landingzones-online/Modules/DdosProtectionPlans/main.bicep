param DdosProtectionPlan object = {}

resource Ddos 'Microsoft.Network/ddosProtectionPlans@2019-09-01' = {
  name: DdosProtectionPlan.name
  location: resourceGroup().location
  tags: {}
  properties: {}
}
