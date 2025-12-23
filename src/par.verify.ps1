<#
PAR2 VERIFY SCRIPT – FINAL VERSION (MULTIPAR / par2j64.exe)

INVARIANT:
- Root directory is NEVER processed (used only as traversal anchor)
- Directories whose names begin with "." are NEVER processed
- If ANY path component starts with ".", the directory is skipped
- Files whose names begin with "." do NOT count as dataset files

CONTRACT RULE:
Header comments are authoritative contract text.
They must never be modified unless explicitly instructed.
#>

param (
    [string]$RootDir = (Get-Location).Path
)

$version = "v1.0.4 (2025-12-16 05:30)"
Write-Host "PAR Verify - $version"
Write-Host ""

# =========================
# CONFIG
# =========================

$ParExe = (Resolve-Path (Join-Path $PSScriptRoot "par2j64.exe")).Path
if (-not (Test-Path $ParExe)) {
    Write-Error "par2j64.exe not found."
    exit 2
}

$RecoveryDirName = ".recovery"
$ParBaseName     = "recovery"

$CorruptionFound = $false

# =========================
# LOGGING
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

function Write-Status {
    param (
        [string]$Message,
        [ConsoleColor]$Color
    )

    $ts   = Get-Date -Format "yyyy-MM-dd HH:mm"
    $text = "$ts $Message"

    Write-Host $text -ForegroundColor $Color
}

# =========================
# HARD INVARIANT  (PATCHED: IDENTICAL TO UPDATE)
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
# VERIFY ONE DIRECTORY
# =========================

function Invoke-ParVerify {
    param ([string]$Dir)

    if (Is-DotPath $Dir) { return }

    # PATCH: normalize directory identity exactly like UPDATE
    $Dir = (Get-Item -LiteralPath $Dir).FullName

    Push-Location -LiteralPath $Dir
    $Files = Get-ChildItem -File -ErrorAction SilentlyContinue |
        Where-Object { -not $_.Name.StartsWith('.') -and $_.Extension -ne '.par2' }
    Pop-Location

    if ($Files.Count -eq 0) { return }

    $RecoveryDir = Join-Path $Dir $RecoveryDirName
    $ParFile     = Join-Path $RecoveryDir "$ParBaseName.par2"

    if (-not (Test-Path -LiteralPath $ParFile)) {
        Write-Status "MISSING RECOVERY DATA: $Dir" Yellow
        return
    }

    Start-Verify-Spinner "VERIFY"

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
        $script:CorruptionFound = $true
    }
    else {
        Write-Status "OK: $Dir" Green
    }
}

# =========================
# WALK TREE (ORDERED)  (UNCHANGED)
# =========================

$AllDirs = Get-ChildItem -Directory -Recurse -Path $RootDir |
    Where-Object { -not (Is-DotPath $_.FullName) }

$WithoutRecovery = $AllDirs | Where-Object {
    -not (Test-Path (Join-Path $_.FullName $RecoveryDirName))
}

$WithRecovery = $AllDirs | Where-Object {
    Test-Path (Join-Path $_.FullName $RecoveryDirName)
}

$WithoutRecovery | ForEach-Object { Invoke-ParVerify $_.FullName }
$WithRecovery    | ForEach-Object { Invoke-ParVerify $_.FullName }

if ($CorruptionFound) { exit 1 } else { exit 0 }
