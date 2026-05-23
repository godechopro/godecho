# God Echo Master Builder: Auto-Sorter & Checksum Generator
$ErrorActionPreference = "Stop"
$audioDir = ".\"
$outputFile = "echo-manifest.json"

Write-Host "Starting God Echo Master Builder..." -ForegroundColor Cyan

# ---------------------------------------------------------
# PHASE 1: THE AUTO-SORTER
# ---------------------------------------------------------
Write-Host "`n[Phase 1] Sorting daily echoes..." -ForegroundColor Yellow
$foldersCreated = 0
$filesMoved = 0

for ($day = 130; $day -le 365; $day++) {
    $folderName = "echoDay$day"
    $folderPath = Join-Path $audioDir $folderName
    $folderExists = $false

    for ($q = 1; $q -le 3; $q++) {
        $fileName = "echoDay$day-$q.mp3"
        $sourcePath = Join-Path $audioDir $fileName
        $destPath = Join-Path $folderPath $fileName

        if (Test-Path $sourcePath) {
            if (-not $folderExists -and -not (Test-Path $folderPath)) {
                New-Item -ItemType Directory -Path $folderPath | Out-Null
                $foldersCreated++
                $folderExists = $true
            }
            Move-Item -Path $sourcePath -Destination $destPath
            $filesMoved++
        }
    }
}
Write-Host "Created $foldersCreated folders and moved $filesMoved files." -ForegroundColor Green

# ---------------------------------------------------------
# PHASE 2: THE INTEGRITY MANIFEST (SHA-256)
# ---------------------------------------------------------
Write-Host "`n[Phase 2] Generating SHA-256 Checksums..." -ForegroundColor Yellow
$manifest = [ordered]@{}

function Get-AudioHash ($path) {
    if (Test-Path $path) {
        # Generate SHA256 and convert to lowercase hex string to match JS format
        return (Get-FileHash -Path $path -Algorithm SHA256).Hash.ToLower()
    }
    return $null
}

# 1. Angel Voices
$angelFiles = @(
    "angelPrep01.mp3", "angelPrep02.mp3", "angelPrep03.mp3",
    "angelQuote01.mp3", "angelQuote02.mp3", "angelQuote03.mp3"
)

Write-Host "Hashing Angel voices..."
foreach ($file in $angelFiles) {
    $fullPath = Join-Path $audioDir $file
    $hash = Get-AudioHash $fullPath
    if ($hash) {
        $manifest[$file] = $hash
        Write-Host "  Verified: $file"
    }
}

# 2. Daily Echoes
Write-Host "Hashing Daily Echoes..."
for ($day = 130; $day -le 365; $day++) {
    $folderName = "echoDay$day"
    for ($q = 1; $q -le 3; $q++) {
        $fileName = "echoDay$day-$q.mp3"
        $relativePath = "$folderName/$fileName"
        $fullPath = Join-Path $audioDir $relativePath
        
        $hash = Get-AudioHash $fullPath
        if ($hash) {
            $manifest[$relativePath] = $hash
        }
    }
}

# 3. Output JSON
$finalOutput = [ordered]@{ "hashes" = $manifest }
$jsonContent = $finalOutput | ConvertTo-Json -Depth 3

Set-Content -Path (Join-Path $audioDir $outputFile) -Value $jsonContent -Encoding UTF8
Write-Host "`nSuccess! Generated manifest for $($manifest.Count) files." -ForegroundColor Green
Write-Host "Saved to: $outputFile" -ForegroundColor Green

Write-Host "`nPress any key to exit..."
$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null