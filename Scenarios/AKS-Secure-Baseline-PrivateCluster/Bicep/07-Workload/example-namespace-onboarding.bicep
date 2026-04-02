targetScope = 'subscription'

// ============================================================ //
// Example: Using the namespace building block in Secure Baseline
// ============================================================ //
// This demonstrates how to onboard multiple team namespaces
// onto an existing AKS cluster using the reusable module.

@description('Resource group name containing the AKS cluster.')
param rgName string = 'ESLZ-SPOKE-RG'

@description('Name of the existing AKS cluster.')
param aksClusterName string = 'aksCluster'

@description('Git repository URL containing namespace manifests.')
param gitRepositoryUrl string = 'https://github.com/<org>/platform-config'

@description('Git branch.')
param gitBranch string = 'main'

// Define namespaces to provision
var namespaces = [
  {
    name: 'team-orders'
    path: './namespaces/team-orders'
  }
  {
    name: 'team-inventory'
    path: './namespaces/team-inventory'
  }
  {
    name: 'team-frontend'
    path: './namespaces/team-frontend'
  }
]

// Deploy the building block for each namespace.
// The first one installs Flux; subsequent ones reuse it.
module namespaceConfig '../07-Workload/namespace-building-block.bicep' = [
  for (ns, index) in namespaces: {
    scope: resourceGroup(rgName)
    name: 'ns-${ns.name}'
    params: {
      aksClusterName: aksClusterName
      namespaceName: ns.name
      gitRepositoryUrl: gitRepositoryUrl
      gitBranch: gitBranch
      gitPath: ns.path
      installFluxExtension: index == 0 // Only install Flux once
    }
  }
]
