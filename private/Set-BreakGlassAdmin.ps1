function set-BreakGlassAdmin {
    [Parameter(Mandatory = $true)]$tenant,
    [Parameter(Mandatory = $false)][switch]$confirmed
    if (!$script:confirmed) {
        Write-Warning "This will create a new 'BreakGlass' admin user to be used in cases of emergency" -WarningAction Inquire  
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

    write-host "Using $tenant"
    $username = "Breakglass-" + (Get-Random -Minimum 1000 -Maximum 3000) + '@' + (Get-MsolDomain -TenantId $tenant.TenantId | where-object { $_.IsInitial -eq $true } ).name
    New-MsolUser -TenantId $tenant.TenantId -UserPrincipalName  $username -DisplayName 'Breakglass admin account' -FirstName "Breakglass" -LastName "Account"
    Add-MsolRoleMember -TenantId $tenant.TenantId -RoleName "Company Administrator" -RoleMemberEmailAddress $username
}