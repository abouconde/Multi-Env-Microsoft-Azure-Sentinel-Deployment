# Login to Azure
$login = Login-AzAccount
if (-not $login) {
    Write-Error "Azure login failed. Exiting..."
    exit
}

# List subscriptions and prompt for selection
Get-AzSubscription | Format-Table -Property Name, Id
$subId = Read-Host "Please enter the Subscription ID you want to use"
Set-AzContext -SubscriptionId $subId

Write-Host "Azure context set."

# Initialize Terraform
terraform init

# Apply Terraform configuration for each environment-region pair
$environment_region_map = @{
  dev      = "francecentral"
  staging  = "northeurope"
  prod     = "westeurope"
}

# Deployment
foreach ($env in $environment_region_map.Keys) {
    $region = $environment_region_map[$env]
    Write-Host "Deploying to $env environment in the $region region."
    terraform apply -var "name_prefix=mug" -var "environments=[$env]" -var "regions=[$region]" -var "environment_region_map={$env=$region}" -var-file="deployment.tfvars" -auto-approve
}

# Deletion Option
$deleteAll = Read-Host "Do you want to delete all resources? (yes/no)"
if ($deleteAll -eq "yes") {
    foreach ($env in $environment_region_map.Keys) {
        $rgName = "mug-$env-rg"
        Write-Host "Deleting resource group $rgName"
        Remove-AzResourceGroup -Name $rgName -Force -AsJob
    }
    Write-Host "All resource groups have been scheduled for deletion."
}
