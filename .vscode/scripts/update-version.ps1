# Sync README/CURSEFORGE version strings from TOC Version
param(
    [string]$Root = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'

function Get-TocVersion([string]$tocPath) {
    if (-not (Test-Path $tocPath)) { throw "TOC not found: $tocPath" }
    $raw = Get-Content -Raw -LiteralPath $tocPath
    $m = [regex]::Match($raw, '##\s*Version:\s*(.+)')
    if (-not $m.Success) { throw "No Version line found in TOC" }
    return $m.Groups[1].Value.Trim()
}

function Update-File([string]$path, [scriptblock]$transform) {
    if (-not (Test-Path $path)) { Write-Host "Skip (missing): $path"; return }
    $orig = Get-Content -Raw -LiteralPath $path
    $new  = & $transform $orig
    if ($new -ne $orig) {
        Set-Content -LiteralPath $path -Value $new -NoNewline
        Write-Host "Updated: $path"
    } else {
        Write-Host "No change: $path"
    }
}

$toc = Join-Path $Root 'AdvancedHotkeyOverlaySystem.toc'
$version = Get-TocVersion $toc
Write-Host "TOC Version detected: $version"

# README.md: badge and highlights heading
$readme = Join-Path $Root 'README.md'
Update-File $readme {
    param($s)
    $s = [regex]::Replace($s, 'version-[0-9]+\.[0-9]+\.[0-9]+-cyan', "version-$version-cyan")
    $s = [regex]::Replace($s, '^(##\s+Version\s+)[0-9]+\.[0-9]+\.[0-9]+(\s+Highlights)\s*$', "$1$version$2", 'Multiline')
    return $s
}

# CURSEFORGE.md: recent updates header
$cf = Join-Path $Root 'CURSEFORGE.md'
Update-File $cf {
    param($s)
    $s = [regex]::Replace($s, '^##\s+Recent\s+Updates\s+\(v[0-9]+\.[0-9]+\.[0-9]+\)\s*$', "## Recent Updates (v$version)", 'Multiline')
    return $s
}

Write-Host "Done."
