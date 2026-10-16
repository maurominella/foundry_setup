# ============================================================
# Purge diretto di aifv2-01-std-foundry
# Usa l'ID esatto restituito dalla lista deletedAccounts
# ============================================================

$subscriptionId = "eca2eddb-0f0c-4351-a634-52751499eeea"
$accountName    = "aifv2-01-std-foundry"
$apiVersion     = "2023-05-01"

Set-AzContext -SubscriptionId $subscriptionId

# Step 1: Lista globale deletedAccounts
Write-Host "`n--- Step 1: Lista globale deletedAccounts ---" -ForegroundColor Cyan
$globalListPath = "/subscriptions/$subscriptionId/providers/Microsoft.CognitiveServices/deletedAccounts?api-version=$apiVersion"
$globalListResp = Invoke-AzRestMethod -Method GET -Path $globalListPath
$globalListContent = $globalListResp.Content | ConvertFrom-Json
$foundAccount = $globalListContent.value | Where-Object { $_.name -eq $accountName }

if (-not $foundAccount) {
    Write-Host "  RISORSA NON TROVATA." -ForegroundColor Red
    exit
}

# Mostra l'ID completo esatto
Write-Host "  -> ID completo: $($foundAccount.id)" -ForegroundColor Green
Write-Host "  -> Location:    $($foundAccount.location)" -ForegroundColor Green

# Step 2: Estrai la location dall'ID (formato: .../locations/{location}/resourceGroups/...)
$idParts  = $foundAccount.id -split "/"
# L'ID ha questo formato:
# /subscriptions/{sub}/providers/Microsoft.CognitiveServices/locations/{loc}/resourceGroups/{rg}/deletedAccounts/{name}
# [0]=""  [1]="subscriptions"  [2]={sub}  [3]="providers"  [4]="Microsoft.CognitiveServices"
# [5]="locations"  [6]={location}  [7]="resourceGroups"  [8]={rg}  [9]="deletedAccounts"  [10]={name}
$location = $idParts[6]
$rgName   = $idParts[8]
Write-Host "  -> Location (da ID): $location" -ForegroundColor Green
Write-Host "  -> ResourceGroup (da ID): $rgName" -ForegroundColor Green

# Step 3: Purge - il path corretto è l'ID stesso + DELETE
# L'endpoint DELETE per purge è esattamente l'ID della deletedAccount
$purgePath = "/subscriptions/$subscriptionId/providers/Microsoft.CognitiveServices/locations/$location/resourceGroups/$rgName/deletedAccounts/$accountName`?api-version=$apiVersion"
Write-Host "`n--- Step 3: Esecuzione purge ---" -ForegroundColor Cyan
Write-Host "  -> PATH: $purgePath"
$purgeResp = Invoke-AzRestMethod -Method DELETE -Path $purgePath
Write-Host "  -> Status Code: $($purgeResp.StatusCode)"
Write-Host "  -> Response:    $($purgeResp.Content)"

if ($purgeResp.StatusCode -in @(200, 202, 204)) {
    Write-Host "`n  PURGE RIUSCITO! Puoi ora ricreare la risorsa." -ForegroundColor Green
} else {
    Write-Host "`n  PURGE FALLITO." -ForegroundColor Red
}