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
    $script:ExternallyResolved = $ExternallyResolved
    write-host "Generating tokens for logon" -ForegroundColor Green
    try {
        $credential = New-Object System.Management.Automation.PSCredential($ApplicationId, ($ApplicationSecret | ConvertTo-SecureString -Force -AsPlainText))
        $aadGraphToken = New-PartnerAccessToken -ApplicationId $ApplicationId -Credential $credential -RefreshToken $refreshToken -Scopes 'https://graph.windows.net/.default' -ServicePrincipal 
        $graphToken = New-PartnerAccessToken -ApplicationId $ApplicationId -Credential $credential -RefreshToken $refreshToken -Scopes 'https://graph.microsoft.com/.default' -ServicePrincipal
    }
    catch {
        write-error "Generating tokens failed. $($_.Exception.Message)"
        continue
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
        continue
    }
    if ($AllTenants) { write-host "Found $($Tenants.count) tenants.." -ForegroundColor Green } 
    else { 
        write-host "Using single domain option." 
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
            "AdminMFAV2" { set-adminmfa }
            "DLPEnabled" { set-dlppolicy } 
            "IntegratedApps" { set-oauthconsent }
            "OneAdmin" { set-breakglassadmin } 
            "PWAgePolicyNew" { set-passwordexpire }
            "InactiveAccounts" { set-inactiveaccounts } 
            "SigninRiskPolicy" { set-signinriskpolicy } 
            "UserRiskPolicy" { set-userriskpolicy } 
            "MFARegistrationV2" { Set-MFAUsers } 
            "SelfServicePasswordReset" { set-sspr }
            "All" {
                set-breakglassadmin
                set-dlppolicy
                set-oauthconsent
                set-passwordexpire
                set-sspr
        
                set-userriskpolicy 
                set-signinriskpolicy
                set-inactiveaccounts
                Set-MFAUsers
                set-adminmfa
            } 
            "LowImpact" {
                set-breakglassadmin
                set-dlppolicy
                set-oauthconsent
                set-passwordexpire
                set-sspr
        
            }
            "MediumImpact" { 
                set-userriskpolicy 
                set-signinriskpolicy
                set-inactiveaccounts
                 
            }
            "HighImpact" {
                Set-MFAUsers
                set-adminmfa
            }

        }

    }
}