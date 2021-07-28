param networkSecurityGroup object = {}
param trafficAnalytics object = {}

resource symbolicname 'Microsoft.Network/networkWatchers/flowLogs@2020-07-01' = {
  name: '${networkSecurityGroup}-flowlog'
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
        workspaceId: trafficAnalytics.LAWorkspaceId
        workspaceRegion: resourceGroup().location
        workspaceResourceId: trafficAnalytics.LAWorkspaceId
        trafficAnalyticsInterval: 10
      }
    }
  }
}
