module "networkHub" {
  source = "../03-Network-Hub/"

  location           = var.location
  rgHubName          = var.rgHubName
  nsgHubDefaultName  = var.nsgHubDefaultName
  nsgVMName          = var.nsgVMName
  hubVNETaddPrefixes = var.hubVNETaddPrefixes
  snetDefaultAddr    = var.snetHubDefaultAddr
  snetFirewallAddr   = var.snetFirewallAddr
  snetBastionAddr    = var.snetBastionAddr
  snetVMAddr         = var.snetVMAddr
  routeAddr          = var.routeAddr
  vnetHubName        = var.vnetHubName
  availabilityZones  = var.availabilityZones
  rtHubName          = var.rtHubName
}

module "networkLZ" {
  source = "../04-Network-LZ/"

  location             = var.location
  rgLzName             = var.rgLzName
  rgHubName            = module.networkHub.rgHubName
  vnetHubName          = module.networkHub.vnetHubName
  vnetLzName           = var.vnetLzName
  rtLzName             = var.rtLzName
  nsgLzDefaultName     = var.nsgLzDefaultName
  nsgAppGWName         = var.nsgAppGWName
  spokeVNETaddPrefixes = var.spokeVNETaddPrefixes
  snetDefaultAddr      = var.snetSpokeDefaultAddr
  snetAksAddr          = var.snetAksAddr
  snetAppGWAddr        = var.snetAppGWAddr

  deployingAllInOne = true
  vnetHubId         = module.networkHub.vnetHubId
  firewallPrivateIp = module.networkHub.firewallPrivateIp
}

module "aksSupporting" {
  source = "../05-AKS-Supporting/"

  location    = var.location
  rgLzName    = module.networkLZ.rgLzName
  vnetLzName  = module.networkLZ.vnetLzName
  rgHubName   = module.networkHub.rgHubName
  vnetHubName = module.networkHub.vnetHubName
  acrName     = var.acrName
  akvName     = var.akvName

  deployingAllInOne = true
  speSubnetId       = module.networkLZ.speSubnetId
  dnszoneAkvId      = module.networkLZ.dnszoneAkvId
  dnszoneAcrId      = module.networkLZ.dnszoneAcrId
}

module "aksCluster" {
  source = "../06-AKS-Cluster/"

  location            = var.location
  rgLzName            = module.networkLZ.rgLzName
  vnetLzName          = module.networkLZ.vnetLzName
  rgHubName           = module.networkHub.rgHubName
  vnetHubName         = module.networkHub.vnetHubName
  acrName             = module.aksSupporting.acrName
  akvName             = module.aksSupporting.akvName
  adminGroupObjectIds = var.adminGroupObjectIds

  deployingAllInOne = true
  vnetLzId          = module.networkLZ.vnetLzId
  snetAksId         = module.networkLZ.snetAksId
  dnszoneAksId      = module.networkLZ.dnszoneAksId
  dnszoneContosoId  = module.networkLZ.dnszoneContosoId
  acrId             = module.aksSupporting.acrId
  akvId             = module.aksSupporting.akvId
}

# module "aksBackup" {
#   source = "../AKS-Backup/"

#   location            = var.location
#   # rgLzName            = module.networkLZ.rgLzName
#   # vnetLzName          = module.networkLZ.vnetLzName
#   # rgHubName           = module.networkHub.rgHubName
#   # vnetHubName         = module.networkHub.vnetHubName
#   # acrName             = module.aksSupporting.acrName
#   # akvName             = module.aksSupporting.akvName
#   # adminGroupObjectIds = var.adminGroupObjectIds

#   # deployingAllInOne = true
#   # vnetLzId          = module.networkLZ.vnetLzId
#   # snetAksId         = module.networkLZ.snetAksId
#   # dnszoneAksId      = module.networkLZ.dnszoneAksId
#   # dnszoneContosoId  = module.networkLZ.dnszoneContosoId
#   # acrId             = module.aksSupporting.acrId
#   # akvId             = module.aksSupporting.akvId
#   # aksClusterId      = module.aksCluster.aksClusterId
# }
