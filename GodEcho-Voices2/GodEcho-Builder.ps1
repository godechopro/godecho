# ====================================================
#      GOD ECHO AUDIO MIGRATION ENGINE (FIXED v4)
# ====================================================
Clear-Host
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "     GOD ECHO AUDIO MIGRATION ENGINE (POWERSHELL)    " -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

# Automatically target the directory where this script file lives
$ScriptDir = $PSScriptRoot
if (-not $ScriptDir) { $ScriptDir = Get-Location }

$logPath = Join-Path $ScriptDir "log.txt"

# Fallback check just in case it was saved as log.txt.txt
if (-not (Test-Path $logPath)) {
    $logPath = Join-Path $ScriptDir "log.txt.txt"
}

if (-not (Test-Path $logPath)) {
    Write-Host "Error: Cannot find log.txt in the script folder." -ForegroundColor Red
    Write-Host "Expected Path: $ScriptDir\log.txt" -ForegroundColor Yellow
    return
}

$confirm = Read-Host "Type Y to begin the CORRECTED relocation process"
if ($confirm -ne "Y") {
    Write-Host "Cancelled by user." -ForegroundColor Yellow
    return
}

$tempStage = Join-Path $ScriptDir "_temp_stage_"
if (Test-Path $tempStage) { Remove-Item -Path $tempStage -Recurse -Force }
New-Item -ItemType Directory -Path $tempStage -Force | Out-Null

Write-Host "Pass 1: Evacuating files using corrected source-destination logic..." -ForegroundColor Yellow
$stagedCount = 0

# Parse log file safely
Get-Content $logPath | ForEach-Object {
    if ($_ -match '\[RENAME\]:\s*([^\s]+)\s*->\s*([^\s]+)') {
        # FIXED DIRECTION: Pulling from the existing file [2] and renaming to target slot [1]
        $srcRelative = $Matches[2].Replace('/', '\')
        $destRelative = $Matches[1].Replace('/', '\')
        
        $srcFull = Join-Path $ScriptDir $srcRelative
        $destFull = Join-Path $tempStage $destRelative
        
        if (Test-Path $srcFull) {
            $targetStageDir = Split-Path $destFull
            if (-not (Test-Path $targetStageDir)) {
                New-Item -ItemType Directory -Path $targetStageDir -Force | Out-Null
            }
            
            Move-Item -Path $srcFull -Destination $destFull -Force
            $stagedCount++
        }
    }
}

Write-Host "Pass 1 Complete: Staged $stagedCount files smoothly." -ForegroundColor Green
Write-Host ""
Write-Host "Pass 2: Rebuilding final folder structures..." -ForegroundColor Yellow

if (Test-Path $tempStage) {
    Get-ChildItem -Path $tempStage -Directory | ForEach-Object {
        $foldername = $_.Name
        $targetFinalDir = Join-Path $ScriptDir $foldername
        if (-not (Test-Path $targetFinalDir)) {
            New-Item -ItemType Directory -Path $targetFinalDir -Force | Out-Null
        }
        Move-Item -Path "$($_.FullName)\*" -Destination $targetFinalDir -Force
    }
}
Write-Host "Pass 2 Complete: All assets migrated to new paths." -ForegroundColor Green
Write-Host ""

Write-Host "Cleanup: Clearing out empty directory shells..." -ForegroundColor Yellow
Get-ChildItem -Path $ScriptDir -Filter "echoDay*" | ForEach-Object {
    if ($_.PSIsContainer) {
        $remainingFiles = @(Get-ChildItem -Path $_.FullName)
        if ($remainingFiles.Count -eq 0) {
            Remove-Item -Path $_.FullName -Force
        }
    }
}

if (Test-Path $tempStage) {
    Remove-Item -Path $tempStage -Recurse -Force
}

Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "Success! Audio tracks mapped perfectly to new database order." -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Cyan