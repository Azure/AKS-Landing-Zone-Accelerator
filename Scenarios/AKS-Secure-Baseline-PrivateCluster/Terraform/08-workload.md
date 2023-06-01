# Deploy a Sample Workload

These applications are provided to demonstrate examples of various types of applications and authentication scenarios for AKS Windows container scenarios. You may deploy one or both. 

We've included two sample applications demonstrating Windows Integrated Authentication with Group Managed Service Accounts (GMSA):

[Simple GMSA Application](../Apps/SimpleGMSAApp/Getting-Started.md)
   
   The Simple GMSA Application walks you through the process of setting up GMSA integration with AKS using the [GMSA PowerShell Module](https://learn.microsoft.com/en-us/virtualization/windowscontainers/manage-containers/gmsa-aks-ps-module) created by Microsoft. This application loads a simple phrase once the application is accessible. 
   
   **If you're looking to get a feel for how GMSA works with AKS, try deploying this application.**

[Legacy .NET Application](../Apps/eshopLegacyApp/Getting-Started.md)
   
   The Legacy .NET (.NET 4.7) Application also walks you through setting up GMSA for your cluster, but the application is ecommerce focused with a shopping webpage UI and backend SQL database for storing product information. As a full .NET project as opposed to the simple application, it also demonstrates how to turn on Windows Integrated Authentication through the Web.config for .NET. 
   
   **If you have a legacy .NET application you're looking to deploy onto AKS, try deploying this application.**
