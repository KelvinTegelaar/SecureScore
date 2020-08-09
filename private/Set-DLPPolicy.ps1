function Set-DLPPolicy {
    [Parameter(Mandatory = $true)]$tenant
    if (!$script:confirmed) {
        Write-Warning "This creates a new DLP policy named 'Default DLP' based on the 'Credit Card Info' template. This template will audit any creditcard data send over e-mail. Do you want to continue?" -WarningAction Inquire  
    } 
    $SCCToken = New-PartnerAccessToken -ApplicationId 'a0c73c16-a7e3-4564-9a95-2bdf47383716'-RefreshToken $ExchangeRefreshToken -Scopes 'https://outlook.office365.com/.default'
    $SCCTokenValue = ConvertTo-SecureString "Bearer $($SCCToken.AccessToken)" -AsPlainText -Force
    $SCCcredential = New-Object System.Management.Automation.PSCredential($upn, $SCCTokenValue)
    $SccSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://ps.compliance.protection.outlook.com/powershell-liveid?BasicAuthToOAuthConversion=true&DelegatedOrg=$($tenant.defaultdomainname)" -Credential $SCCcredential -AllowRedirection -Authentication Basic
    $null = import-PSsession $SccSession -disablenamechecking -allowclobber -CommandName New-DlpCompliancePolicy, New-DlpComplianceRule, Get-DlpSensitiveInformationType
    New-DlpCompliancePolicy -Name "Default DLP Policy" -Comment "Policy made by scripting" -SharePointLocation All -OneDriveLocation All -ExchangeLocation All -Mode Enable
    New-DlpComplianceRule -Name "Default DLP Policy" -Policy "Default DLP Policy" -ContentContainsSensitiveInformation @{Name = (Get-DlpSensitiveInformationType | Where-Object { $_.name -eq 'Credit Card Number' }).id ; minCount = "1" } -BlockAccess $false
    Remove-PSSession $SccSession
}