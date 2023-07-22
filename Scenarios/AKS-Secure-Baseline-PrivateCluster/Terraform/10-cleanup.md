# Cleanup

Remember to destroy resources that are not in use

1. Delete the AKS cluster

   ```bash
   cd ../../Terraform/07-AKS-cluster 
   ```

   ```bash
   terrform init
   ```

   ```bash
   terraform destroy
   ```

2. Delete the supporting services

   ```bash
   cd ../06-AKS-supporting
   ```

   ```bash
   terraform init
   ```

   ```bash
   terraform destroy
   ```

   

3. Delete the spoke network

   ```bash
   cd ../05-Network-LZ
   ```

   ```bash
   terraform init
   ```

   ```bash
   terraform destroy
   ```

   if you get an error, move on to the next step

4. Delete the hub network

   ```
   cd ../04-Network-Hub
   ```

   ```
   terraform init
   ```

   ```
   terraform destroy
   ```

   if you get an error, stating that some resources weren't destroyed, run terraform destroy again

   ```
   terraform destroy
   ```

5. Delete the user groups you created

   ```
   cd ../03-AAD
   ```

   ```
   terraform init
   ```

   ```
   terraform destroy
   ```

   