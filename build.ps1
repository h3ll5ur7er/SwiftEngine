param(
    [string]$Target = "help"
)

$cwd = Get-Location

# Clear any existing VS environment variables that might point to VS 2026
$env:VSINSTALLDIR = $null
$env:VCToolsInstallDir = $null
$env:VCToolsVersion = $null
$env:VCINSTALLDIR = $null
$env:INCLUDE = $null
$env:LIB = $null
$env:LIBPATH = $null

# Enter VS 2022 Developer Shell
Import-Module "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
Enter-VsDevShell e02346ed -SkipAutomaticLocation -DevCmdArguments "-arch=x64 -host_arch=x64"
Set-Location $cwd

function Run {
    Write-Host "==> Running application..." -ForegroundColor Cyan
    swift run Game
}
function RunRelease {
    Write-Host "==> Building application..." -ForegroundColor Cyan
    swift run -c release Game
}
function BuildRelease {
    Write-Host "==> Building application..." -ForegroundColor Cyan
    swift build -c release
}
function BuildDebug {
    Write-Host "==> Building application..." -ForegroundColor Cyan
    swift build
}

function Test {
    Write-Host "==> Running tests..." -ForegroundColor Cyan
    swift test
}

function Clean {
    Write-Host "==> Cleaning..." -ForegroundColor Cyan
    swift package clean
}

function Resolve {
    Write-Host "==> Resolving dependencies..." -ForegroundColor Cyan
    swift package resolve
}

function Help {
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  ./build.ps1 <target>"
    Write-Host ""
    Write-Host "Available targets:" -ForegroundColor Yellow
    Write-Host "  build   - Build the application (swift build)"
    Write-Host "  build-release - Build the application in release mode (swift build -c release)"
    Write-Host "  run     - Run the application (swift run)"
    Write-Host "  run-release - Run the application in release mode (swift run -c release)"
    Write-Host "  test    - Run tests (swift test)"
    Write-Host "  clean   - Clean build artifacts (swift package clean)"
    Write-Host "  resolve - Resolve package dependencies (swift package resolve)"
    Write-Host "  help    - Show this help"
    Write-Host ""
}

switch ($Target.ToLower()) {
    "build" { BuildDebug }
    "build-release" { BuildRelease }
    "run"   { Run }
    "run-release" { RunRelease }
    "test"  { Test }
    "clean" { Clean }
    "resolve" { Resolve }
    "help"  { Help }
    default {
        Write-Host "Unknown target: $Target" -ForegroundColor Red
        Help
        exit 1
    }
}
