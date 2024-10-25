module "networkHub" {
  source = "../03-Network-Hub/"

  location           = var.location
  rgHubName          = var.rgHubName
  nsgHubDefaultName  = var.nsgHubDefaultName
  nsgVMName          = var.nsgVMName
  hubVNETaddPrefixes = var.hubVNETaddPrefixes
  snetDefaultAddr    = var.snetDefaultAddr
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
  rgHubName            = module.networkHub.rgHubName   # var.rgHubName
  vnetHubName          = module.networkHub.vnetHubName # var.vnetHubName
  vnetLzName           = var.vnetLzName
  rtLzName             = var.rtLzName
  nsgLzDefaultName     = var.nsgLzDefaultName
  nsgAppGWName         = var.nsgAppGWName
  spokeVNETaddPrefixes = var.spokeVNETaddPrefixes
  snetDefaultAddr      = var.snetDefaultAddr
  snetAksAddr          = var.snetAksAddr
  snetAppGWAddr        = var.snetAppGWAddr

  # depends_on = [module.networkHub]
}
