function Set-PasswordExpire {
    [Parameter(Mandatory = $true)]$tenant
    if (!$script:confirmed) {
        Write-Warning "This will execute disable the password expire date on all accounts. Do you want to continue?" -WarningAction Inquire
    } 
    
    if (!$script:ExternallyResolve) {
        Write-Warning "Marking issue $($issue) as externally resolved by third party tool." -foregroundcolor Green
$body = @"
{
    "assignedTo": "",
    "comment": "Externally resolved via scripting",
    "state": "ThirdParty",
    "vendorInformation": {
  
      "provider": "SecureScore",
      "providerVersion": null,
      "subProvider": null,
      "vendor": "Microsoft"
    }
  }
"@

(Invoke-RestMethod -method Patch -Body $body -Uri  'https://graph.microsoft.com/beta/security/secureScoreControlProfiles/$($issue)' -Headers $Headers -ContentType "application/json").value 

break
    } 

    Get-MsolUser -All -TenantId $tenant.tenantid | Where-Object { $null -eq $_.LastDirSyncTime } | foreach-object { Set-MsolUser -TenantId $tenant.tenantid -UserPrincipalName $_.UserPrincipalName -PasswordNeverExpires $true }
}
