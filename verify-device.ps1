[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Fail {
    param([string]$Message)
    Write-Host "[FAIL] $Message" -ForegroundColor Red
}

function Test-CommandExists {
    param([Parameter(Mandatory)][string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Invoke-Tool {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string[]]$Arguments
    )

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $FilePath
    $psi.Arguments = ($Arguments | ForEach-Object {
        if ($_ -match '[\s"]') {
            '"' + ($_ -replace '"', '\"') + '"'
        } else {
            $_
        }
    }) -join ' '
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    [void]$process.Start()
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()

    [pscustomobject]@{
        ExitCode = $process.ExitCode
        StdOut = $stdout
        StdErr = $stderr
        Combined = ($stdout + "`n" + $stderr)
    }
}

function Get-FastbootVar {
    param([Parameter(Mandatory)][string]$Name)

    $result = Invoke-Tool -FilePath "fastboot.exe" -Arguments @("getvar", $Name)
    $pattern = "(?im)^\s*$([regex]::Escape($Name))\s*:\s*(.+?)\s*$"
    $match = [regex]::Match($result.Combined, $pattern)
    if ($match.Success) {
        return $match.Groups[1].Value.Trim()
    }
    return $null
}

Write-Host ""
Write-Host "Poco F1 / beryllium Fastboot Verification" -ForegroundColor White
Write-Host "This script only checks the connected phone. It does not modify anything." -ForegroundColor Yellow
Write-Host ""

if (-not (Test-CommandExists -Name "fastboot.exe")) {
    Write-Fail "fastboot.exe was not found in PATH."
    Write-Host ""
    Write-Host "Install Android Platform Tools from:" -ForegroundColor Yellow
    Write-Host "https://developer.android.com/tools/releases/platform-tools"
    Write-Host "Then add the platform-tools folder to PATH and open a new PowerShell window."
    exit 1
}

Write-Ok "fastboot.exe found."

Write-Info "Checking fastboot devices..."
$devices = Invoke-Tool -FilePath "fastboot.exe" -Arguments @("devices")
if ($devices.ExitCode -ne 0) {
    Write-Fail "fastboot devices failed."
    Write-Host $devices.Combined
    exit 1
}

$deviceLines = $devices.StdOut -split "`r?`n" | Where-Object { $_.Trim() -match "\S+\s+fastboot" }
if (-not $deviceLines -or $deviceLines.Count -lt 1) {
    Write-Fail "No Fastboot device detected."
    Write-Host "Put the Poco F1 in Fastboot mode: power off, then hold Volume Down + Power."
    exit 1
}

Write-Ok "Fastboot device detected."

Write-Info "Reading product codename..."
$product = Get-FastbootVar -Name "product"
if ([string]::IsNullOrWhiteSpace($product)) {
    Write-Fail "Could not read fastboot product."
    exit 1
}

Write-Host "Product: $product"
if ($product -ne "beryllium") {
    Write-Fail "Product is not beryllium. Stop immediately. This project is only for Poco F1 / Pocophone F1."
    exit 1
}

Write-Ok "Product is beryllium."

Write-Info "Checking bootloader unlock state if available..."
$unlocked = Get-FastbootVar -Name "unlocked"
if ([string]::IsNullOrWhiteSpace($unlocked)) {
    Write-Warn "Could not read unlock state. Some Fastboot implementations do not report it."
} else {
    Write-Host "Unlocked: $unlocked"
    if ($unlocked -match "^(yes|true|1)$") {
        Write-Ok "Bootloader appears unlocked."
    } else {
        Write-Warn "Bootloader does not appear unlocked. Flashing recovery will probably fail."
    }
}

Write-Host ""
Write-Ok "Verification complete. No changes were made to the phone."
