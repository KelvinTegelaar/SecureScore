function Set-InactiveAccounts {
     
    if (!$script:confirmed) {
        Write-Warning "This will disable all users that have not logged on for 31 days or more. Do you want to coninue?"-WarningAction Inquire 
    } 
    if ($script:ExternallyResolved) {
        Set-ExternallyResolved -issue 'InactiveAccounts'    
    }
    else {
        $date = (get-date).AddMonths(-1).ToString('yyyy-MM-ddTHH:mm:ssZ')
        $Users = (Invoke-RestMethod -Uri "https://graph.microsoft.com/beta/users?`$select=displayName,userPrincipalName,signInActivity" -Headers $script:Headers -Method Get -ContentType "application/json").value | Where-Object { $_.signInActivity.lastSignInDateTime -le $date }
        foreach ($user in $users) {
            write-host "Disabling $($user.userprincipalname)"
            Set-MsolUser -TenantId $tenant.tenantid -UserPrincipalName $($User.userprincipalname) -BlockCredential:$true
        }
    }
}