param(
  [string]$Root = "."
)

$ErrorActionPreference = 'Stop'

# Resolve absolute path for reliability
$rootPath = Resolve-Path -LiteralPath $Root

# Gather Lua files, excluding noisy vendor dirs
$files = Get-ChildItem -LiteralPath $rootPath -Recurse -File -Include *.lua |
  Where-Object { $_.FullName -notmatch "[\/]Libs[\/]LibDeflate[\/]" }

if (-not $files -or $files.Count -eq 0) {
  Write-Host "No Lua files found."
  exit 0
}

# Detect a Lua compiler/interpreter. Distro packages install versioned names
# (luac5.1 on Ubuntu), so accept those as well as the plain binary.
$luac = Get-Command luac, luac5.4, luac5.3, luac5.1 -ErrorAction SilentlyContinue | Select-Object -First 1
$lua = Get-Command lua, lua5.4, lua5.3, lua5.1 -ErrorAction SilentlyContinue | Select-Object -First 1
$useLuac = $null -ne $luac

if (-not $useLuac -and $null -eq $lua) {
  Write-Host "Neither 'luac' nor 'lua' found in PATH. Install Lua or adjust PATH."
  exit 1
}

$failed = $false

foreach ($f in $files) {
  # Native tools report syntax errors through the exit code rather than as
  # PowerShell exceptions, so check $LASTEXITCODE instead of using try/catch.
  if ($useLuac) {
    $output = & $luac.Path -p -- "$($f.FullName)" 2>&1
  } else {
    $output = & $lua.Path -e "assert(loadfile([[$($f.FullName)]]))" 2>&1
  }

  if ($LASTEXITCODE -ne 0) {
    Write-Host "Syntax error in $($f.FullName)"
    if ($output) { Write-Host (($output | Out-String).Trim()) }
    $failed = $true
  }
}

if ($failed) { exit 1 } else { Write-Host "Lua syntax OK"; exit 0 }
