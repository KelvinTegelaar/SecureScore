function set-BreakGlassAdmin {
    [Parameter(Mandatory = $true)]$tenant,
    [Parameter(Mandatory = $false)][switch]$confirmed
    if (!$script:confirmed) {
        Write-Warning "This will create a new 'BreakGlass' admin user to be used in cases of emergency" -WarningAction Inquire  
    } 
    if ($script:ExternallyResolved) {
        Set-ExternallyResolved -issue 'OneAdmin'
        break
    }
    write-host "Using $tenant"
    $username = "Breakglass-" + (Get-Random -Minimum 1000 -Maximum 3000) + '@' + (Get-MsolDomain -TenantId $tenant.TenantId | where-object { $_.IsInitial -eq $true } ).name
    New-MsolUser -TenantId $tenant.TenantId -UserPrincipalName  $username -DisplayName 'Breakglass admin account' -FirstName "Breakglass" -LastName "Account"
    Add-MsolRoleMember -TenantId $tenant.TenantId -RoleName "Company Administrator" -RoleMemberEmailAddress $username
}