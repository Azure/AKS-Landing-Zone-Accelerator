// Parameters
@description('The name of the Front Door profile to create. This must be globally unique.')
param frontDoorName string = 'afd-aks-lza-${uniqueString(resourceGroup().id)}'

@description('The location into which regionally scoped resources should be deployed. Note that Front Door is a global resource.')
param location string = resourceGroup().location

@description('The name of the Front Door endpoint to create. This must be globally unique.')
param frontDoorEndpointName string = 'afd-${uniqueString(resourceGroup().id)}'

@description('The name of the SKU to use when creating the Front Door profile.')
@allowed([
  'Standard_AzureFrontDoor'
  'Premium_AzureFrontDoor'
])
param frontDoorSkuName string = 'Standard_AzureFrontDoor'

//var frontDoorProfileName = 'MyFrontDoor'
var frontDoorOriginGroupName = 'MyOriginGroup'
var frontDoorOriginName = 'MyAppServiceOrigin'
var frontDoorRouteName = 'MyRoute'


// Azure Front Door (Standard/Premium)
resource frontDoorProfile 'Microsoft.Cdn/profiles@2021-06-01' = {
  name: frontDoorName
  location: 'Global'
  sku: {
    name: frontDoorSkuName // Change to 'Premium_AzureFrontDoor' if needed
  }
}


resource frontDoorEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2021-06-01' = {
  name: frontDoorEndpointName
  parent: frontDoorProfile
  location: 'global'
  properties: {
    enabledState: 'Enabled'
  }
}


resource frontDoorOriginGroup 'Microsoft.Cdn/profiles/originGroups@2021-06-01' = {
  name: frontDoorOriginGroupName
  parent: frontDoorProfile
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Http'
      probeIntervalInSeconds: 100
    }
  }
}

// resource frontDoorOrigin 'Microsoft.Cdn/profiles/originGroups/origins@2021-06-01' = {
//   name: frontDoorOriginName
//   parent: frontDoorOriginGroup
//   properties: {
//     hostName: app.properties.defaultHostName
//     httpPort: 80
//     httpsPort: 443
//     originHostHeader: app.properties.defaultHostName
//     priority: 1
//     weight: 1000
//   }
// }

// resource frontDoorRoute 'Microsoft.Cdn/profiles/afdEndpoints/routes@2021-06-01' = {
//   name: frontDoorRouteName
//   parent: frontDoorEndpoint
//   dependsOn: [
//     frontDoorOrigin // This explicit dependency is required to ensure that the origin group is not empty when the route is created.
//   ]
//   properties: {
//     originGroup: {
//       id: frontDoorOriginGroup.id
//     }
//     supportedProtocols: [
//       'Http'
//       'Https'
//     ]
//     patternsToMatch: [
//       '/*'
//     ]
//     forwardingProtocol: 'HttpsOnly'
//     linkToDefaultDomain: 'Enabled'
//     httpsRedirect: 'Enabled'
//   }
// }

// Output the front door ID for reference
output frontDoorId string = frontDoorProfile.id
