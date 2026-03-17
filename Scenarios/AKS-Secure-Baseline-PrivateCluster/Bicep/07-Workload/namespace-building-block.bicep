targetScope = 'resourceGroup'

// =============================== //
// Namespace Building Block Module //
// =============================== //
// This reusable module provisions a fully configured Kubernetes namespace via GitOps.
// It installs the Flux extension on an AKS cluster and creates a FluxConfiguration
// that reconciles namespace manifests (Namespace, RBAC, Ingress) from a Git repository.

@description('Required. The name of the AKS cluster to configure.')
param aksClusterName string

@description('Optional. Location for resources.')
param location string = resourceGroup().location

@description('Required. The name of the Kubernetes namespace to provision.')
param namespaceName string

@description('Required. The Git repository URL containing namespace manifests.')
param gitRepositoryUrl string

@description('Optional. The Git branch to reconcile from.')
param gitBranch string = 'main'

@description('Optional. The path within the Git repository containing the namespace manifests.')
param gitPath string = './namespaces/${namespaceName}'

@description('Optional. Sync interval for GitOps reconciliation in seconds.')
param syncIntervalInSeconds int = 300

@description('Optional. Whether to install the Flux extension (set to false if already installed on the cluster).')
param installFluxExtension bool = true

@description('Optional. Whether to prune resources that are removed from the Git source.')
param enablePrune bool = true

// ===================== //
// Flux Extension        //
// ===================== //

module fluxExtension 'br/public:avm/res/kubernetes-configuration/extension:0.3.8' = if (installFluxExtension) {
  name: 'flux-extension-${uniqueString(aksClusterName)}'
  params: {
    name: 'flux'
    clusterName: aksClusterName
    extensionType: 'microsoft.flux'
    releaseNamespace: 'flux-system'
    releaseTrain: 'Stable'
    location: location
  }
}

// ===================== //
// Flux Configuration    //
// ===================== //

module fluxConfig 'br/public:avm/res/kubernetes-configuration/flux-configuration:0.3.8' = {
  name: 'flux-ns-${namespaceName}-${uniqueString(aksClusterName)}'
  params: {
    name: 'ns-${namespaceName}'
    clusterName: aksClusterName
    namespace: namespaceName
    scope: 'cluster'
    sourceKind: 'GitRepository'
    gitRepository: {
      url: gitRepositoryUrl
      timeoutInSeconds: 180
      syncIntervalInSeconds: syncIntervalInSeconds
      repositoryRef: {
        branch: gitBranch
      }
    }
    kustomizations: {
      'namespace-config': {
        path: gitPath
        timeoutInSeconds: 300
        syncIntervalInSeconds: syncIntervalInSeconds
        prune: enablePrune
        force: false
      }
    }
  }
  dependsOn: installFluxExtension ? [fluxExtension] : []
}
