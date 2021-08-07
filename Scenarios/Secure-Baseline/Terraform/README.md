# A Word on Terraform State Management:
In this example, state is stored in an Azure Storage account that was created out-of-band.  All deployments reference this storage account using an storage account access key, however you may choose to use other tools for state managment, like Terraform Cloud after making the necessary code changes.


