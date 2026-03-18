targetScope = 'subscription'

@description('The name of the resource group for AKS supporting resources.')
param rgName string

@description('The name of the spoke virtual network.')
param vnetName string

@description('The name of the subnet for private endpoints.')
param subnetName string

@description('The private DNS zone name for Azure Container Registry.')
param privateDNSZoneACRName string = 'privatelink${environment().suffixes.acrLoginServer}'

@description('The private DNS zone name for Azure Key Vault.')
param privateDNSZoneKVName string = 'privatelink.vaultcore.azure.net'

@description('The private DNS zone name for Azure Storage.')
param privateDNSZoneSAName string = 'privatelink.file.${environment().suffixes.storage}'

@description('The name of the Azure Container Registry.')
param acrName string = 'eslzacr${uniqueString('acrvws', uniqueString(subscription().id, utcNow()))}'

@description('The name of the Azure Key Vault.')
param keyvaultName string = 'eslz-kv-${uniqueString('acrvws', uniqueString(subscription().id, utcNow()))}'

@description('The name of the storage account.')
param storageAccountName string = 'eslzsa${uniqueString('aks', uniqueString(subscription().id), utcNow())}'

@description('The storage account SKU type.')
param storageAccountType string

@description('Enable etcd encryption with KMS v2 using a Key Vault key.')
param enableKmsEncryption bool = true

@description('The Azure region for all resources.')
param location string = deployment().location

resource servicesSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  scope: resourceGroup(rg.name)
  name: '${vnetName}/${subnetName}'
}

resource privateDNSZoneSA 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  scope: resourceGroup(rg.name)
  name: privateDNSZoneSAName
}

resource privateDNSZoneKV 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  scope: resourceGroup(rg.name)
  name: privateDNSZoneKVName
}

resource privateDNSZoneACR 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  scope: resourceGroup(rg.name)
  name: privateDNSZoneACRName
}

module rg 'br/public:avm/res/resources/resource-group:0.4.3' = {
  name: rgName
  params: {
    name: rgName
    location: location
    enableTelemetry: true
  }
}

module registry 'br/public:avm/res/container-registry/registry:0.11.0' = {
  scope: resourceGroup(rg.name)
  name: acrName
  params: {
    name: acrName
    location: location
    acrAdminUserEnabled: true
    publicNetworkAccess: 'Disabled'
    acrSku: 'Premium'
    privateEndpoints: [
      {
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: privateDNSZoneACR.id
            }
          ]
        }
        subnetResourceId: servicesSubnet.id
      }
    ]
  }
}

module vault 'br/public:avm/res/key-vault/vault:0.13.3' = {
  scope: resourceGroup(rg.name)
  name: keyvaultName
  params: {
    name: keyvaultName
    enablePurgeProtection: true
    location: location
    sku: 'standard'
    enableVaultForDiskEncryption: true
    enableRbacAuthorization: true
    softDeleteRetentionInDays: 7
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    keys: enableKmsEncryption
      ? [
          {
            name: 'aks-etcd-kms'
            kty: 'RSA'
            keySize: 2048
          }
        ]
      : []
    privateEndpoints: [
      {
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: privateDNSZoneKV.id
            }
          ]
        }
        subnetResourceId: servicesSubnet.id
      }
    ]
  }
}

module storageAccount 'br/public:avm/res/storage/storage-account:0.32.0' = {
  scope: resourceGroup(rg.name)
  name: storageAccountName
  params: {
    name: storageAccountName
    allowBlobPublicAccess: false
    location: location
    skuName: storageAccountType
    kind: 'StorageV2'
    privateEndpoints: [
      {
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: privateDNSZoneSA.id
            }
          ]
        }
        service: 'file'
        subnetResourceId: servicesSubnet.id
      }
    ]
  }
}

@description('The name of the Azure Container Registry.')
output acrName string = registry.outputs.name

@description('The name of the Azure Key Vault.')
output keyVaultName string = vault.outputs.name

@description('The resource ID of the Azure Key Vault.')
output keyVaultResourceId string = vault.outputs.resourceId

@description('The URI of the KMS encryption key (empty if KMS not enabled).')
output kmsKeyUri string = enableKmsEncryption ? '${vault.outputs.uri}keys/aks-etcd-kms' : ''
