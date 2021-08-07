## Terraform State Management
In this example, state is stored in an Azure Storage account that was created out-of-band.  All deployments reference this storage account using an storage account access key, however you may choose to use other tools for state managment, like Terraform Cloud after making the necessary code changes.

## Keeping It As Simple As Possible
The code here is purposely written to avoid loops, complex variables and logic. In most cases, it is resource blocks, small modules and limited variables, with the goal of making it easier to determine what is being deployed and how they are connected. Resources are broken into separate files for future modularization as needed by your organization. 


