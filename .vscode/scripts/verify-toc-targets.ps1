$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$root = Split-Path -Parent $root

$expected = @{
    'AdvancedHotkeyOverlaySystem.toc' = @{
        'Interface' = '110107, 110200, 120000, 120001, 120005, 120007, 120100'
        'X-Compatible-With' = '120100'
        'X-Min-Interface' = '110107'
    }
    'AdvancedHotkeyOverlaySystem_Mainline.toc' = @{
        'Interface' = '110107, 110200, 120000, 120001, 120005, 120007, 120100'
        'X-Compatible-With' = '120100'
        'X-Min-Interface' = '110107'
    }
    'AdvancedHotkeyOverlaySystem_Mists.toc' = @{
        'Interface' = '50500, 50501, 50503'
        'X-Compatible-With' = '50503'
        'X-Min-Interface' = '50500'
    }
    'AdvancedHotkeyOverlaySystem_Vanilla.toc' = @{
        'Interface' = '11508'
        'X-Compatible-With' = '11508'
        'X-Min-Interface' = '11508'
    }
}

function Get-TocField([string]$path, [string]$field) {
    $escaped = [regex]::Escape($field)
    $match = Select-String -Path $path -Pattern "^## $escaped`:\s*(.+)$"
    if (-not $match) {
        throw "Missing '$field' in $path"
    }
    return $match.Matches[0].Groups[1].Value.Trim()
}

foreach ($file in $expected.Keys) {
    $path = Join-Path $root $file
    foreach ($field in $expected[$file].Keys) {
        $actual = Get-TocField $path $field
        $wanted = $expected[$file][$field]
        if ($actual -ne $wanted) {
            throw "$file has invalid '$field'. Expected '$wanted' but found '$actual'"
        }
    }
}

Write-Host 'TOC target metadata verified'
