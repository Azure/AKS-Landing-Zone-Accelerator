param networkSecurityGroup object = {}

resource nsgDeploy 'Microsoft.Network/networkSecurityGroups@2020-07-01' = {
  name: networkSecurityGroup.name
  location: resourceGroup().location
  tags: {}
  properties: {
  }
}
