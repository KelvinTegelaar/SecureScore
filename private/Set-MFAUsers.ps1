function Set-MFAUsers {
    [Parameter(Mandatory = $true)]$tenant
    if (!$script:confirmed) {
        Write-Warning "This will enable multi-factor authentication for all admin users, and prompt them at first logon to configure MFA. Do you want to continue?" -WarningAction Inquire  
    } 
    if ($script:ExternallyResolved) {
        Set-ExternallyResolved -issue 'MFARegistrationV2'
        break
    }

    $mf = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
    $mf.RelyingParty = "*"
    $mfa = @($mf)
    get-msoluser -TenantId $tenant.tenantid | Where-Object { $null -eq $_.StrongAuthenticationRequirements.state } | Set-MsolUser -TenantId $tenant.tenantid -StrongAuthenticationRequirements $mfa  
}