param subnetId string
param vmSize string
param vmName string = 'runner'
param publisher string = 'Canonical'
param offer string = 'UbuntuServer'
param sku string = '18.04-LTS'
param location string = resourceGroup().location
param adminUsername string
@secure()
param adminPassword string
@secure()
param ghtoken string

module jbnic '../vnet/nic.bicep' = {
  name: 'jbnic'
  params: {
    location: location
    subnetId: subnetId
    nicName: 'runnerNic'
  }
}

resource jumpbox 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: vmName 
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    osProfile: {
      computerName: vmName 
      adminUsername: adminUsername
      adminPassword: adminPassword
      customData: base64(replace(loadTextContent('cloud-init.yml'), '_GITHUB_TOKEN_', ghtoken))
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      imageReference: {
        publisher: publisher
        offer: offer
        sku: sku
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: jbnic.outputs.nicId
        }
      ]
    }
  }
}
