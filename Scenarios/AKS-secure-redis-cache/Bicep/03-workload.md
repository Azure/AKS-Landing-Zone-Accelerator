# Deploy the Smart Brain app

This will deploy the Smart brain application to AKS utilizing Azure Cache for Redis Enterprise.

## Deployment instructions

1. Clone the smart brain app repository [here](https://github.com/mosabami/smartbrain)
2. Update the smartbrain/k8s/worker-deployment.yaml file  with the Azure Cache for Redis Enterprise configuration of the newly created Redis cluster. You will at least need to update the REDIS_HOST and REDIS_PWD.
3. Please follow the instructions found [here](https://github.com/mosabami/smartbrain/blob/main/smartbrain/README.md)
to deploy the workload in your preferred AKS cluster.
