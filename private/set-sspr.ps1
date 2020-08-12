function Set-SSPR {
     
    if (!$script:confirmed) {
        Write-Warning "This will enable self service password reset, at the next logon users that do not have a mobile phone and/or alternative e-mail set, will be request to fill one in. Do you want to continue?" -WarningAction Inquire 
    } 
    if ($script:ExternallyResolved) {
        Set-ExternallyResolved -issue 'SelfServicePasswordReset'

    }
    else {
        Set-MsolCompanySettings -TenantId $tenant.TenantId -SelfServePasswordResetEnabled:$true -erroraction Stop
    }
}