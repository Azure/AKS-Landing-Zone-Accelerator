using 'workload-identity.bicep'

param rgName = 'rg-spoke'

param workloadIdentityName = 'workload-identity'

param oidcIssuerUrl = '<REPLACE_WITH_AKS_OIDC_ISSUER_URL>'

param workloadNamespace = 'default'

param workloadServiceAccountName = 'workload-sa'

param keyvaultName = '<REPLACE_WITH_KEYVAULT_NAME>'
