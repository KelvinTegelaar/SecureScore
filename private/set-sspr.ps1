function Set-SSPR {
    [Parameter(Mandatory = $true)]$tenant
    if (!$script:confirmed) {
        Write-Warning "This will enable self service password reset, at the next logon users that do not have a mobile phone and/or alternative e-mail set, will be request to fill one in. Do you want to continue?" -WarningAction Inquire 
    } 
    Set-MsolCompanySettings -TenantId $tenant.TenantId -SelfServePasswordResetEnabled:$true -erroraction Stop

}