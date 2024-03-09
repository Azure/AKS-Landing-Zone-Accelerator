targetScope = 'subscription'

//  Telemetry Deployment
@description('Enable usage and telemetry feedback to Microsoft.')

param enableTelemetry bool = true
param location string

var telemetryId = 'a4c036ff-1c94-4378-862a-8e090a88da82-${location}'

resource telemetrydeployment 'Microsoft.Resources/deployments@2021-04-01' = if (enableTelemetry) {
  name: telemetryId
  location: location
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#'
      contentVersion: '1.0.0.0'
      resources: {}
    }
  }
}

