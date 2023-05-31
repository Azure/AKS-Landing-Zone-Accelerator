targetScope = 'subscription'

// Parameters
@description('Optional. Azure location to which the resources are to be deployed -defaults to the location of the current deployment')
param location string = deployment().location

@description('Required. A short name for the workload where Azure Cache for Redis Enteprise will be used')
param workloadName string

@description('Required. The environment for which the deployment is being executed')
@allowed([
  'dev'
  'uat'
  'prod'
  'dr'
])
param environment string

@description('Optional. A numeric suffix (e.g. "001") to be appended on the naming generated for the resources. Defaults to empty.')
param numericSuffix string = ''

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

@description('Required. The subnet id used for Azure Cache for Redis Enterprise private endpoint.')
param redisPrivateEndpointSubnetId string

@description('Required, The name of the resource group where Azure Cache for Redis Enterprise will be deployed.')
param resourceGroupName string 

@description('Required. Name of the key vault used to store Azure Cache for Redis Enterprise hostname and password')
param keyVaultName string

// Variables

var defaultTags = union({
  application: workloadName
  environment: environment
}, tags)

var defaultSuffixes = [
  workloadName
  environment
  '**location**'
]

var namingSuffixes = empty(numericSuffix) ? defaultSuffixes : concat(defaultSuffixes, [
  numericSuffix
])

module naming 'modules/naming.module.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'namingModule-Deployment'
  params: {
    location: location
    suffix: namingSuffixes
    uniqueLength: 6
  }
}

//Create Redis resource
module redis 'redis.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'redis-Deployment'
  params: {
    location: location
    redisPrivateEndpointSubnetId: redisPrivateEndpointSubnetId
    naming: naming.outputs.names
    tags: defaultTags
    keyVaultName: keyVaultName
  }
}

output redisHostName string = redis.outputs.redisHostName
