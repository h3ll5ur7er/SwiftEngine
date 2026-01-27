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

function Coverage {
    Write-Host "==> Running tests with coverage..." -ForegroundColor Cyan
    swift test --enable-code-coverage
    
    $coveragePath = swift test --enable-code-coverage --show-codecov-path 2>$null
    if (-not (Test-Path $coveragePath)) {
        Write-Host "Coverage file not found at: $coveragePath" -ForegroundColor Red
        return
    }
    
    $json = Get-Content $coveragePath | ConvertFrom-Json
    $files = $json.data.files | Where-Object { $_.filename -like "*Sources\GameEngine*" }
    
    Write-Host ""
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host "                      CODE COVERAGE REPORT                              " -ForegroundColor Cyan
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Calculate totals
    $totalLines = 0
    $coveredLines = 0
    foreach ($f in $files) {
        $totalLines += $f.summary.lines.count
        $coveredLines += $f.summary.lines.covered
    }
    $overallPercent = 0
    if ($totalLines -gt 0) { 
        $overallPercent = 100 * $coveredLines / $totalLines 
    }
    
    $overallColor = "Yellow"
    if ($overallPercent -ge 50) { $overallColor = "Green" }
    Write-Host "  Overall: $([math]::Round($overallPercent, 1))% ($coveredLines/$totalLines lines)" -ForegroundColor $overallColor
    Write-Host ""
    
    # Well covered files (>50%)
    $wellCovered = $files | Where-Object { $_.summary.lines.percent -gt 50 } | Sort-Object { $_.summary.lines.percent } -Descending
    if ($wellCovered.Count -gt 0) {
        Write-Host "  [+] Well Covered (>50%):" -ForegroundColor Green
        foreach ($f in $wellCovered) {
            $name = $f.filename -replace '.*GameEngine\\', ''
            $pct = [math]::Round($f.summary.lines.percent, 1)
            $covered = $f.summary.lines.covered
            $total = $f.summary.lines.count
            $color = "Yellow"
            if ($pct -ge 80) { $color = "Green" }
            Write-Host "      $($pct.ToString().PadLeft(5))% ($($covered.ToString().PadLeft(4))/$($total.ToString().PadLeft(4))) $name" -ForegroundColor $color
        }
        Write-Host ""
    }
    
    # Partially covered files (1-50%)
    $partiallyCovered = $files | Where-Object { $_.summary.lines.percent -gt 0 -and $_.summary.lines.percent -le 50 } | Sort-Object { $_.summary.lines.percent } -Descending
    if ($partiallyCovered.Count -gt 0) {
        Write-Host "  [~] Partially Covered (1-50%):" -ForegroundColor Yellow
        foreach ($f in $partiallyCovered) {
            $name = $f.filename -replace '.*GameEngine\\', ''
            $pct = [math]::Round($f.summary.lines.percent, 1)
            $covered = $f.summary.lines.covered
            $total = $f.summary.lines.count
            Write-Host "      $($pct.ToString().PadLeft(5))% ($($covered.ToString().PadLeft(4))/$($total.ToString().PadLeft(4))) $name" -ForegroundColor Yellow
        }
        Write-Host ""
    }
    
    # Not covered files
    $notCovered = $files | Where-Object { $_.summary.lines.percent -eq 0 }
    if ($notCovered.Count -gt 0) {
        $notCoveredLines = ($notCovered | ForEach-Object { $_.summary.lines.count } | Measure-Object -Sum).Sum
        Write-Host "  [-] Not Covered (0%): $($notCovered.Count) files ($notCoveredLines lines)" -ForegroundColor Red
        Write-Host "      (UI, Platform, Runtime components - require integration tests)" -ForegroundColor DarkGray
        Write-Host ""
    }
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
    Write-Host "  build         - Build the application (swift build)"
    Write-Host "  build-release - Build the application in release mode (swift build -c release)"
    Write-Host "  run           - Run the application (swift run)"
    Write-Host "  run-release   - Run the application in release mode (swift run -c release)"
    Write-Host "  test          - Run tests (swift test)"
    Write-Host "  coverage      - Run tests with code coverage report"
    Write-Host "  clean         - Clean build artifacts (swift package clean)"
    Write-Host "  resolve       - Resolve package dependencies (swift package resolve)"
    Write-Host "  help          - Show this help"
    Write-Host ""
}

switch ($Target.ToLower()) {
    "build" { BuildDebug }
    "build-release" { BuildRelease }
    "run"   { Run }
    "run-release" { RunRelease }
    "test"  { Test }
    "coverage" { Coverage }
    "clean" { Clean }
    "resolve" { Resolve }
    "help"  { Help }
    default {
        Write-Host "Unknown target: $Target" -ForegroundColor Red
        Help
        exit 1
    }
}
