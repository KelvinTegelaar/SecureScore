function Set-AdminMFA {
    if (!$script:confirmed) {
        Write-Warning "This will enable multi-factor authentication for all admin users, and prompt them at first logon to configure MFA. Do you want to continue?" -WarningAction Inquire  
    } 
    if ($script:ExternallyResolved) {
        Set-ExternallyResolved -issue 'AdminMFAV2'
    }
    else {
        $mf = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
        $mf.RelyingParty = "*"
        $mfa = @($mf)
        $admins = Get-MsolRoleMember -TenantId $tenant.tenantid -RoleObjectId (Get-MsolRole -RoleName "Company Administrator").ObjectId | Set-MsolUser -StrongAuthenticationRequirements $mfa   
    }
}
