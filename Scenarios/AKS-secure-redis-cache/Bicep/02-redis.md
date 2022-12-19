# Deploy Azure Cache for Redis Enteprise using Bicep

This will create a Azure Cache for Redis Enteprise cluster with private endpoint in the subnet of your choice.

## Connect to Azure

* Login to Azure

   ```bash
   TENANTID=<tenant id>
   az login -t $TENANTID
   ```

* Ensure you are connected to the correct subscription

   ```bash
   az account set --subscription <subscription id>
   ```

## Deploy Azure Cache for Redis Enterprise

* Run bicep file

    ``` bash
    az deployment sub --template-file main.bicep --location <location> 
    ```
