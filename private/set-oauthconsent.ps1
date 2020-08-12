function Set-oauthConsent {
    [Parameter(Mandatory = $true)]$tenant
    if (!$script:confirmed) {
        Write-Warning "This will disable users from allowing to consent to oauth applications, Users that are using Android or IOS mail will get a consent pop-up, when first reconfiguring the mail application. You must give consent once as an administrator. Do you want to continue?" -WarningAction Inquire  
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

    Set-MsolCompanySettings -tenantID $tenant.tenantid -UsersPermissionToUserConsentToAppEnabled:$false -ErrorAction Stop
}