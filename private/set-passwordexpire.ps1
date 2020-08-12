function Set-PasswordExpire {
     
    if (!$script:confirmed) {
        Write-Warning "This will execute disable the password expire date on all accounts. Do you want to continue?"-WarningAction Inquire 
    } 
    if ($script:ExternallyResolved) {
        Set-ExternallyResolved -issue 'PWAgePolicyNew'

    }
    else {
        Get-MsolUser -All -TenantId $tenant.tenantid | Where-Object { $null -eq $_.LastDirSyncTime } | foreach-object { Set-MsolUser -TenantId $tenant.tenantid -UserPrincipalName $_.UserPrincipalName -PasswordNeverExpires $true }
    }

}
