function Set-InactiveAccounts {
    [Parameter(Mandatory = $true)]$tenant
    if (!$script:confirmed) {
        Write-Warning "This will disable all users that have not logged on for 31 days or more. Do you want to coninue?" -WarningAction Inquire
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

    $date = (get-date).AddMonths(-1).ToString('yyyy-MM-ddTHH:mm:ssZ')
    $Users = (Invoke-RestMethod -Uri "https://graph.microsoft.com/beta/users?`$select=displayName,userPrincipalName,signInActivity" -Headers $script:Headers -Method Get -ContentType "application/json").value | Where-Object { $_.signInActivity.lastSignInDateTime -le $date }
    foreach ($user in $users) {
        write-host "Disabling $($user.userprincipalname)"
        Set-MsolUser -TenantId $tenant.tenantid -UserPrincipalName $($User.userprincipalname) -BlockCredential:$true
    }
}