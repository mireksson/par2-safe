param (
    [string]$RootDir = (Get-Location).Path
)

Write-Host "Fixing percent-encoded filenames"
Write-Host "Root: $RootDir"

# Windows illegal filename characters
$IllegalChars = '[\\/:*?"<>|]'

function Decode-PercentUtf8 {
    param ([string]$Name)

    try {
        return [System.Uri]::UnescapeDataString($Name)
    }
    catch {
        return $Name
    }
}

function Sanitize-FileName {
    param ([string]$Name)

    # Replace illegal characters with underscore
    return ($Name -replace $IllegalChars, "_")
}

# Walk tree safely, deepest-first
Get-ChildItem -Path $RootDir -Recurse -Force -ErrorAction SilentlyContinue |
    Sort-Object FullName -Descending |
    ForEach-Object {

        $Item = $_
        $OldName = $Item.Name

        # Only process names with percent encoding
        if ($OldName -notmatch "%[0-9A-Fa-f]{2}") {
            return
        }

        $Decoded = Decode-PercentUtf8 $OldName
        if ($Decoded -eq $OldName) {
            return
        }

        $Sanitized = Sanitize-FileName $Decoded
        if ($Sanitized -eq $OldName) {
            return
        }

        $NewPath = Join-Path $Item.DirectoryName $Sanitized

        if (Test-Path $NewPath) {
            Write-Host "SKIP (exists): $OldName"
            return
        }

        try {
            Rename-Item -LiteralPath $Item.FullName -NewName $Sanitized
            Write-Host "RENAMED:"
            Write-Host "  $OldName"
            Write-Host "  -> $Sanitized"
        }
        catch {
            Write-Host "FAILED:"
            Write-Host "  $OldName"
        }
    }

Write-Host "Filename normalization complete."
