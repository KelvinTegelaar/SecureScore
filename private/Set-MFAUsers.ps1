function Set-MFAUsers {
    [Parameter(Mandatory = $true)]$tenant
    if (!$script:confirmed) {
        Write-Warning "This will enable multi-factor authentication for all admin users, and prompt them at first logon to configure MFA. Do you want to continue?" -WarningAction Inquire  
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

    $mf = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
    $mf.RelyingParty = "*"
    $mfa = @($mf)
    get-msoluser -TenantId $tenant.tenantid | Where-Object { $null -eq $_.StrongAuthenticationRequirements.state } | Set-MsolUser -TenantId $tenant.tenantid -StrongAuthenticationRequirements $mfa  
}