
param (
    [string]$SubscriptionID
)

# If subscription is explicitly provided, select the given subscription
if ($SubscriptionID) {
    Select-AzSubscription -SubscriptionId $SubscriptionID | Out-Null
}

# gather all key vaults from subscription
$KeyVaults = Get-AzKeyVault

$ExpiredSecrets = @()
$NearExpirationSecrets = @()
$NoExpireDateSetSecrets = @()

#check date which will notify about expiration
$ExpirationDate = (Get-Date (Get-Date).AddDays(20) -Format yyyyMMdd)
$CurrentDate = (Get-Date -Format yyyyMMdd)

# iterate across all key vaults in subscription
foreach ($KeyVault in $KeyVaults) {
    # gather all secrets in each key vault
    $SecretsArray = Get-AzKeyVaultSecret -VaultName $KeyVault.VaultName
    foreach ($secret in $SecretsArray) {
        # check if expiration date is set
        if ($secret.Expires) {
            $secretExpiration = Get-date $secret.Expires -Format yyyyMMdd
            # check if expiration date set on secret is before notify expiration date
            if ($ExpirationDate -gt $secretExpiration) {
                # check if secret did not expire yet but will expire soon
                if ($CurrentDate -lt $secretExpiration) {
                    $NearExpirationSecrets += New-Object PSObject -Property @{
                        Name           = $secret.Name;
                        Category       = 'SecretNearExpiration';
                        KeyVaultName   = $KeyVault.VaultName;
                        ExpirationDate = $secret.Expires;
                    }
                }
                # secret is already expired
                else {
                    $ExpiredSecrets += New-Object PSObject -Property @{
                        Name           = $secret.Name;
                        Category       = 'SecretExpired';
                        KeyVaultName   = $KeyVault.VaultName;
                        ExpirationDate = $secret.Expires;
                    }
                }
            }
            else {
                $NoExpireDateSetSecrets += New-Object PSObject -Property @{
                    Name         = $secret.Name;
                    Category     = 'SecretNoExpiryDate';
                    KeyVaultName = $KeyVault.VaultName;
                }
                # set to expiry date to 30 years from now :)
                $Expires = (Get-Date).AddYears(30).ToUniversalTime()
                Update-AzKeyVaultSecret -VaultName $KeyVault.VaultName -Name $secret.Name -Expires $Expires
            }
        }
    }
}

Write-Output "`nTotal number of expired secrets: $($ExpiredSecrets.Count)"
$ExpiredSecrets

Write-Output "`nTotal number of secrets near expiration: $($NearExpirationSecrets.Count)"
$NearExpirationSecrets

Write-Output "`nTotal number of secrets with no expiration date: $($NoExpireDateSetSecrets.Count)"
$NoExpireDateSetSecrets