

# Create a new Azure AD Service Principal.
# To be used for Terraform

$tenant = Get-AzTenant

# Make sure we are using the right subscription (Pay-As-You-Go)
$subscription = Select-AzSubscription -SubscriptionId 'e14cf51b-9ce6-40e1-841a-6214c2f28f7c'

# Variables for Service Principal Creation
$input_role = "Contributor"
$input_scope = "/subscriptions/$($subscription.subscription)"
$input_displayname = "TERRAFORM_DEV"

$sp = New-AzADServicePrincipal -Role $input_role -Scope $input_scope -DisplayName $input_displayname

# Decode The Secret

$value = $sp.Secret | ConvertFrom-SecureString
$secret_decode = [System.Runtime.InteropServices.Marshal]::PtrToStringUni([System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($value))

Write-Host "Tenant               : $($tenant.Id)"
Write-Host "Application ID       : $($sp.ApplicationId)"
Write-Host "Secret               : $($secret_decode)"

$sp