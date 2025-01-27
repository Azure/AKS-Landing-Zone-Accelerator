// Parameters
param location string
param frontDoorName string

// Azure Front Door (Standard/Premium)
resource frontDoor 'Microsoft.Cdn/profiles@2021-06-01' = {
  name: frontDoorName
  location: location
  sku: {
    name: 'Standard_AzureFrontDoor' // Change to 'Premium_AzureFrontDoor' if needed
  }
  properties: {
    enabledState: 'Enabled'
    resourceState: 'Active'
  }
}

// Output the front door ID for reference
output frontDoorId string = frontDoor.id
