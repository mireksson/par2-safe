<#
PAR2 BALANCED MODE – FINAL, HDD-OPTIMIZED, INTEGRITY-SAFE VERSION (MULTIPAR)

- Uses par2j64.exe (MultiPar)
- Uses file-list mode (/fu) with UTF-8 filenames
- No wildcards, no recursion, no argument limits
- Uses .recovery subdirectory ONLY
- Persistent padding file for small datasets
- Stable metadata hash (name + size)
- Block size ALWAYS multiple of 4

INTEGRITY RULE:
If a PAR exists, it MUST verify successfully before regeneration.
If verification fails, regeneration is FORBIDDEN.

PROCESSING ORDER RULE:
Directories WITHOUT a ".recovery" subdirectory are always processed first.
Directories WITH an existing ".recovery" subdirectory are processed afterward.

INVARIANT:
- Root directory is NEVER processed (used only as traversal anchor)
- Directories whose names begin with "." are NEVER processed
- If ANY path component starts with ".", the directory is skipped
- Files whose names begin with "." do NOT count as dataset files

All console output is prefixed with timestamp: yyyy-MM-dd HH:mm

CONTRACT RULE:
Header comments are authoritative contract text.
They must never be modified unless explicitly instructed.
#>

param (
    [string]$RootDir = (Get-Location).Path
)

$version = "v1.0.4 (2025-12-16 05:30)"
Write-Host "PAR Update - $version"
Write-Host ""

# =========================
# CONFIG
# =========================

$ParExe = (Resolve-Path (Join-Path $PSScriptRoot "par2j64.exe")).Path
if (-not (Test-Path $ParExe)) {
    Write-Error "par2j64.exe not found."
    exit 1
}

$RecoveryDirName = ".recovery"
$ParBaseName     = "recovery"
$HashFileName    = "recovery.sha256"
$Redundancy      = 0.20

$ErrorFound = $false

# =========================
# SPINNER
# =========================

$SpinnerFrames = @('|','/','-','\')
$SpinnerIndex  = 0

function Start-Verify-Spinner {
    param ([string]$Label)

    $ts = Get-Date -Format "yyyy-MM-dd HH:mm"
    $frame = $SpinnerFrames[$SpinnerIndex % $SpinnerFrames.Count]
    $script:SpinnerIndex++

    $line = "$ts $Label $frame"
    $width = $Host.UI.RawUI.WindowSize.Width
    if ($line.Length -gt ($width - 1)) {
        $line = $line.Substring(0, $width - 1)
    }

    Write-Host "`r$line" -NoNewline -ForegroundColor Yellow
}

function Stop-Verify-Spinner {
    $width = $Host.UI.RawUI.WindowSize.Width
    Write-Host "`r$(' ' * ($width - 1))`r" -NoNewline
}

# =========================
# LOGGING
# =========================

function Write-Status {
    param (
        [string]$Message,
        [ConsoleColor]$Color
    )

    $ts = Get-Date -Format "yyyy-MM-dd HH:mm"
    Write-Host "$ts $Message" -ForegroundColor $Color
}

# =========================
# HARD INVARIANT
# =========================

function Is-DotPath {
    param ([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) { return $true }

    foreach ($p in ($Path -split '[\\/]')) {
        if ($p.StartsWith(".")) { return $true }
    }
    return $false
}

# =========================
# HELPERS
# =========================

function Get-DataFiles {
    Get-ChildItem -File | Where-Object {
        -not $_.Name.StartsWith(".") -and
        $_.Extension -ne ".par2"
    }
}

function Get-Hash {
    param ($Files)

    $sb = New-Object Text.StringBuilder
    foreach ($f in ($Files | Sort-Object Name)) {
        $null = $sb.AppendLine("$($f.Name)|$($f.Length)")
    }

    $sha = [Security.Cryptography.SHA256]::Create()
    $bytes = [Text.Encoding]::UTF8.GetBytes($sb.ToString())
    $hashBytes = $sha.ComputeHash($bytes)

    ([BitConverter]::ToString($hashBytes)) -replace "-", ""
}

# =========================
# DYNAMIC PAR2 SIZING
# =========================

function Get-Par2Sizing {
    param (
        [Int64]$TotalSize,
        [Int64]$LargestFile
    )

    $BaseSize     = 1GB
    $MaxScaleSize = 1TB

    $BaseTargetBlocks = 800
    $MaxTargetBlocks  = 2400

    $BaseMinBlock = 2MB
    $MaxMinBlock  = 8MB

    $BaseMaxBlock = 8MB
    $MaxMaxBlock  = 64MB

    $ClampedSize = [Math]::Min(
        [Math]::Max($TotalSize, $BaseSize),
        $MaxScaleSize
    )

    $Scale = ($ClampedSize - $BaseSize) / ($MaxScaleSize - $BaseSize)

    $TargetDataBlocks = [Int64](
        $BaseTargetBlocks +
        ($MaxTargetBlocks - $BaseTargetBlocks) * $Scale
    )

    if ($TargetDataBlocks -gt 3000) { $TargetDataBlocks = 3000 }

    $MinBlockSize = [Int64](
        $BaseMinBlock +
        ($MaxMinBlock - $BaseMinBlock) * $Scale
    )

    $MaxBlockSize = [Int64](
        $BaseMaxBlock +
        ($MaxMaxBlock - $BaseMaxBlock) * $Scale
    )

    if ($MinBlockSize -lt 64KB) { $MinBlockSize = 64KB }
    if ($MaxBlockSize -gt 64MB) { $MaxBlockSize = 64MB }

    $RawBlockSize = [Int64][Math]::Ceiling($TotalSize / $TargetDataBlocks)
    $RawBlockSize -= ($RawBlockSize % 4)

    if ($LargestFile -lt 2GB) {
        $RawBlockSize = [Math]::Min($RawBlockSize, 4MB)
    }

    $BlockSize = [Math]::Max(
        $MinBlockSize,
        [Math]::Min($RawBlockSize, $MaxBlockSize)
    )

    if ($BlockSize -lt 64KB) { $BlockSize = 64KB }
    $BlockSize -= ($BlockSize % 4)

    return $BlockSize
}

# =========================
# PROCESS ONE DIRECTORY
# =========================

function Invoke-ParUpdate {
    param ([string]$Dir)

    if (Is-DotPath $Dir) { return }

    $Dir = (Get-Item -LiteralPath $Dir).FullName

    Push-Location -LiteralPath $Dir
    $Files = Get-DataFiles
    Pop-Location

    if ($Files.Count -eq 0) { return }

    $RecoveryDir = Join-Path $Dir $RecoveryDirName
    $ParFile     = Join-Path $RecoveryDir "$ParBaseName.par2"
    $HashPath    = Join-Path $RecoveryDir $HashFileName

    if (-not (Test-Path -LiteralPath $RecoveryDir)) {
        New-Item -ItemType Directory -Path $RecoveryDir -Force | Out-Null
    }

    if (Test-Path -LiteralPath $ParFile) {

        $job = Start-Job -ArgumentList $Dir, $ParExe, $ParFile -ScriptBlock {
            param ($Dir, $ParExe, $ParFile)

            Push-Location -LiteralPath $Dir
            & $ParExe v "/d$Dir" "$ParFile" *> $null
            Pop-Location

            return $LASTEXITCODE
        }

        while ($job.State -eq 'Running') {
            Start-Verify-Spinner "VERIFY"
            Start-Sleep -Milliseconds 120
        }

        $exitCode = Receive-Job $job
        Remove-Job $job
        Stop-Verify-Spinner

        if ($exitCode -ne 0) {
            Write-Status "VERIFY ERROR: $Dir" Red
            $script:ErrorFound = $true
            return
        }
    }

    $NewHash = Get-Hash $Files
    $OldHash = if (Test-Path -LiteralPath $HashPath) {
        (Get-Content -LiteralPath $HashPath | Out-String).Trim()
    }

    if ($NewHash -eq $OldHash -and (Test-Path -LiteralPath $ParFile)) {
        Write-Status "OK: $Dir" Green
        return
    }

    Get-ChildItem $RecoveryDir -Filter "$ParBaseName*.par2" -ErrorAction SilentlyContinue |
        Remove-Item -Force

    $TotalSize   = [Int64](($Files | Measure-Object Length -Sum).Sum)
    $LargestFile = [Int64](($Files | Measure-Object Length -Maximum).Maximum)

    $BlockSize = Get-Par2Sizing -TotalSize $TotalSize -LargestFile $LargestFile

    $FileListAbs = Join-Path $RecoveryDir "recovery.files.txt"

    [System.IO.File]::WriteAllLines(
        $FileListAbs,
        ($Files | Sort-Object Name | ForEach-Object { $_.Name }),
        (New-Object System.Text.UTF8Encoding($false))
    )

    Push-Location -LiteralPath $Dir
    & $ParExe c `
        "/fu" `
        "/d$Dir" `
        "/ss$BlockSize" `
        "/rn$([Math]::Max(1,[Math]::Ceiling(($TotalSize / $BlockSize) * $Redundancy)))" `
        "$ParFile" `
        "$FileListAbs"
    Pop-Location

    if ($LASTEXITCODE -ne 0) {
        Write-Status "ERROR: $Dir" Red
        $script:ErrorFound = $true
        return
    }

    $NewHash | Set-Content -NoNewline -Encoding UTF8 -LiteralPath $HashPath
    Write-Status "UPDATED: $Dir" Cyan
}

# =========================
# WALK TREE (ORDERED)
# =========================

$AllDirs = Get-ChildItem -Directory -Recurse -Path $RootDir |
    Where-Object { -not (Is-DotPath $_.FullName) }

$WithoutRecovery = $AllDirs | Where-Object {
    -not (Test-Path (Join-Path $_.FullName $RecoveryDirName))
}

$WithRecovery = $AllDirs | Where-Object {
    Test-Path (Join-Path $_.FullName $RecoveryDirName)
}

$WithoutRecovery | ForEach-Object { Invoke-ParUpdate $_.FullName }
$WithRecovery    | ForEach-Object { Invoke-ParUpdate $_.FullName }

if ($ErrorFound) { exit 1 } else { exit 0 }
