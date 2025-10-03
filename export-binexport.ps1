# Paths
$GHIDRA       = "C:\Users\BOS6LB\Desktop\ghidra_11.0.3_PUBLIC"
$DATASET_ROOT = "C:\Users\BOS6LB\OneDrive - Bosch Group\thesis-dataset-unstripped\dataset_opt0"

# Temp project parent
$ProjParent = Join-Path $env:TEMP "gh_proj"
New-Item -ItemType Directory -Force -Path $ProjParent | Out-Null

function Export-One {
    param([string]$BinPath)

    $OutPath = "$BinPath.BinExport"
    if (Test-Path -LiteralPath $OutPath) {
        Write-Host "Skip (exists): $OutPath"
        return
    }

    Write-Host "Exporting: $BinPath"
    $ProjDir = New-Item -ItemType Directory -Force -Path (Join-Path $ProjParent ("proj." + [guid]::NewGuid().ToString("N")))
    $LogPath = Join-Path $ProjDir.FullName "headless.log"

    & "$GHIDRA\support\analyzeHeadless.bat" `
        "$($ProjDir.FullName)" proj `
        -import "$BinPath" `
        -scriptPath "$HOME\ghidra_scripts" `
        -postScript ExportBinExport.py "$OutPath" `
        -deleteProject `
        *> "$LogPath"

    if (Test-Path -LiteralPath $OutPath) {
        Write-Host "OK: $OutPath"
        Remove-Item -Recurse -Force -LiteralPath $ProjDir.FullName -ErrorAction SilentlyContinue
    } else {
        Write-Warning "Missing .BinExport for $BinPath. See log: $LogPath"
    }
}

# Process every file except existing .BinExport outputs
Get-ChildItem -Path $DATASET_ROOT -Recurse -File |
  Where-Object { $_.Extension -ne ".BinExport" } |
  ForEach-Object { Export-One -BinPath $_.FullName }
