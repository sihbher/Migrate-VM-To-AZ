# Azure VM Migration to Zonal Deployment Helper

This project provides a PowerShell script to help migrate an Azure Virtual Machine from a regional to a zonal deployment. It follows the guidance from this [article](https://learn.microsoft.com/en-us/azure/virtual-machines/move-virtual-machines-regional-zonal-powershell).

## Table of Contents

- [Problem Statement](#problem-statement)
- [Use Case](#use-case)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
    - [Steps to Deploy Terraform Example](#steps-to-deploy-terraform-example)
        - [Example Commands](#example-commands)
    - [How to Use the PowerShell Script](#how-to-use-the-powershell-script)
        - [Steps to Execute the PowerShell Script](#steps-to-execute-the-powershell-script)
        - [Example Usage](#example-usage)
        - [Parameters](#parameters)
        - [Notes](#notes)

## Problem Statement

Deploying Azure Virtual Machines (VMs) in a regional scope may limit service availability and resilience, as all resources are located within a single Azure region. This can lead to service downtime if the region experiences an outage, which may not meet the requirements for mission-critical applications.

Azure’s Availability Zones provide physically separate locations within a region, each with independent power, cooling, and networking. Migrating VMs from a regional to a zonal deployment can enhance application resilience by isolating resources across these zones. However, the migration process involves multiple configuration steps, resource checks, and dependency management, which can be complex and time-consuming.

## Use Case

This PowerShell script simplifies the process of migrating Azure VMs from a regional to a zonal deployment. The script automates key steps, including:

1. Verifying the resource group and VM details.
2. Registering the required resource provider (`Microsoft.Migrate`).
3. Creating the destination resource group if it does not exist.
4. Setting up and managing an Azure Resource Mover collection.
5. Resolving dependencies and ensuring all required resources are included.
6. Initiating and committing the move to the specified availability zone.

This automation enables IT administrators and DevOps teams to:

- Improve resilience and availability by using Azure Availability Zones.
- Simplify and speed up VM migration to zonal deployments with minimal manual intervention.
- Follow best practices as described in the [Azure documentation](https://learn.microsoft.com/en-us/azure/virtual-machines/move-virtual-machines-regional-zonal-powershell).

## Prerequisites

- Terraform installed on your local machine
- An Azure account with sufficient permissions

## Usage

This repository includes Terraform code to deploy a single regional VM, which can then be migrated using the PowerShell script.

### Steps to Deploy Terraform Example

1. **Clone the Repository**

    ```bash
    git clone https://github.com/yourusername/Migrate-VM-To-AZ.git
    cd Migrate-VM-To-AZ
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

    - Confirm by typing `yes` when prompted.

#### Example Commands

```bash
# Clone the repository
git clone https://github.com/sihbher/Migrate-VM-To-AZ.git

# Navigate to the project directory
cd terraform_test_vm

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
    cd /Path/To/Migrate-VM-To-AZ/Scripts
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
cd C:\Users\YourName\Migrate-VM-To-AZ\Scripts

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
