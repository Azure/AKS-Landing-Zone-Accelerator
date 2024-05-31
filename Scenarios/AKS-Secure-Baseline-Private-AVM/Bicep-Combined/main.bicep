targetScope = 'subscription'

param hubRgName string = ''
param vnetHubName string = ''
param hubVNETaddPrefixes array = []
param azfwName string = ''
param rtVMSubnetName string = 'dwdw'
param fwapplicationRuleCollections array = []
param fwnetworkRuleCollections array = []
param fwnatRuleCollections array  =[]
param location string = deployment().location
param availabilityZones array  = []

module network_hub '../Bicep/03-Network-Hub/main.bicep' = {
 name: 'network_hub'
 params:{
  rgName:hubRgName
  azfwName:azfwName
  fwapplicationRuleCollections:fwapplicationRuleCollections
  fwnatRuleCollections:fwnatRuleCollections
  fwnetworkRuleCollections:fwnetworkRuleCollections
  hubVNETaddPrefixes:hubVNETaddPrefixes
  vnetHubName:vnetHubName
  rtVMSubnetName:rtVMSubnetName
  availabilityZones:availabilityZones
  location:location
}
}

param spokeRgName string =''
param vnetSpokeName string =''
param spokeVNETaddPrefixes array =[]
param rtAKSSubnetName string =''
param firewallIP string =''
param appGatewayName string =''
param vnetHUBRGName string =''
param nsgAKSName string =''
param nsgAppGWName string =''
param rtAppGWSubnetName string =''
param dnsServers array =[]
param appGwyAutoScale object ={}
param securityRules array = []



module network_lz '../Bicep/04-Network-LZ/main.bicep' = {
  name: 'network_lz'
  params:{
   rgName:spokeRgName
   availabilityZones:availabilityZones
   location:location
   appGatewayName:appGatewayName
   appGwyAutoScale:appGwyAutoScale
   firewallIP:firewallIP
   dnsServers:dnsServers
   nsgAKSName:nsgAKSName
   nsgAppGWName:nsgAppGWName
   rtAKSSubnetName:rtAKSSubnetName
   rtAppGWSubnetName:rtAppGWSubnetName
   spokeVNETaddPrefixes:spokeVNETaddPrefixes
   vnetHubName:vnetHubName
   vnetHUBRGName:vnetHUBRGName
   vnetSpokeName:vnetSpokeName
 }
 dependsOn:[network_hub]
 }

param appgwname string =''
param subnetid string =''
param appgwpip string =''
var frontendPortName = 'HTTP-80'
var frontendIPConfigurationName = 'appGatewayFrontendIP'
var httplistenerName = 'httplistener'
var backendAddressPoolName = 'backend-add-pool'
var backendHttpSettingsCollectionName = 'backend-http-settings'


 module network_lz_appgw '../Bicep/04-Network-LZ/appgw.bicep' = {
  name:'network_lz_appgw'
  scope:resourceGroup(spokeRgName)
  params:{
    location:location
    appgwname:appGatewayName
    appgwpip:appgwpip
    appGwyAutoScale:appGwyAutoScale
    availabilityZones:availabilityZones
    rgName:spokeRgName
    subnetid:subnetid
  }
  dependsOn:[network_hub,network_lz]
 }
 
param vnetName string =''
param subnetName string =''
param privateDNSZoneACRName string = 'privatelink${environment().suffixes.acrLoginServer}'
param privateDNSZoneKVName string = 'privatelink.vaultcore.azure.net'
param privateDNSZoneSAName string = 'privatelink.file.${environment().suffixes.storage}'
param acrName string = 'eslzacr${uniqueString('acrvws', utcNow('u'))}'
param keyvaultName string = 'eslz-kv-${uniqueString('acrvws', utcNow('u'))}'
param storageAccountName string = 'eslzsa${uniqueString('aks', utcNow('u'))}'
param storageAccountType string =''

module aks_supporting '../Bicep/05-AKS-Supporting/main.bicep' = {
  name:'aks_supporting'
  params:{
    storageAccountType:storageAccountType
    subnetName:subnetName
    vnetName:vnetName
    rgName:spokeRgName
  }
  dependsOn:[network_hub,network_lz]
 }


param aksIdentityName string =''
param enableAutoScaling bool = false
param autoScalingProfile object ={}
param aksadminaccessprincipalId string =''
 
 @allowed([
   'azure'
   'kubenet'
 ])
 param networkPlugin string = 'azure'
 
 module aks_cluster '../Bicep/06-AKS-Cluster/main.bicep' = {
  name:'aks_cluster'
  params:{
    aksadminaccessprincipalId:aksadminaccessprincipalId
    aksIdentityName:aksIdentityName
    appGatewayName:appGatewayName
    autoScalingProfile:autoScalingProfile
    enableAutoScaling:enableAutoScaling
    subnetName:subnetName
    vnetName:vnetName
    rgName:spokeRgName
  }
  dependsOn:[network_hub,network_lz,aks_supporting]
 }
