# Deploy the Smart Brain app

This will deploy the Smart brain application to AKS utilizing Azure Cache for Redis Enterprise.

## Deployment instructions

1. Clone the smart brain app repository [here](https://github.com/mosabami/smartbrain)
2. Update the smartbrain/k8s/worker-deployment.yaml file  with the Azure Cache for Redis Enterprise configuration of the newly created Redis cluster. You will need to update the REDIS_HOST, REDIS_PWD, REDIS_PORT and REDIS_SSL settings.
    - By Default the REDIS_SSL value = 0, please update this value to 1 if using Azure Cache for Redis Enterprise with TLS connection.
3. Please follow the instructions found [here](https://github.com/mosabami/smartbrain/blob/main/smartbrain/README.md)
to deploy the workload in your preferred AKS cluster.
