using 'main.bicep'

param rgName = 'AKS-Istio-Mesh-RG'

param vnetName = 'istio-mesh-vnet'

param vnetAddressPrefixes = ['10.10.0.0/16']

param aksSubnetPrefix = '10.10.1.0/24'

param aksClusterName = 'aks-istio-mesh'

param kubernetesVersion = '1.30'

param vmSize = 'Standard_DS4_v2'

param aksAdminsGroupId = '<REPLACE_WITH_ENTRA_ID_GROUP_OBJECT_ID>'

param istioRevision = 'asm-1-27'

param enableIstioInternalIngress = true

param enableIstioExternalIngress = false
