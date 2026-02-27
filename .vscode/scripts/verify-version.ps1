$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$root = Split-Path -Parent $root

function Get-TocVersion([string]$path) {
    $match = Select-String -Path $path -Pattern '^## Version:\s*(.+)$'
    if (-not $match) {
        throw "Missing version in $path"
    }
    return $match.Matches[0].Groups[1].Value.Trim()
}

$tocFiles = @(
    'AdvancedHotkeyOverlaySystem.toc',
    'AdvancedHotkeyOverlaySystem_Mainline.toc',
    'AdvancedHotkeyOverlaySystem_Mists.toc',
    'AdvancedHotkeyOverlaySystem_Vanilla.toc'
) | ForEach-Object { Join-Path $root $_ }

$versions = @{}
foreach ($toc in $tocFiles) {
    $versions[$toc] = Get-TocVersion $toc
}

$uniqueVersions = @($versions.Values | Sort-Object -Unique)
if ($uniqueVersions.Count -ne 1) {
    $details = $versions.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" }
    throw "TOC version mismatch:`n$($details -join "`n")"
}

$version = [string]$uniqueVersions[0]
$readme = Get-Content -Raw -Path (Join-Path $root 'README.md')
$curseforge = Get-Content -Raw -Path (Join-Path $root 'CURSEFORGE.md')
$changelog = Get-Content -Raw -Path (Join-Path $root 'CHANGELOG.md')

if ($readme -notmatch [regex]::Escape("version-$version-cyan")) {
    throw "README badge is not synced to version $version"
}

if ($readme -notmatch [regex]::Escape("## Version $version Highlights")) {
    throw "README highlights heading is not synced to version $version"
}

if ($curseforge -notmatch [regex]::Escape("## Recent Updates (v$version)")) {
    throw "CURSEFORGE.md recent updates heading is not synced to version $version"
}

if ($changelog -notmatch "(?m)^## \[$([regex]::Escape($version))\] - ") {
    throw "CHANGELOG.md is missing an entry for version $version"
}

Write-Host "Version metadata verified for $version"
