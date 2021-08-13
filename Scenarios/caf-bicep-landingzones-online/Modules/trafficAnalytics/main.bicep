param networkSecurityGroup object = {}
param trafficAnalytics object = {}

resource NSGFlowLogs 'Microsoft.Network/networkWatchers/flowLogs@2020-07-01' = {
  name: '${trafficAnalytics.name}/${networkSecurityGroup.name}-flowlog'
  location: resourceGroup().location
  tags: {}
  properties: {
    targetResourceId: networkSecurityGroup.id
    storageId: trafficAnalytics.storageAccountId
    enabled: true
    retentionPolicy: {
      days: 30
      enabled: true
    }
    flowAnalyticsConfiguration: {
      networkWatcherFlowAnalyticsConfiguration: {
        enabled: true
        workspaceRegion: resourceGroup().location
        workspaceResourceId: trafficAnalytics.LAWorkspaceId
        trafficAnalyticsInterval: 10
      }
    }
  }
}
