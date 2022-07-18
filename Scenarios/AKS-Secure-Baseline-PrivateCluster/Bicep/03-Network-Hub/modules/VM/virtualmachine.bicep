param subnetId string
param publicKey string
param vmSize string
param location string = resourceGroup().location
param adminUsername string = 'azureuser'
//param script64 string

module jbnic '../vnet/nic.bicep' = {
  name: 'jbnic'
  params: {
    location: location
    subnetId: subnetId
  }
}

resource jumpbox 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: 'jumpbox'
  location: location
  properties: {
    osProfile: {
      computerName: 'jumpbox'
      adminUsername: adminUsername
      adminPassword: 'Password123'
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
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

// resource vmext 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
//   name: '${jumpbox.name}/csscript'
//   location: resourceGroup().location
//   properties: {
//     publisher: 'Microsoft.Azure.Extensions'
//     type: 'CustomScript'
//     typeHandlerVersion: '2.1'
//     autoUpgradeMinorVersion: true
//     settings: {}
//     protectedSettings: {
//       script: script64
//     }
//   }
// }
