param(
    [string]$Destination = (Join-Path $PSScriptRoot 'data/raw'),
    [switch]$UseExistingArchive
)
$ErrorActionPreference = 'Stop'
$sourceUrl = 'https://archive.ics.uci.edu/static/public/17/breast+cancer+wisconsin+diagnostic.zip'
New-Item -ItemType Directory -Force -Path $Destination | Out-Null
$archivePath = Join-Path $Destination 'wdbc.zip'
if (-not $UseExistingArchive) {
    Invoke-WebRequest -Uri $sourceUrl -OutFile $archivePath
}
if (-not (Test-Path -LiteralPath $archivePath)) { throw 'Source archive is missing.' }
Expand-Archive -LiteralPath $archivePath -DestinationPath $Destination -Force
$dataPath = Join-Path $Destination 'wdbc.data'
$rawLines = @(Get-Content -LiteralPath $dataPath)
$records = @($rawLines | ForEach-Object { ,($_ -split ',') })
if ($records.Count -eq 0) { throw 'The downloaded data are empty.' }
$audit = [ordered]@{
    source = $sourceUrl
    checked_at_utc = [DateTime]::UtcNow.ToString('o')
    sha256 = (Get-FileHash -LiteralPath $dataPath -Algorithm SHA256).Hash
    rows = $records.Count
    column_counts = @($records | ForEach-Object { $_.Count } | Sort-Object -Unique)
    labels = @($records | Group-Object { $_[1] } | ForEach-Object { @{label=$_.Name; count=$_.Count} })
    unique_ids = @($records | ForEach-Object { $_[0] } | Sort-Object -Unique).Count
    duplicate_rows = $rawLines.Count - @($rawLines | Sort-Object -Unique).Count
    missing_cells = 0
    invalid_numeric_cells = 0
}
foreach ($record in $records) {
    if ($record.Count -ne 32) { throw 'Unexpected column count.' }
    if ($record[1] -notin @('M', 'B')) { throw 'Unexpected diagnosis label.' }
    foreach ($value in $record[2..31]) {
        if ([string]::IsNullOrWhiteSpace($value) -or $value -eq '?') { $audit.missing_cells++ }
        $parsedNumber = 0.0
        $parsed = [double]::TryParse($value, [Globalization.NumberStyles]::Float,
            [Globalization.CultureInfo]::InvariantCulture, [ref]$parsedNumber)
        if (-not $parsed -or [double]::IsNaN($parsedNumber) -or [double]::IsInfinity($parsedNumber)) {
            $audit.invalid_numeric_cells++
        }
    }
}
$auditJson = $audit | ConvertTo-Json -Depth 5
$auditJson | Set-Content -LiteralPath (Join-Path $Destination 'data-audit.json') -Encoding utf8
$auditJson
if ($audit.missing_cells -gt 0 -or $audit.invalid_numeric_cells -gt 0) {
    throw 'Data validation failed; inspect data-audit.json.'
}
