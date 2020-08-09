function Set-SecureScore {
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'AllTenants', Mandatory = $true)][switch]$AllTenants,
        [Parameter(Mandatory = $false)][switch]$Confirmed,
        [Parameter(Mandatory = $true)]
        [ValidateSet("All",
            "LowImpact",
            "MediumImpact",
            "HighImpact",
            "AdminMFAV2",
            "DLPEnabled",
            "IntegratedApps",
            "OneAdmin",
            "PWAgePolicyNew",
            "InactiveAccounts",
            "SigninRiskPolicy",
            "UserRiskPolicy",
            "MFARegistrationV2",
            "SelfServicePasswordReset"
        )][string]$ControlName,
        [Parameter(Mandatory = $false)][switch]$ExternallyResolved,
        [Parameter(Mandatory = $true)][string]$upn,
        [Parameter(Mandatory = $true)][string]$RefreshToken,
        [Parameter(Mandatory = $true)][string]$ExchangeToken,
        [Parameter(Mandatory = $true)][string]$ApplicationId,
        [Parameter(Mandatory = $true)][string]$ApplicationSecret,
        [Parameter(ParameterSetName = 'TenantID', Mandatory = $true)][string]$TenantID
    )
    $script:confirmed = $Confirmed
    write-host "Generating tokens for logon" -ForegroundColor Green
    try {
        $credential = New-Object System.Management.Automation.PSCredential($ApplicationId, ($ApplicationSecret | ConvertTo-SecureString -Force -AsPlainText))
        $aadGraphToken = New-PartnerAccessToken -ApplicationId $ApplicationId -Credential $credential -RefreshToken $refreshToken -Scopes 'https://graph.windows.net/.default' -ServicePrincipal 
        $graphToken = New-PartnerAccessToken -ApplicationId $ApplicationId -Credential $credential -RefreshToken $refreshToken -Scopes 'https://graph.microsoft.com/.default' -ServicePrincipal
    }
    catch {
        write-error "Generating tokens failed. $($_.Exception.Message)"
        break
    }
    write-host "Logging into Azure AD" -ForegroundColor Green
    try {
        Connect-MsolService -AdGraphAccessToken $aadGraphToken.AccessToken -MsGraphAccessToken $graphToken.AccessToken
        if ($AllTenants) {
            $tenants = Get-MsolPartnerContract -All
        } 
        else {
            $tenants = Get-MsolPartnerContract -All | Where-Object { $_.DefaultDomainName -eq $TenantID }
        }
            
    }
    catch {
        write-error "Logging in to Azure AD failed. $($_.Exception.Message)"
        break
    }
    if ($AllTenants) { write-host "Found $($Tenants.count) tenants.." -ForegroundColor Green } 
    else { 
        write-host "Using $($tenants.DefaultDomainName)." 
    }

    foreach ($tenant in $tenants) {
        write-host "Getting Graph Token $($tenant.DefaultDomainName)." -ForegroundColor Green
        try {
            $CustomerToken = New-PartnerAccessToken -ApplicationId $ApplicationId -Credential $credential -RefreshToken $refreshToken -Scopes 'https://graph.microsoft.com/.default' -ServicePrincipal -Tenantid $($tenant.Tenantid) -ErrorAction Stop
        }
        catch {
            write-error "Getting token failed for $($tenant.DefaultDomainName). $($_.Exception.Message)"
            continue
    
        }
        $script:headers = @{ "Authorization" = "Bearer $($CustomerToken.AccessToken)" }

        switch ($ControlName) {
            "AdminMFAV2" { set-adminmfa -tenant $tenant.tenantid }
            "DLPEnabled" { set-dlppolicy -tenant $tenant.tenantid } 
            "IntegratedApps" { set-oauthconsent -tenant $tenant.tenantid }
            "OneAdmin" { set-breakglassadmin -tenant $tenant.tenantid } 
            "PWAgePolicyNew" { set-passwordexpire -tenant $tenant.tenantid }
            "InactiveAccounts" { set-inactiveaccounts -tenant $tenant.tenantid } 
            "SigninRiskPolicy" { set-signinriskpolicy -tenant $tenant.tenantid } 
            "UserRiskPolicy" { set-userriskpolicy -tenant $tenant.tenantid } 
            "MFARegistrationV2" { Set-MFAUsers -tenant $tenant.tenantid } 
            "SelfServicePasswordReset" { set-sspr -tenant $tenant.tenantid }
            "All" {
                set-breakglassadmin -tenant $tenant.tenantid
                set-dlppolicy -tenant $tenant.tenantid
                set-oauthconsent -tenant $tenant.tenantid
                set-passwordexpire -tenant $tenant.tenantid
                set-sspr -tenant $tenant.tenantid
                set-irmdocs -tenant $tenant.tenantid
                set-customerlockbox -tenant $tenant.tenantid
                set-userriskpolicy -tenant $tenant.tenantid 
                set-signinriskpolicy -tenant $tenant.tenantid
                set-inactiveaccounts -tenant $tenant.tenantid
                Set-MFAUsers -tenant $tenant.tenantid
                set-adminmfa -tenant $tenant.tenantid
            } 
            "LowImpact" {
                set-breakglassadmin -tenant $tenant.tenantid
                set-dlppolicy -tenant $tenant.tenantid
                set-oauthconsent -tenant $tenant.tenantid
                set-passwordexpire -tenant $tenant.tenantid
                set-sspr -tenant $tenant.tenantid
                set-irmdocs -tenant $tenant.tenantid
            }
            "MediumImpact" { 
                set-customerlockbox -tenant $tenant.tenantid
                set-userriskpolicy -tenant $tenant.tenantid 
                set-signinriskpolicy -tenant $tenant.tenantid
                set-inactiveaccounts -tenant $tenant.tenantid
                 
            }
            "HighImpact" {
                Set-MFAUsers -tenant $tenant.tenantid
                set-adminmfa -tenant $tenant.tenantid
            }

        }

    }
}