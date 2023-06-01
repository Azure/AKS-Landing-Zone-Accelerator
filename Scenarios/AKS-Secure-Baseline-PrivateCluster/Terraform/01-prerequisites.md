# Prerequisites

1. An Azure subscription
   The subscription used in this deployment cannot be a free account; it must be a standard EA, pay-as-you-go, or Visual Studio benefit subscription. This is because the resources deployed here are beyond the quotas of free subscriptions.

    The service principal initiating the deployment process must have the following minimal set of Azure Role-Based Access Control (RBAC) roles:

        - Contributor role is required at the subscription level to have the ability to create resource groups and perform deployments.
        - User Access Administrator role is required at the subscription level since you'll be performing role assignments to managed identities across various resource groups.
        - Global Admin on Azure AD Tenant is required for setting up Azure Application Proxy. This setup is done manually. An admin could perform this step for you as it's the last step in the setup after deploying your application. 
    Please follow [these instructions](https://learn.microsoft.com/azure/active-directory/develop/howto-create-service-principal-portal) to create a service principal in Azure. 
2. PowerShell terminal. This reference reference implementation uses PowerShell for deployment.
3. Latest [Azure CLI installed](https://learn.microsoft.com/cli/azure/install-azure-cli-windows?tabs=powershell#powershell)
4. [Terraform version 1.4.0 or greater](https://learn.microsoft.com/azure/developer/terraform/get-started-windows-bash?tabs=bash#4-install-terraform-for-windows)
5. Clone/download this repo locally using a Git Bash terminal, GitHub Desktop app or VSCode.
    ``` Git Bash
    git clone https://github.com/Azure/aks-baseline-windows.git
    cd aks-baseline-windows
    ```

    [VSCode](https://learn.microsoft.com/azure/developer/javascript/how-to/with-visual-studio-code/clone-github-repository?tabs=create-repo-command-palette%2Cinitialize-repo-activity-bar%2Ccreate-branch-command-palette%2Ccommit-changes-command-palette%2Cpush-command-palette#clone-repository)
    
    [GitHub Desktop app](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository?tool=desktop#cloning-a-repository)

# Next Step
:arrow_forward: [Setup state storage for Terraform](./02-state-storage.md)