$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$root = Split-Path -Parent $root
$path = Join-Path $root 'CHANGELOG.md'
$content = Get-Content -Raw -Path $path

$matches = [regex]::Matches($content, '(?m)^## \[(\d+\.\d+\.\d+)\] - ')
if ($matches.Count -eq 0) {
    throw 'No semantic version headings found in CHANGELOG.md'
}

$versions = @()
foreach ($match in $matches) {
    $versions += [version]$match.Groups[1].Value
}

for ($i = 1; $i -lt $versions.Count; $i++) {
    if ($versions[$i - 1] -lt $versions[$i]) {
        throw "CHANGELOG.md is out of order near $($versions[$i - 1]) and $($versions[$i])"
    }
}

Write-Host "Changelog order verified"
