[CmdletBinding()]
param(
    [string]$DownloadsDir = ".\downloads",
    [switch]$DownloadPlatformTools,
    [switch]$SkipLineage
)

$ErrorActionPreference = "Stop"

$OfficialStaticBuildList = "https://download-static.lineageos.org/beryllium"
$OfficialPlatformToolsZip = "https://dl.google.com/android/repository/platform-tools-latest-windows.zip"

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

function Resolve-ProjectPath {
    param([Parameter(Mandatory)][string]$Path)
    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }
    return [System.IO.Path]::GetFullPath((Join-Path -Path (Get-Location) -ChildPath $Path))
}

function Save-Url {
    param(
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][string]$OutputPath
    )

    if (Test-Path -LiteralPath $OutputPath) {
        $existing = Get-Item -LiteralPath $OutputPath
        if ($existing.Length -gt 0) {
            Write-Ok "Already downloaded: $OutputPath"
            return
        }
    }

    Write-Info "Downloading: $Url"
    Invoke-WebRequest -Uri $Url -OutFile $OutputPath -UseBasicParsing
    $downloaded = Get-Item -LiteralPath $OutputPath
    if ($downloaded.Length -le 0) {
        throw "Downloaded file is empty: $OutputPath"
    }
    Write-Ok "Saved: $OutputPath ($($downloaded.Length) bytes)"
}

function Get-Sha256Text {
    param([Parameter(Mandatory)][string]$Url)
    return ((Invoke-WebRequest -Uri "$Url?sha256" -UseBasicParsing).Content.Trim() -split "\s+")[0].ToLowerInvariant()
}

function Assert-Sha256 {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Expected
    )

    $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
    if ($actual -ne $Expected.ToLowerInvariant()) {
        throw "SHA-256 mismatch for $Path`nExpected: $Expected`nActual:   $actual"
    }
    Write-Ok "SHA-256 verified: $Path"
}

function Get-LatestLineageFiles {
    Write-Info "Reading official LineageOS build list: $OfficialStaticBuildList"
    $html = (Invoke-WebRequest -Uri $OfficialStaticBuildList -UseBasicParsing).Content
    $urls = ([regex]::Matches($html, 'https://[^"''<> ]+')) | ForEach-Object { $_.Value }

    $lineageUrl = $urls |
        Where-Object { $_ -match '/full/beryllium/\d{8}/lineage-[^/]+-beryllium-signed\.zip$' } |
        Select-Object -First 1

    if (-not $lineageUrl) {
        throw "Could not find a beryllium LineageOS signed zip on the official static build list."
    }

    $buildDate = [regex]::Match($lineageUrl, '/full/beryllium/(\d{8})/').Groups[1].Value
    $recoveryUrl = $urls |
        Where-Object { $_ -eq "https://mirrorbits.lineageos.org/full/beryllium/$buildDate/recovery.img" } |
        Select-Object -First 1

    if (-not $recoveryUrl) {
        throw "Could not find matching recovery.img for build date $buildDate."
    }

    [pscustomobject]@{
        BuildDate = $buildDate
        LineageUrl = $lineageUrl
        RecoveryUrl = $recoveryUrl
    }
}

$downloadsPath = Resolve-ProjectPath $DownloadsDir
New-Item -ItemType Directory -Force -Path $downloadsPath | Out-Null

Write-Host ""
Write-Host "Poco F1 required file downloader" -ForegroundColor Cyan
Write-Host "This downloads from official sources and verifies LineageOS SHA-256 checksums." -ForegroundColor Cyan
Write-Host ""

if (-not $SkipLineage) {
    $latest = Get-LatestLineageFiles
    Write-Ok "Latest official beryllium build date: $($latest.BuildDate)"

    $lineageName = [System.IO.Path]::GetFileName($latest.LineageUrl)
    $lineagePath = Join-Path -Path $downloadsPath -ChildPath $lineageName
    $recoveryPath = Join-Path -Path $downloadsPath -ChildPath "recovery-$($latest.BuildDate)-beryllium.img"

    Save-Url -Url $latest.LineageUrl -OutputPath $lineagePath
    Save-Url -Url $latest.RecoveryUrl -OutputPath $recoveryPath

    $lineageSha = Get-Sha256Text -Url $latest.LineageUrl
    $recoverySha = Get-Sha256Text -Url $latest.RecoveryUrl
    Assert-Sha256 -Path $lineagePath -Expected $lineageSha
    Assert-Sha256 -Path $recoveryPath -Expected $recoverySha

    Write-Host ""
    Write-Host "Use these with the installer if you want local-file mode:" -ForegroundColor Yellow
    Write-Host ".\install-poco-f1-lineageos.ps1 -LineageZip `"$lineagePath`" -RecoveryImg `"$recoveryPath`""
}

if ($DownloadPlatformTools) {
    $platformToolsZip = Join-Path -Path $downloadsPath -ChildPath "platform-tools-latest-windows.zip"
    Save-Url -Url $OfficialPlatformToolsZip -OutputPath $platformToolsZip

    $extractPath = Join-Path -Path (Get-Location) -ChildPath "platform-tools"
    Write-Info "Extracting Android Platform Tools to: $extractPath"
    Expand-Archive -LiteralPath $platformToolsZip -DestinationPath (Get-Location) -Force
    Write-Ok "Platform Tools ready. You can run .\platform-tools\adb.exe and .\platform-tools\fastboot.exe"
}

Write-Host ""
Write-Ok "Download preparation complete."
