param(
    [switch]$SkipGoTest
)

$ErrorActionPreference = 'Stop'

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message"
}

function Fail {
    param([string]$Message)
    Write-Host "FAIL: $Message" -ForegroundColor Red
    exit 1
}

function Warn {
    param([string]$Message)
    Write-Host "WARN: $Message" -ForegroundColor Yellow
}

function Pass {
    param([string]$Message)
    Write-Host "OK: $Message" -ForegroundColor Green
}

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$iosProject = Join-Path $root 'ios\VKTurnProxyApp.xcodeproj\project.pbxproj'
$iosSourceRoot = Join-Path $root 'ios\VKTurnProxyApp'
$frameworkPath = Join-Path $root 'Mobile.xcframework'
$corePath = Join-Path $root '..\vk-turn-proxy-core'
$coreClientPath = Join-Path $corePath 'pkg\clientcore'

Write-Step 'Checking required files'

foreach ($path in @(
    (Join-Path $root 'go.mod'),
    (Join-Path $root 'mobile\ios\client.go'),
    $iosProject,
    $iosSourceRoot
)) {
    if (-not (Test-Path -LiteralPath $path)) {
        Fail "Missing required path: $path"
    }
}

Pass 'Required wrapper files exist'

Write-Step 'Checking Xcode project references'

$pbxproj = Get-Content -LiteralPath $iosProject -Raw
$swiftFiles = Get-ChildItem -LiteralPath $iosSourceRoot -Recurse -Filter '*.swift'

if ($swiftFiles.Count -eq 0) {
    Fail "No Swift files found under $iosSourceRoot"
}

$missingReferences = @()
foreach ($file in $swiftFiles) {
    if ($pbxproj -notmatch [regex]::Escape($file.Name)) {
        $missingReferences += $file.FullName
    }
}

if ($missingReferences.Count -gt 0) {
    Fail "Swift files missing from project.pbxproj:`n$($missingReferences -join "`n")"
}

if ($pbxproj -notmatch [regex]::Escape('Mobile.xcframework')) {
    Fail 'project.pbxproj does not reference Mobile.xcframework'
}

Pass "Xcode project references $($swiftFiles.Count) Swift files and Mobile.xcframework"

if (-not (Test-Path -LiteralPath $frameworkPath)) {
    Warn "Mobile.xcframework is not present yet. Build it on macOS before Xcode/device testing."
} else {
    Pass 'Mobile.xcframework exists'
}

Write-Step 'Checking core checkout'

if (-not (Test-Path -LiteralPath $corePath)) {
    Fail "Core checkout is missing: $corePath"
}

$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$coreGit = & git -C $corePath status --short --branch 2>&1
$coreGitExitCode = $LASTEXITCODE
$ErrorActionPreference = $previousErrorActionPreference

if ($coreGitExitCode -eq 0) {
    Write-Host $coreGit
} else {
    Warn "Could not read core git status. Git said: $coreGit"
    Warn "If needed, configure safe.directory for the core checkout or work in the real checkout."
}

$clientPackageNames = rg '^package ' $coreClientPath 2>$null
if ($LASTEXITCODE -ne 0) {
    Fail 'Could not inspect core pkg/clientcore package declarations'
}

if ($clientPackageNames -match 'package main') {
    Fail 'Core pkg/clientcore contains package main. The iOS wrapper needs package clientcore.'
} elseif ($clientPackageNames -match 'package clientcore') {
    Pass 'Core pkg/clientcore package declarations look importable'
} else {
    Warn 'Could not identify core pkg/clientcore package name from package declarations'
}

Write-Step 'Checking gomobile binding package'

$env:GOCACHE = Join-Path $root '.gocache'
$env:GOMODCACHE = Join-Path $root '.gomodcache'

if ($SkipGoTest) {
    Warn 'Skipping go test because -SkipGoTest was provided'
} else {
    go test ./...
    if ($LASTEXITCODE -ne 0) {
        Fail 'go test ./... failed'
    }
    Pass 'go test ./... passed'
}

Write-Step 'Checking optional Swift toolchain'

$swift = Get-Command swift -ErrorAction SilentlyContinue
if ($null -eq $swift) {
    Warn 'Swift CLI is not installed on this Windows machine. Full SwiftUI/Xcode validation still needs macOS.'
} else {
    swift --version
    Pass 'Swift CLI is available'
}

Write-Host ""
Pass 'Preflight finished'
