function Set-oauthConsent {
    [Parameter(Mandatory = $true)]$tenant
    if (!$script:confirmed) {
        Write-Warning "This will disable users from allowing to consent to oauth applications, Users that are using Android or IOS mail will get a consent pop-up, when first reconfiguring the mail application. You must give consent once as an administrator. Do you want to continue?" -WarningAction Inquire  
    } 
    Set-MsolCompanySettings -tenantID $tenant.tenantid -UsersPermissionToUserConsentToAppEnabled:$false -ErrorAction Stop
}