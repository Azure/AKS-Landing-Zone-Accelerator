module "networkHub" {
  source = "../03-Network-Hub/"

  location           = var.location
  rgHubName          = var.rgHubName
  nsgDefaultName     = var.nsgDefaultName
  nsgVMName          = var.nsgVMName
  hubVNETaddPrefixes = var.hubVNETaddPrefixes
  snetDefaultAddr    = var.snetDefaultAddr
  snetFirewallAddr   = var.snetFirewallAddr
  snetBastionAddr    = var.snetBastionAddr
  snetVMAddr         = var.snetVMAddr
  routeAddr          = var.routeAddr
  vnetHubName        = var.vnetHubName
  availabilityZones  = var.availabilityZones
  rtName             = var.rtName
}

module "networkLZ" {
  source = "../04-Network-LZ/"

  location             = var.location
  rgLzName             = var.rgLzName
  rgHubName            = var.rgHubName
  vnetHubName          = module.networkHub.vnetHubName # var.vnetHubName
  vnetLzName           = var.vnetLzName
  rtName               = var.rtName
  nsgDefaultName       = var.nsgDefaultName
  nsgAppGWName         = var.nsgAppGWName
  spokeVNETaddPrefixes = var.spokeVNETaddPrefixes
  snetDefaultAddr      = var.snetDefaultAddr
  snetAksAddr          = var.snetAksAddr
  snetAppGWAddr        = var.snetAppGWAddr

  # depends_on = [module.networkHub]
}
