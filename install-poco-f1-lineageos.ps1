[CmdletBinding()]
param(
    [string]$Config = "",
    [string]$LineageZip = "",
    [string]$RecoveryImg = "",
    [string]$GappsZip = ""
)

$ErrorActionPreference = "Stop"

$OfficialDevicePage = "https://wiki.lineageos.org/devices/beryllium/"
$OfficialInstallGuide = "https://wiki.lineageos.org/devices/beryllium/install/"
$OfficialDownloadsPage = "https://download.lineageos.org/devices/beryllium"
$OfficialStaticBuildList = "https://download-static.lineageos.org/beryllium"
$RequiredDevice = "beryllium"
$ConfirmationPhrase = "INSTALL LINEAGEOS ON BERYLLIUM"

$Script:LogFile = $null

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
    Write-Log "[INFO] $Message"
}

function Write-Ok {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
    Write-Log "[OK] $Message"
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
    Write-Log "[WARN] $Message"
}

function Write-Fail {
    param([string]$Message)
    Write-Host "[FAIL] $Message" -ForegroundColor Red
    Write-Log "[FAIL] $Message"
}

function Write-Log {
    param([string]$Message)
    if ($Script:LogFile) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $Script:LogFile -Value "[$timestamp] $Message"
    }
}

function Stop-Safely {
    param([string]$Message)
    Write-Fail $Message
    Write-Host ""
    Write-Host "Stopped safely. No bootloader lock commands were run." -ForegroundColor Yellow
    exit 1
}

function Resolve-ProjectPath {
    param([Parameter(Mandatory)][string]$Path)
    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }
    return [System.IO.Path]::GetFullPath((Join-Path -Path (Get-Location) -ChildPath $Path))
}

function Test-CommandExists {
    param([Parameter(Mandatory)][string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Show-PlatformToolsHelp {
    Write-Host ""
    Write-Host "Android Platform Tools are required." -ForegroundColor Yellow
    Write-Host "Official download:"
    Write-Host "https://developer.android.com/tools/releases/platform-tools"
    Write-Host ""
    Write-Host "After downloading:"
    Write-Host "1. Extract the zip, for example to C:\platform-tools"
    Write-Host "2. Add that folder to your Windows PATH"
    Write-Host "3. Open a new PowerShell window"
    Write-Host "4. Test: adb version"
    Write-Host "5. Test: fastboot --version"
}

function Invoke-Tool {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string[]]$Arguments,
        [switch]$AllowFailure
    )

    $commandText = "$FilePath $($Arguments -join ' ')"
    Write-Log "RUN: $commandText"

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

    Write-Log "EXIT: $($process.ExitCode)"
    if (-not [string]::IsNullOrWhiteSpace($stdout)) {
        Write-Log "STDOUT: $stdout"
    }
    if (-not [string]::IsNullOrWhiteSpace($stderr)) {
        Write-Log "STDERR: $stderr"
    }

    $result = [pscustomobject]@{
        ExitCode = $process.ExitCode
        StdOut = $stdout
        StdErr = $stderr
        Combined = ($stdout + "`n" + $stderr)
    }

    if ($process.ExitCode -ne 0 -and -not $AllowFailure) {
        throw "Command failed: $commandText`n$result.Combined"
    }

    return $result
}

function Get-FastbootVar {
    param([Parameter(Mandatory)][string]$Name)

    $result = Invoke-Tool -FilePath "fastboot.exe" -Arguments @("getvar", $Name) -AllowFailure
    $pattern = "(?im)^\s*$([regex]::Escape($Name))\s*:\s*(.+?)\s*$"
    $match = [regex]::Match($result.Combined, $pattern)
    if ($match.Success) {
        return $match.Groups[1].Value.Trim()
    }
    return $null
}

function Read-ConfigFile {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return @{}
    }
    $resolved = Resolve-ProjectPath -Path $Path
    if (-not (Test-Path -LiteralPath $resolved)) {
        Stop-Safely "Config file not found: $resolved"
    }
    try {
        $json = Get-Content -LiteralPath $resolved -Raw | ConvertFrom-Json
        $map = @{}
        foreach ($property in $json.PSObject.Properties) {
            $map[$property.Name] = $property.Value
        }
        return $map
    } catch {
        Stop-Safely "Could not read config file: $($_.Exception.Message)"
    }
}

function Assert-FileExistsNonEmpty {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Label
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        Stop-Safely "$Label not found: $Path"
    }
    $item = Get-Item -LiteralPath $Path
    if ($item.Length -le 0) {
        Stop-Safely "$Label is empty: $Path"
    }
}

function Assert-OfficialLineageUrl {
    param([Parameter(Mandatory)][string]$Url)

    $uri = [Uri]$Url
    $hostOk = ($uri.Host -eq "lineageos.org" -or $uri.Host.EndsWith(".lineageos.org"))
    if (-not $hostOk) {
        Stop-Safely "Refusing non-LineageOS URL: $Url"
    }
}

function ConvertTo-AbsoluteUrl {
    param(
        [Parameter(Mandatory)][string]$BaseUrl,
        [Parameter(Mandatory)][string]$Href
    )

    return ([Uri]::new([Uri]$BaseUrl, $Href)).AbsoluteUri
}

function Get-OfficialLinksFromPage {
    param([Parameter(Mandatory)][string]$Url)

    Write-Info "Reading official LineageOS build list..."
    try {
        $response = Invoke-WebRequest -Uri $Url -Headers @{ "User-Agent" = "PocoF1-LineageOS-Installer/1.0" } -UseBasicParsing
    } catch {
        Stop-Safely "Could not read official LineageOS build list: $($_.Exception.Message)"
    }

    $links = New-Object System.Collections.Generic.List[string]

    foreach ($link in $response.Links) {
        if ($link.href) {
            $links.Add((ConvertTo-AbsoluteUrl -BaseUrl $Url -Href $link.href))
        }
    }

    $hrefMatches = [regex]::Matches($response.Content, 'href\s*=\s*["'']([^"'']+)["'']', "IgnoreCase")
    foreach ($match in $hrefMatches) {
        $links.Add((ConvertTo-AbsoluteUrl -BaseUrl $Url -Href $match.Groups[1].Value))
    }

    return $links |
        Where-Object { $_ -match "lineageos\.org" } |
        Select-Object -Unique
}

function Find-LatestOfficialBuild {
    param([Parameter(Mandatory)][string]$DownloadsDir)

    $links = @(Get-OfficialLinksFromPage -Url $OfficialStaticBuildList)

    $zipCandidates = foreach ($link in $links) {
        if ($link -match "lineage-[^/]*-\d{8}-[^/]*-$RequiredDevice-signed\.zip(\?|$)") {
            $dateMatch = [regex]::Match($link, "\d{8}")
            if ($dateMatch.Success) {
                [pscustomobject]@{
                    Url = $link
                    Date = $dateMatch.Value
                    FileName = [System.IO.Path]::GetFileName(([Uri]$link).AbsolutePath)
                }
            }
        }
    }

    if (-not $zipCandidates) {
        Stop-Safely "Could not find an official signed LineageOS zip for $RequiredDevice on $OfficialStaticBuildList"
    }

    $latestZip = $zipCandidates | Sort-Object Date, FileName -Descending | Select-Object -First 1
    $buildDate = $latestZip.Date

    $recoveryCandidates = foreach ($link in $links) {
        if ($link -match "\.img(\?|$)" -and $link -match "recovery") {
            $dateMatch = [regex]::Match($link, "\d{8}")
            $date = if ($dateMatch.Success) { $dateMatch.Value } else { "" }
            [pscustomobject]@{
                Url = $link
                Date = $date
                FileName = [System.IO.Path]::GetFileName(([Uri]$link).AbsolutePath)
            }
        }
    }

    $matchingRecovery = $recoveryCandidates |
        Where-Object { $_.Date -eq $buildDate -or $_.Url -match $buildDate } |
        Sort-Object Date, FileName -Descending |
        Select-Object -First 1

    if (-not $matchingRecovery) {
        $matchingRecovery = $recoveryCandidates | Sort-Object Date, FileName -Descending | Select-Object -First 1
    }

    if (-not $matchingRecovery) {
        Stop-Safely "Could not find an official Lineage Recovery image on $OfficialStaticBuildList"
    }

    $checksumLinks = $links | Where-Object { $_ -match "(sha256|sha256sum)" }

    [pscustomobject]@{
        LineageUrl = $latestZip.Url
        LineageFileName = $latestZip.FileName
        RecoveryUrl = $matchingRecovery.Url
        RecoveryFileName = $matchingRecovery.FileName
        BuildDate = $buildDate
        ChecksumLinks = $checksumLinks
        DownloadsDir = $DownloadsDir
    }
}

function Download-OfficialFile {
    param(
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][string]$Destination
    )

    Assert-OfficialLineageUrl -Url $Url
    Write-Info "Downloading $Url"
    Write-Info "Saving to $Destination"
    try {
        Invoke-WebRequest -Uri $Url -OutFile $Destination -Headers @{ "User-Agent" = "PocoF1-LineageOS-Installer/1.0" } -UseBasicParsing
    } catch {
        Stop-Safely "Download failed: $($_.Exception.Message)"
    }
    Assert-FileExistsNonEmpty -Path $Destination -Label "Downloaded file"
}

function Get-Sha256FromText {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][string]$FileName
    )

    $escapedName = [regex]::Escape($FileName)
    $patterns = @(
        "(?im)^([a-f0-9]{64})\s+[\*\s]?$escapedName\s*$",
        "(?im)^([a-f0-9]{64})\b",
        "(?im)\b([a-f0-9]{64})\b"
    )

    foreach ($pattern in $patterns) {
        $match = [regex]::Match($Text, $pattern)
        if ($match.Success) {
            return $match.Groups[1].Value.ToLowerInvariant()
        }
    }
    return $null
}

function Find-ChecksumUrl {
    param(
        [Parameter(Mandatory)][string]$FileUrl,
        [Parameter(Mandatory)][string[]]$ChecksumLinks
    )

    $fileName = [System.IO.Path]::GetFileName(([Uri]$FileUrl).AbsolutePath)
    $escaped = [regex]::Escape($fileName)
    $fromPage = $ChecksumLinks | Where-Object { $_ -match $escaped -or $_ -match ([regex]::Escape("$fileName.sha256")) -or $_ -match ([regex]::Escape("$fileName.sha256sum")) } | Select-Object -First 1
    if ($fromPage) {
        return $fromPage
    }

    return @(
        "$FileUrl?sha256",
        "$FileUrl.sha256",
        "$FileUrl.sha256sum"
    )
}

function Try-VerifyOfficialChecksum {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string]$FileUrl,
        [Parameter(Mandatory)][string[]]$ChecksumLinks
    )

    $fileName = Split-Path -Path $FilePath -Leaf
    $checksumUrlCandidates = @(Find-ChecksumUrl -FileUrl $FileUrl -ChecksumLinks $ChecksumLinks)

    foreach ($checksumUrl in $checksumUrlCandidates) {
        try {
            Assert-OfficialLineageUrl -Url $checksumUrl
            Write-Info "Trying official checksum: $checksumUrl"
            $response = Invoke-WebRequest -Uri $checksumUrl -Headers @{ "User-Agent" = "PocoF1-LineageOS-Installer/1.0" } -UseBasicParsing
            $expected = Get-Sha256FromText -Text $response.Content -FileName $fileName
            if ($expected) {
                $actual = (Get-FileHash -LiteralPath $FilePath -Algorithm SHA256).Hash.ToLowerInvariant()
                Write-Log "Expected SHA256 for ${fileName}: $expected"
                Write-Log "Actual SHA256 for ${fileName}:   $actual"
                if ($actual -ne $expected) {
                    Stop-Safely "SHA-256 mismatch for $fileName. Refusing to continue."
                }
                Write-Ok "SHA-256 verified for $fileName."
                return $true
            }
        } catch {
            Write-Log "Checksum attempt failed for $checksumUrl : $($_.Exception.Message)"
        }
    }

    Write-Warn "Could not automatically verify official checksum for $fileName."
    Write-Host "The file was downloaded from an official LineageOS URL, but checksum verification was not automated." -ForegroundColor Yellow
    $answer = Read-Host "Type CONTINUE WITHOUT CHECKSUM to continue, or press Enter to stop"
    if ($answer -ne "CONTINUE WITHOUT CHECKSUM") {
        Stop-Safely "User stopped because checksum verification was unavailable."
    }
    Write-Warn "Continuing without automated checksum verification for $fileName by user confirmation."
    return $false
}

function Download-LatestOfficialLineage {
    param([Parameter(Mandatory)][string]$DownloadsDir)

    if (-not (Test-Path -LiteralPath $DownloadsDir)) {
        New-Item -ItemType Directory -Path $DownloadsDir | Out-Null
    }

    Write-Host ""
    Write-Host "Official LineageOS sources:" -ForegroundColor White
    Write-Host $OfficialDevicePage
    Write-Host $OfficialInstallGuide
    Write-Host $OfficialDownloadsPage
    Write-Host $OfficialStaticBuildList
    Write-Host ""

    $build = Find-LatestOfficialBuild -DownloadsDir $DownloadsDir
    Write-Ok "Selected build date $($build.BuildDate)."

    $lineagePath = Join-Path -Path $DownloadsDir -ChildPath $build.LineageFileName
    $recoveryName = $build.RecoveryFileName
    if ([string]::IsNullOrWhiteSpace($recoveryName) -or $recoveryName -eq "download") {
        $recoveryName = "lineage-$($build.BuildDate)-recovery-$RequiredDevice.img"
    }
    $recoveryPath = Join-Path -Path $DownloadsDir -ChildPath $recoveryName

    if (-not (Test-Path -LiteralPath $lineagePath)) {
        Download-OfficialFile -Url $build.LineageUrl -Destination $lineagePath
    } else {
        Write-Ok "LineageOS zip already exists: $lineagePath"
        Assert-FileExistsNonEmpty -Path $lineagePath -Label "LineageOS zip"
    }

    if (-not (Test-Path -LiteralPath $recoveryPath)) {
        Download-OfficialFile -Url $build.RecoveryUrl -Destination $recoveryPath
    } else {
        Write-Ok "Recovery image already exists: $recoveryPath"
        Assert-FileExistsNonEmpty -Path $recoveryPath -Label "Recovery image"
    }

    [void](Try-VerifyOfficialChecksum -FilePath $lineagePath -FileUrl $build.LineageUrl -ChecksumLinks ([string[]]$build.ChecksumLinks))
    [void](Try-VerifyOfficialChecksum -FilePath $recoveryPath -FileUrl $build.RecoveryUrl -ChecksumLinks ([string[]]$build.ChecksumLinks))

    return [pscustomobject]@{
        LineageZip = $lineagePath
        RecoveryImg = $recoveryPath
    }
}

function Wait-ForAdbState {
    param(
        [Parameter(Mandatory)][string]$DesiredState,
        [int]$TimeoutSeconds = 300
    )

    Write-Info "Waiting for adb device state '$DesiredState'..."
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        $result = Invoke-Tool -FilePath "adb.exe" -Arguments @("devices") -AllowFailure
        $lines = $result.StdOut -split "`r?`n"
        foreach ($line in $lines) {
            if ($line.Trim() -match "^\S+\s+$DesiredState$") {
                Write-Ok "ADB device is in '$DesiredState' state."
                return $true
            }
        }
        Start-Sleep -Seconds 3
    }
    return $false
}

function Pause-ForEnter {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host ""
    [void](Read-Host $Message)
}

try {
    if (-not [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) {
        Stop-Safely "This script must run on Windows."
    }

    $configMap = Read-ConfigFile -Path $Config

    $deviceCodename = if ($configMap.ContainsKey("deviceCodename") -and $configMap.deviceCodename) { [string]$configMap.deviceCodename } else { $RequiredDevice }
    if ($deviceCodename -ne $RequiredDevice) {
        Stop-Safely "Config deviceCodename must be beryllium."
    }

    $downloadsDir = if ($configMap.ContainsKey("downloadsDir") -and $configMap.downloadsDir) { Resolve-ProjectPath ([string]$configMap.downloadsDir) } else { Resolve-ProjectPath ".\downloads" }
    $logsDir = if ($configMap.ContainsKey("logsDir") -and $configMap.logsDir) { Resolve-ProjectPath ([string]$configMap.logsDir) } else { Resolve-ProjectPath ".\logs" }

    if (-not (Test-Path -LiteralPath $logsDir)) {
        New-Item -ItemType Directory -Path $logsDir | Out-Null
    }
    if (-not (Test-Path -LiteralPath $downloadsDir)) {
        New-Item -ItemType Directory -Path $downloadsDir | Out-Null
    }

    $Script:LogFile = Join-Path -Path $logsDir -ChildPath ("install-{0}.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
    New-Item -ItemType File -Path $Script:LogFile -Force | Out-Null

    Write-Host ""
    Write-Host "Poco F1 Fully Automated Android 15 Installer" -ForegroundColor White
    Write-Host "Log file: $Script:LogFile" -ForegroundColor DarkGray
    Write-Host ""

    Write-Info "Checking required tools..."
    if (-not (Test-CommandExists -Name "adb.exe")) {
        Show-PlatformToolsHelp
        Stop-Safely "adb.exe was not found in PATH."
    }
    if (-not (Test-CommandExists -Name "fastboot.exe")) {
        Show-PlatformToolsHelp
        Stop-Safely "fastboot.exe was not found in PATH."
    }
    Write-Ok "adb.exe and fastboot.exe found."

    Write-Info "Checking Fastboot device..."
    $devices = Invoke-Tool -FilePath "fastboot.exe" -Arguments @("devices")
    $deviceLines = $devices.StdOut -split "`r?`n" | Where-Object { $_.Trim() -match "\S+\s+fastboot" }
    if (-not $deviceLines -or $deviceLines.Count -lt 1) {
        Stop-Safely "No Fastboot device detected. Put the phone in Fastboot mode and reconnect USB."
    }
    Write-Ok "Fastboot device detected."

    Write-Info "Checking product codename with fastboot getvar product..."
    $product = Get-FastbootVar -Name "product"
    if ([string]::IsNullOrWhiteSpace($product)) {
        Stop-Safely "Could not read Fastboot product. Refusing to flash."
    }
    Write-Host "Fastboot product: $product" -ForegroundColor White
    Write-Log "Fastboot product: $product"
    if ($product -ne $RequiredDevice) {
        Stop-Safely "Product is '$product', not '$RequiredDevice'. Refusing to flash."
    }
    Write-Ok "Device codename verified as beryllium."

    Write-Info "Checking bootloader unlock state if available..."
    $unlocked = Get-FastbootVar -Name "unlocked"
    if ([string]::IsNullOrWhiteSpace($unlocked)) {
        Write-Warn "Could not read bootloader unlock state. Some devices do not report it."
    } else {
        Write-Host "Bootloader unlocked: $unlocked" -ForegroundColor White
        Write-Log "Bootloader unlocked: $unlocked"
        if ($unlocked -notmatch "^(yes|true|1)$") {
            Write-Warn "Bootloader does not appear unlocked. Flashing recovery may fail."
        }
    }

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host "WARNING" -ForegroundColor Red
    Write-Host "This will wipe the phone and install LineageOS. Bootloader will NOT be locked." -ForegroundColor Yellow
    Write-Host "Target device: Poco F1 / Pocophone F1 / beryllium only." -ForegroundColor Yellow
    Write-Host "All phone data will be erased during the recovery factory reset." -ForegroundColor Yellow
    Write-Host "Do not continue if battery is low. Keep battery above 50%." -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host ""

    $confirmation = Read-Host "Type exactly '$ConfirmationPhrase' to continue"
    if ($confirmation -ne $ConfirmationPhrase) {
        Stop-Safely "Confirmation phrase did not match."
    }
    Write-Ok "Final confirmation accepted."

    $configLineageZip = if ($configMap.ContainsKey("lineageZip")) { [string]$configMap.lineageZip } else { "" }
    $configRecoveryImg = if ($configMap.ContainsKey("recoveryImg")) { [string]$configMap.recoveryImg } else { "" }
    $configGappsZip = if ($configMap.ContainsKey("gappsZip")) { [string]$configMap.gappsZip } else { "" }
    $autoDownload = if ($configMap.ContainsKey("autoDownloadOfficialLineage")) { [bool]$configMap.autoDownloadOfficialLineage } else { $true }

    if ([string]::IsNullOrWhiteSpace($LineageZip) -and -not [string]::IsNullOrWhiteSpace($configLineageZip)) {
        $LineageZip = $configLineageZip
    }
    if ([string]::IsNullOrWhiteSpace($RecoveryImg) -and -not [string]::IsNullOrWhiteSpace($configRecoveryImg)) {
        $RecoveryImg = $configRecoveryImg
    }
    if ([string]::IsNullOrWhiteSpace($GappsZip) -and -not [string]::IsNullOrWhiteSpace($configGappsZip)) {
        $GappsZip = $configGappsZip
    }

    if (-not [string]::IsNullOrWhiteSpace($LineageZip) -and -not [string]::IsNullOrWhiteSpace($RecoveryImg)) {
        $LineageZip = Resolve-ProjectPath -Path $LineageZip
        $RecoveryImg = Resolve-ProjectPath -Path $RecoveryImg
        Assert-FileExistsNonEmpty -Path $LineageZip -Label "LineageOS zip"
        Assert-FileExistsNonEmpty -Path $RecoveryImg -Label "Recovery image"

        $lineageName = Split-Path -Path $LineageZip -Leaf
        if ($lineageName -notmatch "lineage-.*-$RequiredDevice-signed\.zip$") {
            Stop-Safely "LineageOS zip filename does not look like an official beryllium signed build: $lineageName"
        }
        Write-Ok "Using provided local LineageOS zip and recovery image."
    } elseif ($autoDownload) {
        $downloaded = Download-LatestOfficialLineage -DownloadsDir $downloadsDir
        $LineageZip = $downloaded.LineageZip
        $RecoveryImg = $downloaded.RecoveryImg
    } else {
        Stop-Safely "Provide both -LineageZip and -RecoveryImg, or enable autoDownloadOfficialLineage."
    }

    if (-not [string]::IsNullOrWhiteSpace($GappsZip)) {
        $GappsZip = Resolve-ProjectPath -Path $GappsZip
        Assert-FileExistsNonEmpty -Path $GappsZip -Label "GApps zip"
        Write-Warn "GApps are not provided by LineageOS. Make sure this is Android 15 arm64 and trusted by you."
    }

    Write-Host ""
    Write-Host "Files ready:" -ForegroundColor White
    Write-Host "LineageOS: $LineageZip"
    Write-Host "Recovery:  $RecoveryImg"
    if ($GappsZip) {
        Write-Host "GApps:     $GappsZip"
    } else {
        Write-Host "GApps:     none"
    }
    Write-Host ""

    Write-Info "Flashing Lineage Recovery..."
    Invoke-Tool -FilePath "fastboot.exe" -Arguments @("flash", "recovery", $RecoveryImg) | Out-Null
    Write-Ok "Recovery flashed."

    Write-Info "Trying to reboot directly into recovery..."
    $rebootRecovery = Invoke-Tool -FilePath "fastboot.exe" -Arguments @("reboot", "recovery") -AllowFailure
    if ($rebootRecovery.ExitCode -ne 0) {
        Write-Warn "fastboot reboot recovery failed or is unsupported on this setup."
        Write-Host "Manually boot recovery now: hold Volume Up + Power until Lineage Recovery appears." -ForegroundColor Yellow
    } else {
        Write-Host "If the phone does not enter recovery, hold Volume Up + Power until Lineage Recovery appears." -ForegroundColor Yellow
    }

    Pause-ForEnter "Press Enter after Lineage Recovery is visible on the phone"

    Write-Host ""
    Write-Host "Factory reset stage" -ForegroundColor White
    Write-Host "On the phone, use Lineage Recovery:" -ForegroundColor Yellow
    Write-Host "Factory reset > Format data/factory reset > confirm" -ForegroundColor Yellow
    Write-Host "This is the wipe step that removes the old Kali NetHunter Pro system data." -ForegroundColor Yellow
    Pause-ForEnter "Press Enter only after factory reset is complete"

    Write-Host ""
    Write-Host "ADB sideload stage" -ForegroundColor White
    Write-Host "On the phone, choose:" -ForegroundColor Yellow
    Write-Host "Apply update > Apply from ADB" -ForegroundColor Yellow

    if (-not (Wait-ForAdbState -DesiredState "sideload" -TimeoutSeconds 300)) {
        Stop-Safely "ADB did not show a device in sideload mode. Choose Apply update > Apply from ADB, then rerun if needed."
    }

    Write-Info "Sideloading LineageOS. PC progress may appear to stop around 47%; that can be normal."
    Invoke-Tool -FilePath "adb.exe" -Arguments @("sideload", $LineageZip) | Out-Null
    Write-Ok "LineageOS sideload command completed. Check the phone for final recovery status."

    if ($GappsZip) {
        Write-Host ""
        Write-Host "GApps sideload stage" -ForegroundColor White
        Write-Host "On the phone, choose Apply from ADB again." -ForegroundColor Yellow
        Write-Host "If recovery warns that signature verification failed for GApps, that can be expected for add-ons not signed by LineageOS." -ForegroundColor Yellow
        Pause-ForEnter "Press Enter after choosing Apply from ADB again"

        if (-not (Wait-ForAdbState -DesiredState "sideload" -TimeoutSeconds 300)) {
            Stop-Safely "ADB did not show sideload mode for GApps."
        }

        Write-Info "Sideloading GApps..."
        Invoke-Tool -FilePath "adb.exe" -Arguments @("sideload", $GappsZip) | Out-Null
        Write-Ok "GApps sideload command completed. Check the phone for final recovery status."
    } else {
        Write-Host ""
        Write-Host "No GApps provided. LineageOS will boot without Play Store." -ForegroundColor Yellow
        Write-Log "No GApps provided."
    }

    Write-Host ""
    Write-Host "Reboot stage" -ForegroundColor White
    Write-Host "Choose Reboot system now on the phone, or let the script try adb reboot." -ForegroundColor Yellow
    $tryReboot = Read-Host "Type ADB REBOOT to try adb reboot, or press Enter after choosing Reboot system now on the phone"
    if ($tryReboot -eq "ADB REBOOT") {
        Invoke-Tool -FilePath "adb.exe" -Arguments @("reboot") -AllowFailure | Out-Null
    }

    Write-Host ""
    Write-Ok "Install flow complete."
    Write-Host "First boot can take several minutes." -ForegroundColor Yellow
    Write-Host "After LineageOS boots, follow android-studio-after-install.md for Android Studio detection." -ForegroundColor Cyan
    Write-Host "Log file: $Script:LogFile" -ForegroundColor DarkGray
} catch {
    Write-Fail $_.Exception.Message
    Write-Host ""
    Write-Host "Stopped because of an error. Keep the phone in Fastboot or Recovery and read troubleshooting.md." -ForegroundColor Yellow
    Write-Host "Log file: $Script:LogFile" -ForegroundColor DarkGray
    exit 1
}
