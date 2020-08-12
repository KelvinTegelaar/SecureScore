function Set-ExternallyResolved {
  [Parameter(Mandatory = $true)]$Issue

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

  write-host "Setting $($Issue) to the Externally Resolved / Third Party state"
  (Invoke-RestMethod -method Patch -Body $body -Uri  "https://graph.microsoft.com/beta/security/secureScoreControlProfiles/$($Issue)" -Headers $Headers -ContentType "application/json").value 
}
