function Set-SSPR {
    [Parameter(Mandatory = $true)]$tenant
    if (!$script:confirmed) {
        Write-Warning "This will enable self service password reset, at the next logon users that do not have a mobile phone and/or alternative e-mail set, will be request to fill one in. Do you want to continue?" -WarningAction Inquire 
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

    Set-MsolCompanySettings -TenantId $tenant.TenantId -SelfServePasswordResetEnabled:$true -erroraction Stop

}