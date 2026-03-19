using 'main.bicep'

param rgName = 'rg-spoke'

param enableAutoScaling = true

param autoScalingProfile = {
  balanceSimilarNodeGroups: false
  expander: 'random'
  maxEmptyBulkDelete: 10
  maxGracefulTerminationSec: 600
  maxNodeProvisionTime: '15m'
  maxTotalUnreadyPercentage: 45
  newPodScaleUpDelay: '0s'
  okTotalUnreadyCount: 3
  scaleDownDelayAfterAdd: '10m'
  scaleDownDelayAfterDelete: '10s'
  scaleDownDelayAfterFailure: '3m'
  scaleDownUnneededTime: '10m'
  scaleDownUnreadyTime: '20m'
  scaleDownUtilizationThreshold: '0.5'
  scanInterval: '10s'
  skipNodesWithLocalStorage: false
  skipNodesWithSystemPods: true
}

param vnetName = 'vnet-spoke'

param subnetName = 'AKS'

param aksIdentityName = 'id-aks'

param aksClusterName = 'aks-cluster'

param aksAdminAccessPrincipalId = '<REPLACE_WITH_ENTRA_ID_GROUP_OBJECT_ID>'

param kubernetesVersion = '1.33'

param keyVaultName = '<REPLACE_WITH_KEYVAULT_NAME>'

param acrName = '<REPLACE_WITH_ACR_NAME>'

param networkPlugin = 'azure'

param enablePrivateCluster = true

param vmSize = 'Standard_D4d_v5'

param aksSkuName = 'Base'
