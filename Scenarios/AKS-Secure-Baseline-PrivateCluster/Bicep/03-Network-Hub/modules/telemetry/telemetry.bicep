@description('Enable usage and telemetry feedback to Microsoft.')

param enableTelemetry bool = true
param location string = deployment().location

var telemetryId = '0d807b2d-f7c3-4710-9a65-e88257df1ea0-${location}'

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
