function Get-SecureScore {
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'AllTenants', Mandatory = $true)][switch]$AllTenants,
        [Parameter(Mandatory = $true)][string]$upn,
        [Parameter(Mandatory = $true)][string]$RefreshToken,
        [Parameter(Mandatory = $true)][string]$ApplicationId,
        [Parameter(Mandatory = $true)][string]$ApplicationSecret,
        [Parameter(ParameterSetName = 'TenantID', Mandatory = $true)][string]$TenantID
    )

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
    if ($AllTenants) { write-host "Found $($Tenants.count) tenants. Getting secure score for all." -ForegroundColor Green } 
    else { 
        write-host "Using $($tenants.DefaultDomainName)." 
    }
    foreach ($tenant in $tenants) {
        write-host "Getting secure score for $($tenant.DefaultDomainName)." -ForegroundColor Green
        try {
            $CustomerToken = New-PartnerAccessToken -ApplicationId $ApplicationId -Credential $credential -RefreshToken $refreshToken -Scopes 'https://graph.microsoft.com/.default' -ServicePrincipal -Tenantid $($tenant.Tenantid) -ErrorAction Stop
        }
        catch {
            write-error "Logging in to Azure AD failed for $($tenant.DefaultDomainName). $($_.Exception.Message)"
            continue
    
        }

        $headers = @{ "Authorization" = "Bearer $($CustomerToken.AccessToken)" }
        do {
            $Scores = (Invoke-RestMethod -Uri 'https://graph.microsoft.com/beta/security/securescores?`$top=1' -Headers $Headers -Method Get -ContentType "application/json").value | Select-Object -First 1

        } while ($null -eq $scores)

        [PSCustomObject]@{
            TenantName = $($tenant.DefaultDomainName)
            TenantID   = $($tenant.Tenantid)
            Scores     = $scores
            
        }
    }
}