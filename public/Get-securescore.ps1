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
        $counter = 0
        do {
            $counter++
            if($counter -gt 10){
                Write-Host "Could not connect to SecureScore API for $($tenant.DefaultDomainName). Moving to next client."
                Break
            }
            $Scores = (Invoke-RestMethod -Uri 'https://graph.microsoft.com/beta/security/securescores?`$top=1' -Headers $Headers -Method Get -ContentType "application/json")
            $ScoreProfiles = (Invoke-RestMethod -Uri 'https://graph.microsoft.com/beta/security/secureScoreControlProfiles' -Headers $Headers -Method Get -ContentType "application/json").value
        } while ($null -eq $scores)

        [PSCustomObject]@{
            TenantName    = $($tenant.DefaultDomainName)
            TenantID      = $($tenant.Tenantid)
            Scores        = $scores.value | Select-Object -first 1
            ScoreProfiles = $ScoreProfiles
            Domains       = (Get-MsolDomain -TenantId $tenant.tenantid).name
            
        }
    }
}