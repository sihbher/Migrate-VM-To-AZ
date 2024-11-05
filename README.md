
# Azure VM migration to zonal deployment helper
This project provides an example on now to use PowerShell to migrate an Azure Virtual Machine deployed as regional to a zonal deployment. It is based on this [article](https://learn.microsoft.com/en-us/azure/virtual-machines/move-virtual-machines-regional-zonal-powershell)


## Table of Contents

- [Problem statement](#problem-statement)
- [Use case](#use-case)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
    - [Steps to Deploy Terraform example](#steps-to-deploy-terraform-example)
        - [Example Commands](#example-commands)
    - [How to use the PowerShell script](#how-to-use-the-powershell-script)
        - [Steps to Execute the PowerShell Script](#steps-to-execute-the-powershell-script)
        - [Example Usage](#example-usage)
        - [Parameters](#parameters)
        - [Notes](#notes)


## Problem statement
Organizations deploying Azure Virtual Machines (VMs) in a regional scope often face challenges with service availability and resilience due to the lack of zonal separation. In a regional deployment, all resources are placed within a single Azure region, making them susceptible to downtime if the region encounters an outage. For mission-critical applications, this single-region approach may not meet availability requirements, especially for disaster recovery and high availability.

Azure offers Availability Zones, which are unique physical locations within an Azure region, each with independent power, cooling, and networking. Migrating VMs from a regional to a zonal deployment can significantly improve application resilience by isolating resources across these zones. However, the migration process from a regional deployment to a zonal deployment involves multiple configuration steps, resource checks, and dependency resolutions, which can be complex and time-consuming.

## Use case
This PowerShell-based project provides a script to simplify the migration of Azure Virtual Machines from a regional to a zonal deployment. This script automates essential steps such as:

1. Verifying the resource group and VM details.
2. Registering the required resource provider (`Microsoft.Migrate`).
3. Setting up the destination resource group if it doesn't exist.
4. Creating and managing an Azure Resource Mover collection to facilitate the migration.
5. Resolving dependencies and ensuring that all required resources are included in the migration.
6. Initiating and committing the move to the specified target availability zone.

By automating this process, the script helps IT administrators and DevOps teams to:

- Enhance the resilience and availability of Azure-based applications by leveraging Availability Zones.
- Simplify and accelerate the migration of VMs to zonal deployments, ensuring minimal manual intervention.
- Follow best practices as outlined in the [Azure documentation](https://learn.microsoft.com/en-us/azure/virtual-machines/move-virtual-machines-regional-zonal-powershell) for regional-to-zonal VM migration.


## Prerequisites


- Terraform installed on your local machine
- An Azure account with sufficient permissions


## Usage
This repo contains a terraform code for deploying a single regional virtual machine, with this then you can test the migration procesure using the PowerShell script

### Steps to Deploy Terraform example

1. **Clone the Repository**

    ```bash
    git clone https://github.com/yourusername/RegionalToZonal.git
    cd RegionalToZonal
    ```

2. **Initialize Terraform**

    ```bash
    terraform init
    ```

3. **Review Configuration**

    - Update any necessary variables in the `variables.tf` file.

4. **Plan the Deployment**

    ```bash
    terraform plan
    ```

5. **Apply the Deployment**

    ```bash
    terraform apply
    ```

    - Confirm the prompt by typing `yes`.

#### Example Commands

```bash
# Clone the repository
git clone https://github.com/yourusername/RegionalToZonal.git

# Navigate to the project directory
cd RegionalToZonal

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the deployment
terraform apply
```

**Note:** Ensure your Azure credentials are configured properly.

### How to use the PowerShell script

The PowerShell script provided in this repository facilitates the migration of an Azure Virtual Machine from a regional to a zonal deployment.

#### Steps to Execute the PowerShell Script

1. **Open PowerShell**

    Ensure you have the necessary permissions to run scripts on your machine. You might need to adjust the execution policy:
    
    ```powershell
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
    ```

2. **Navigate to the Script Directory**

    ```powershell
    cd /Path/To/RegionalToZonal/Scripts
    ```

3. **Configure Azure Credentials**

    Authenticate your Azure account to allow the script to perform operations:
    
    ```powershell
    Connect-AzAccount
    ```

4. **Run the Migration Script**

    Execute the script to start the migration process:
    
    ```powershell
    .\Migrate-VM-To-AZ.ps1 -OriginSubscriptionId "YourSubscriptionID" -OriginResourceGroupName "YourResourceGroup" -OriginVMName "YourVMName"
    ```

#### Example Usage 1: Basic Migration with Mandatory Parameters
In this example, only the mandatory parameters are provided. The VM is moved within the same resource group and retains its original name and default availability zone.
```powershell
# Authenticate with Azure
Connect-AzAccount

# Navigate to the scripts directory
cd C:\Users\YourName\RegionalToZonal\Scripts

# Execute the migration script
.\Migrate-VM-To-AZ.ps1 -OriginSubscriptionId "XXXXX-XXXX-XXXX-XXX-XXXX" -OriginResourceGroupName "ProdResources" -OriginVMName "WebServer01"
```

#### Example Usage 2: Specifying a Different Resource Group and Availability Zone
This example specifies an alternative resource group and a target availability zone. The VM is migrated to a different resource group and a specified availability zone in the destination.
```powershell
.\Migrate-VM-To-AZ.ps1 -OriginSubscriptionId "12345678-1234-1234-1234-123456789abc" `
                -OriginResourceGroupName "MyResourceGroup" `
                -OriginVMName "MyVirtualMachine" `
                -DestinationResourceGroupName "MyDestinationResourceGroup" `
                -TargetAvailabilityZone "3"
```
#### Example Usage 3: Specifying All Parameters Including Origin Location
In this example, all parameters are specified. The script moves the VM to a new resource group with a new name in a specific availability zone and origin location.
```powershell
.\Move-AzVM.ps1 -OriginSubscriptionId "12345678-1234-1234-1234-123456789abc" `
                -OriginResourceGroupName "MyResourceGroup" `
                -OriginVMName "MyVirtualMachine" `
                -OriginLocation "eastus" `
                -DestinationResourceGroupName "MyDestinationResourceGroup" `
                -DestinationVMName "MyNewVirtualMachine" `
                -TargetAvailabilityZone "1"
```

**Parameters:**
## Parameters

| Parameter                     | Type     | Mandatory | Description                                                                                                            | Default                                   | Example                                      |
| ----------------------------- | -------- | --------- | ---------------------------------------------------------------------------------------------------------------------- | ----------------------------------------- | -------------------------------------------- |
| `-OriginSubscriptionId`       | `String` | Yes       | The subscription ID of the Azure subscription where the original VM is located.                                        | N/A                                       | `"12345678-1234-1234-1234-123456789abc"`     |
| `-OriginResourceGroupName`    | `String` | Yes       | The name of the Azure Resource Group containing the source virtual machine.                                            | N/A                                       | `"MyResourceGroup"`                          |
| `-OriginVMName`               | `String` | Yes       | The name of the virtual machine to migrate from a regional deployment to a zonal deployment.                           | N/A                                       | `"MyVirtualMachine"`                         |
| `-OriginLocation`             | `String` | No        | The location (region) of the source resource group. Defaults to the location of the specified resource group if absent.| Location of `$OriginResourceGroupName`    | `"eastus"`                                  |
| `-DestinationResourceGroupName` | `String` | No        | The name of the destination resource group to which the VM will be moved. Defaults to the origin resource group name. | `$OriginResourceGroupName`               | `"MyDestinationResourceGroup"`              |
| `-DestinationVMName`          | `String` | No        | The name of the virtual machine in the destination resource group. Defaults to the original VM name.                   | `$OriginVMName`                           | `"MyNewVirtualMachine"`                     |
| `-TargetAvailabilityZone`     | `String` | No        | Specifies the target availability zone for the virtual machine in the destination region.                              | `"2"`                                     | `"1"`                                       |



**Notes:**

- Ensure the target zone is available and meets the deployment requirements.
- Review the script parameters and customize them as needed for your environment.

For further assistance, refer to the [Move a virtual machine in an availability zone using Azure PowerShell and CLI](https://learn.microsoft.com/en-us/azure/virtual-machines/move-virtual-machines-regional-zonal-powershell)
