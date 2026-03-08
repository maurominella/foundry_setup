# ============================================================
# Purge risorse Azure in stato soft-delete via REST API
# Compatibile con Az.Accounts < 2.5.0 (usa -Path invece di -Uri)
# ATTENZIONE: operazione irreversibile!
# ============================================================

Connect-AzAccount

$subscriptionId = "eca2eddb-0f0c-4351-a634-52751499eeea"
Set-AzContext -SubscriptionId $subscriptionId

$apiVersion_CogSvc  = "2023-05-01"
$apiVersion_KV      = "2023-07-01"
$apiVersion_APIM    = "2023-05-01-preview"
$apiVersion_AppConf = "2023-03-01"

# ============================================================
# 1. COGNITIVE SERVICES / AZURE AI FOUNDRY
# ============================================================
Write-Host "`n=== Cognitive Services / Azure AI ===" -ForegroundColor Cyan

# Recupera tutte le location disponibili per CognitiveServices
$locPath  = "/subscriptions/$subscriptionId/providers/Microsoft.CognitiveServices?api-version=2023-05-01"
$locResp  = (Invoke-AzRestMethod -Method GET -Path $locPath).Content | ConvertFrom-Json
$locations = ($locResp.resourceTypes | Where-Object { $_.resourceType -eq "accounts" }).locations

foreach ($location in $locations) {
    $locationNorm = $location.ToLower() -replace " ", ""
    $listPath = "/subscriptions/$subscriptionId/providers/Microsoft.CognitiveServices/locations/$locationNorm/deletedAccounts?api-version=$apiVersion_CogSvc"
    $listResp = Invoke-AzRestMethod -Method GET -Path $listPath
    if ($listResp.StatusCode -ne 200) { continue }
    $deletedAccounts = ($listResp.Content | ConvertFrom-Json).value
    if (-not $deletedAccounts) { continue }
    foreach ($account in $deletedAccounts) {
        $rgName      = ($account.id -split "/")[4]
        $accountName = $account.name
        Write-Host "Purging Cognitive Service: $accountName (RG: $rgName, Location: $locationNorm)" -ForegroundColor Yellow
        $purgePath = "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.CognitiveServices/accounts/$accountName/purge?api-version=$apiVersion_CogSvc"
        $purgeResp = Invoke-AzRestMethod -Method POST -Path $purgePath
        Write-Host "  -> Status: $($purgeResp.StatusCode)" -ForegroundColor Green
    }
}

# ============================================================
# 2. KEY VAULT
# ============================================================
Write-Host "`n=== Key Vaults ===" -ForegroundColor Cyan

$kvListPath  = "/subscriptions/$subscriptionId/providers/Microsoft.KeyVault/deletedVaults?api-version=$apiVersion_KV"
$kvListResp  = (Invoke-AzRestMethod -Method GET -Path $kvListPath).Content | ConvertFrom-Json
foreach ($kv in $kvListResp.value) {
    $kvName  = $kv.name
    $kvLoc   = $kv.properties.location
    Write-Host "Purging Key Vault: $kvName (Location: $kvLoc)" -ForegroundColor Yellow
    $purgePath = "/subscriptions/$subscriptionId/providers/Microsoft.KeyVault/locations/$kvLoc/deletedVaults/$kvName/purge?api-version=$apiVersion_KV"
    $purgeResp = Invoke-AzRestMethod -Method POST -Path $purgePath
    Write-Host "  -> Status: $($purgeResp.StatusCode)" -ForegroundColor Green
}

# ============================================================
# 3. MANAGED HSM
# ============================================================
Write-Host "`n=== Managed HSM ===" -ForegroundColor Cyan

$hsmListPath  = "/subscriptions/$subscriptionId/providers/Microsoft.KeyVault/deletedManagedHSMs?api-version=$apiVersion_KV"
$hsmListResp  = (Invoke-AzRestMethod -Method GET -Path $hsmListPath).Content | ConvertFrom-Json
foreach ($hsm in $hsmListResp.value) {
    $hsmName = $hsm.name
    $hsmLoc  = $hsm.properties.location
    Write-Host "Purging Managed HSM: $hsmName (Location: $hsmLoc)" -ForegroundColor Yellow
    $purgePath = "/subscriptions/$subscriptionId/providers/Microsoft.KeyVault/locations/$hsmLoc/deletedManagedHSMs/$hsmName/purge?api-version=$apiVersion_KV"
    $purgeResp = Invoke-AzRestMethod -Method POST -Path $purgePath
    Write-Host "  -> Status: $($purgeResp.StatusCode)" -ForegroundColor Green
}

# ============================================================
# 4. API MANAGEMENT
# ============================================================
Write-Host "`n=== API Management ===" -ForegroundColor Cyan

$apimListPath  = "/subscriptions/$subscriptionId/providers/Microsoft.ApiManagement/deletedservices?api-version=$apiVersion_APIM"
$apimListResp  = (Invoke-AzRestMethod -Method GET -Path $apimListPath).Content | ConvertFrom-Json
foreach ($apim in $apimListResp.value) {
    $apimName = $apim.name
    $apimLoc  = $apim.location
    Write-Host "Purging APIM: $apimName (Location: $apimLoc)" -ForegroundColor Yellow
    $purgePath = "/subscriptions/$subscriptionId/providers/Microsoft.ApiManagement/locations/$apimLoc/deletedservices/$apimName/purge?api-version=$apiVersion_APIM"
    $purgeResp = Invoke-AzRestMethod -Method DELETE -Path $purgePath
    Write-Host "  -> Status: $($purgeResp.StatusCode)" -ForegroundColor Green
}

# ============================================================
# 5. APP CONFIGURATION
# ============================================================
Write-Host "`n=== App Configuration ===" -ForegroundColor Cyan

$appconfListPath  = "/subscriptions/$subscriptionId/providers/Microsoft.AppConfiguration/deletedConfigurationStores?api-version=$apiVersion_AppConf"
$appconfListResp  = (Invoke-AzRestMethod -Method GET -Path $appconfListPath).Content | ConvertFrom-Json
foreach ($store in $appconfListResp.value) {
    $storeName = $store.name
    $storeLoc  = $store.properties.location
    Write-Host "Purging App Configuration: $storeName (Location: $storeLoc)" -ForegroundColor Yellow
    $purgePath = "/subscriptions/$subscriptionId/providers/Microsoft.AppConfiguration/locations/$storeLoc/deletedConfigurationStores/$storeName/purge?api-version=$apiVersion_AppConf"
    $purgeResp = Invoke-AzRestMethod -Method POST -Path $purgePath
    Write-Host "  -> Status: $($purgeResp.StatusCode)" -ForegroundColor Green
}

Write-Host "`n=== Purge completato! ===" -ForegroundColor Cyan