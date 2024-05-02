param appgwname string
param rgName string
param subnetid string
param appgwpip string
param location string = resourceGroup().location
param appGwyAutoScale object
var frontendPortName = 'HTTP-80'
var frontendIPConfigurationName = 'appGatewayFrontendIP'
var httplistenerName = 'httplistener'
var backendAddressPoolName = 'backend-add-pool'
var backendHttpSettingsCollectionName = 'backend-http-settings'
param availabilityZones array

resource appgw 'Microsoft.Network/applicationGateways@2021-02-01' = {
  name: appgwname
  location: location
  zones: !empty(availabilityZones) ? availabilityZones : null
  properties: {
    autoscaleConfiguration: !empty(appGwyAutoScale) ? appGwyAutoScale : null
    sku: {
      tier: 'Standard_v2'
      name: 'Standard_v2'
       capacity: empty(appGwyAutoScale) ? 2 : null
    }
    gatewayIPConfigurations: [
      {
        name: 'appgw-ip-configuration'
        properties: {
          subnet: {
            id: subnetid
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: frontendIPConfigurationName
        properties: {
          publicIPAddress: {
            id: appgwpip
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: frontendPortName
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: backendAddressPoolName
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: backendHttpSettingsCollectionName
        properties: {
          cookieBasedAffinity: 'Disabled'
          path: '/'
          port: 80
          protocol: 'Http'
          requestTimeout: 60
        }
      }
    ]
    httpListeners: [
      {
        name: httplistenerName
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appgwname, frontendIPConfigurationName)
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appgwname, frontendPortName)
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'rule1'
        properties:{
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appgwname, httplistenerName)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appgwname, backendAddressPoolName)
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appgwname, backendHttpSettingsCollectionName)
          }
        }
      }
    ]
  }
}
