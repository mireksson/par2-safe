<#
PAR2 RECOVERY FILE ORGANIZER

- Traverses directories using same rules as PAR2 script
- Skips dot-directories (.git, .Music Projects, etc.)
- Moves all PAR2 recovery files into ".recovery" subdirectory
- Safe to re-run (idempotent)
- Does NOT touch data files
#>

param (
    [string]$RootDir = (Get-Location).Path
)

# Files to move
$RecoveryPatterns = @(
    "*.par2",
    "recovery.sha256"
)

function Move-RecoveryFiles {
    param ([string]$Dir)

    # ---- skip dot-directories ----
    if ((Split-Path $Dir -Leaf).StartsWith(".")) {
        return
    }

    if (-not (Test-Path $Dir)) {
        return
    }

    Push-Location $Dir

    $RecoveryFiles = Get-ChildItem -File -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -like "*.par2" -or $_.Name -eq "recovery.sha256"
        }

    if ($RecoveryFiles.Count -eq 0) {
        Pop-Location
        return
    }

    $RecoveryDir = Join-Path $Dir ".recovery"

    if (-not (Test-Path $RecoveryDir)) {
        New-Item -ItemType Directory -Path $RecoveryDir | Out-Null
    }

    foreach ($file in $RecoveryFiles) {
        $target = Join-Path $RecoveryDir $file.Name

        if (-not (Test-Path $target)) {
            Move-Item -Path $file.FullName -Destination $RecoveryDir
        }
    }

    Write-Host "Moved recovery files to:" $RecoveryDir

    Pop-Location
}

# =========================
# WALK DIRECTORIES
# =========================

Get-ChildItem -Directory -Recurse -Path $RootDir -ErrorAction SilentlyContinue |
Where-Object {
    -not $_.Name.StartsWith(".")
} |
ForEach-Object {
    Move-RecoveryFiles -Dir $_.FullName
}

Write-Host ""
Write-Host "Recovery file organization complete."
