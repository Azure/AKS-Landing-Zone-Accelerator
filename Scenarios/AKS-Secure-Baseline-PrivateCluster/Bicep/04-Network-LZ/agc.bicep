@description('The name of the Application Gateway for Containers traffic controller.')
param agcName string

@description('The location for the AGC resources.')
param location string

@description('The resource ID of the delegated subnet for the AGC association.')
param agcSubnetId string

resource trafficController 'Microsoft.ServiceNetworking/trafficControllers@2025-01-01' = {
  name: agcName
  location: location
  properties: {}
}

resource agcAssociation 'Microsoft.ServiceNetworking/trafficControllers/associations@2025-01-01' = {
  parent: trafficController
  name: '${agcName}-association'
  location: location
  properties: {
    associationType: 'subnets'
    subnet: {
      id: agcSubnetId
    }
  }
}

@description('The resource ID of the Application Gateway for Containers traffic controller.')
output agcResourceId string = trafficController.id
