function Set-UserRiskPolicy {
   
  if (!$script:confirmed) {
    Write-Warning "This policy has to be activated manually, but when using external tools such as the cyberdrain.com location monitoring script you can use this method to tell the Secure Score API you are using a third party solution. Would you like to continue?"-WarningAction Inquire 
  } 
    if ($script:ExternallyResolved) {
      Set-ExternallyResolved -issue 'PWAgePolicyNew'
    }
    else {
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

      (Invoke-RestMethod -method Patch -Body $body -Uri  'https://graph.microsoft.com/beta/security/secureScoreControlProfiles/UserRiskPolicy' -Headers $Headers -ContentType "application/json").value 
    }
  }