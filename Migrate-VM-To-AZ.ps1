Param(
    [Parameter(Mandatory = $true, HelpMessage = "Please provide the origin subscription ID")]
    [ValidateNotNullOrEmpty()]
    [string]
    [Alias('Please provide the origin subscription ID')]	
    $OriginSubscriptionId,

    [Parameter(Mandatory = $true, HelpMessage = "Please provide the origin resource group name")]
    [ValidateNotNullOrEmpty()]
    [string]
    [Alias('Please provide the origin resource group name')]
    $OriginResourceGroupName,

    [Parameter(Mandatory = $true, HelpMessage = "Please provide the origin virtual machine name")]
    [ValidateNotNullOrEmpty()]
    [string]
    [Alias('Please provide the origin virtual machine name')]
    $OriginVMName,

    [Parameter(Mandatory = $false, HelpMessage = "Please provide the origin location")]
    [string]
    [Alias('Please provide the origin location')]
    $OriginLocation = (Get-AzResourceGroup -Name $OriginResourceGroupName).Location,

    [Parameter(Mandatory = $false, HelpMessage = "Please provide the destination resource group name")]
    [string]
    [Alias('Please provide the destination resource group name')]
    #$DestinationResourceGroupName = "ZonalMove-MC-" + (Get-Date).ToString("yyyyMMddHHmmss"),
    $DestinationResourceGroupName = $OriginResourceGroupName,
    
    [Parameter(Mandatory = $false, HelpMessage = "Please provide the destination virtual machine name")]
    [string]
    [Alias('Please provide the destination virtual machine name')]
    $DestinationVMName = $OriginVMName,

    [Parameter(Mandatory = $false, HelpMessage = "Please provide the destination Availability Zone")]
    [string]
    [Alias('Please provide the destination Availability Zone')]
    $TargetAvailabilityZone = "2"

)


### Variables
# 1. Sign in to Azure if not already signed in
$azContext = Get-AzContext
$Login = $false
$DestinationLocation = $OriginLocation
$swapLocation = "eastus2" #eastus2euap
###

If (!($azContext)) {
    Write-Host "Please sign in to Azure"
    $Login = $true
}
If ($Login) {
    #Sign in to Azure
    Connect-AzAccount
}

Set-AzContext -SubscriptionId $OriginSubscriptionId 
$azContext = Get-AzContext 


#####Implement Pre-requisites


### P.1 Check if Microsoft.Migrate is registered in the origin subscription and register it if not
$originResourceProvider = Get-AzResourceProvider -ProviderNamespace Microsoft.Migrate
if (!($originResourceProvider.RegistrationState -eq "Registered")) {
    Write-Host "Registering Microsoft.Migrate in the origin subscription" -ForegroundColor Yellow
    Register-AzResourceProvider -ProviderNamespace Microsoft.Migrate

    While (((Get-AzResourceProvider -ProviderNamespace Microsoft.Migrate) | Where-Object { $_.RegistrationState -eq "Registered" -and $_.ResourceTypes.ResourceTypeName -eq "moveCollections" } | Measure-Object).Count -eq 0) {
        Start-Sleep -Seconds 5
        Write-Host "Waiting for registration to complete."
    }
    
    Write-Host "Microsoft.Migrate registered in the origin subscription"
}else {
    Write-Host "Microsoft.Migrate is already registered in the origin subscription" -ForegroundColor Green
}


##### #####Implement Pre-requisites END

#2. Check if Destination Resource Group exists, and if not, create it
$sourceVm = Get-AzVM -ResourceGroupName $OriginResourceGroupName -Name $OriginVMName
$DestinationLocation = $sourceVm.Location

$destinationResourceGroup = Get-AzResourceGroup -Name $DestinationResourceGroupName -ErrorAction SilentlyContinue
If (!($destinationResourceGroup)) {
    Write-Host "Creating destination resource group $DestinationResourceGroupName in $DestinationLocation" -ForegroundColor Yellow
    New-AzResourceGroup -Name $DestinationResourceGroupName -Location $DestinationLocation -Tag $ResourceGroupTags
    Write-Host "Destination resource group $DestinationResourceGroupName created in $DestinationLocation" -ForegroundColor Green
}


#3. Create a move collection in the origin subscription
#"eastus2euap" ???
$moveCollectionName = "RegionToZone-MoveCollection-" + (Get-Date).ToString("yyyyMMddHHmmss")
New-AzResourceMoverMoveCollection -Name $moveCollectionName  -ResourceGroupName $DestinationResourceGroupName -MoveRegion $DestinationLocation -Location $swapLocation -IdentityType "SystemAssigned" -MoveType "RegionToZone"
Write-Host "Move collection $moveCollectionName created in $DestinationLocation" -ForegroundColor Green

#4. Grant access to the managed identity. https://learn.microsoft.com/en-us/azure/virtual-machines/move-virtual-machines-regional-zonal-powershell?tabs=PowerShell#grant-access-to-the-managed-identity
$moveCollection = Get-AzResourceMoverMoveCollection -Name $moveCollectionName -ResourceGroupName $DestinationResourceGroupName
$identityPrincipalId = $moveCollection.IdentityPrincipalId

#Get subscription resource ID /subscriptions/<subscription-id>
write-host "Granting access to the managed identity $identityPrincipalId ..." -ForegroundColor Yellow
$subscriptionId = "/subscriptions/" + $OriginSubscriptionId
#Check if the managed identity already has the required permissions if not, grant them
$roleAssignmentsContributor = Get-AzRoleAssignment -ObjectId $identityPrincipalId -Scope $subscriptionId -RoleDefinitionName Contributor -ErrorAction SilentlyContinue
$roleAssignmentsUserAccessAdministrator = Get-AzRoleAssignment -ObjectId $identityPrincipalId -Scope $subscriptionId -RoleDefinitionName "User Access Administrator" -ErrorAction SilentlyContinue

if(!($roleAssignmentsContributor) ){
    write-host "Granting Contributor access to the managed identity $identityPrincipalId ..." -ForegroundColor Yellow
    New-AzRoleAssignment -ObjectId $identityPrincipalId -RoleDefinitionName Contributor -Scope $subscriptionId  
}else{
    write-host "The managed identity $identityPrincipalId already has Contributor access" -ForegroundColor Green
}

if(!($roleAssignmentsUserAccessAdministrator) ){
    write-host "Granting User Access Administrator access to the managed identity $identityPrincipalId ..." -ForegroundColor Yellow
    New-AzRoleAssignment -ObjectId $identityPrincipalId -RoleDefinitionName "User Access Administrator" -Scope $subscriptionId
}else{
    write-host "The managed identity $identityPrincipalId already has User Access Administrator access" -ForegroundColor Green
}


#5. Add regional VMs to the move collection. https://learn.microsoft.com/en-us/azure/virtual-machines/move-virtual-machines-regional-zonal-powershell?tabs=PowerShell#add-regional-vms-to-the-move-collection

#Create target resource setting object as follows:
$targetResourceSettingsObj = New-Object Microsoft.Azure.PowerShell.Cmdlets.ResourceMover.Models.Api20230801.VirtualMachineResourceSettings
$targetResourceSettingsObj.ResourceType = "Microsoft.Compute/virtualMachines"
$targetResourceSettingsObj.TargetResourceName = $DestinationVMName
$targetResourceSettingsObj.TargetAvailabilityZone = $TargetAvailabilityZone

#Add resources
#Get VM resource ID
$sourceVm = Get-AzVM -ResourceGroupName $OriginResourceGroupName -Name $OriginVMName
$resourceMoverName=$DestinationVMName + "_MovedResource"
Add-AzResourceMoverMoveResource -ResourceGroupName $DestinationResourceGroupName -MoveCollectionName $moveCollectionName -SourceId $sourceVm.Id -Name $resourceMoverName -ResourceSetting $targetResourceSettingsObj




#6. Resolve dependencies. https://learn.microsoft.com/en-us/azure/virtual-machines/move-virtual-machines-regional-zonal-powershell?tabs=PowerShell#resolve-dependencies
write-host "Resolving dependencies ..." -ForegroundColor Yellow
Resolve-AzResourceMoverMoveCollectionDependency -ResourceGroupName $DestinationResourceGroupName -MoveCollectionName $moveCollectionName

write-host "Dependencies resolved" -ForegroundColor Green
Get-AzResourceMoverMoveResource -ResourceGroupName $DestinationResourceGroupName -MoveCollectionName $moveCollectionName | Select-Object -Property Name, IsResolveRequired, ProvisioningState, MoveStatusMoveState,  SourceId, TargetId | Format-Table -AutoSize


### =================>
#7. Initiate the move. https://learn.microsoft.com/en-us/azure/virtual-machines/move-virtual-machines-regional-zonal-powershell?tabs=PowerShell#initiate-the-move
write-host "Initiating the move ..." -ForegroundColor Yellow
Invoke-AzResourceMoverInitiateMove -ResourceGroupName $DestinationResourceGroupName -MoveCollectionName $moveCollectionName -MoveResource $resourceMoverName -MoveResourceInputType "MoveResourceId"


#8. Commit the move. https://learn.microsoft.com/en-us/azure/virtual-machines/move-virtual-machines-regional-zonal-powershell?tabs=PowerShell#commit-the-move
Invoke-AzResourceMoverCommit -ResourceGroupName $DestinationResourceGroupName -MoveCollectionName $moveCollectionName -MoveResource $($resourceMoverName) -MoveResourceInputType "MoveResourceId"

Write-Host "Move completed!" -ForegroundColor Green
