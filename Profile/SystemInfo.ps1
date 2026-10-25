# ----------------------------------
# System info banner (lightweight neofetch-style)
# ----------------------------------
function Show-SystemInfo {
    [CmdletBinding()]
    param(
        [switch]$PublicIP
    )

    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    $osDesc = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
    $osArch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
    $hostName = [Environment]::MachineName
    $userName = [Environment]::UserName
    $shellName = "PowerShell $($PSVersionTable.PSVersion.ToString())"

    $uptimeStr = ""
    $kernelStr = ""
    $pkgStr = ""
    $wmStr = ""
    $termStr = ""
    $cpuStr = ""
    $loadStr = ""
    $batteryStr = ""
    $diskStr = ""
    $localIpStr = ""
    $publicIpStr = ""
    try {
        if ($IsLinux -and (Test-Path "/proc/uptime")) {
            $sec = [double]((Get-Content "/proc/uptime" -Raw).Split()[0])
            $ts = [TimeSpan]::FromSeconds($sec)
            $uptimeStr = "$([int]$ts.TotalHours)h $($ts.Minutes)m"
        }
        elseif ($IsWindows) {
            $boot = (Get-CimInstance -ClassName Win32_OperatingSystem -Property LastBootUpTime).LastBootUpTime
            if ($boot) {
                $ts = (Get-Date) - $boot
                $uptimeStr = "$([int]$ts.TotalHours)h $($ts.Minutes)m"
            }
        }
        elseif ($IsMacOS) {
            $raw = & sysctl -n kern.boottime 2>$null
            if ($raw) {
                $secs = [regex]::Match($raw, "{ sec = (\d+)").Groups[1].Value
                if ($secs -match "^\d+$") {
                    $boot = [DateTimeOffset]::FromUnixTimeSeconds([int64]$secs)
                    $ts = [DateTimeOffset]::Now - $boot
                    $uptimeStr = "$([int]$ts.TotalHours)h $($ts.Minutes)m"
                }
            }
        }
    }
    catch {
        $uptimeStr = "n/a"
    }

    # Load average (Linux /proc/loadavg, macOS sysctl)
    try {
        if ($IsLinux -and (Test-Path "/proc/loadavg")) {
            $rawLoad = Get-Content "/proc/loadavg" -Raw -ErrorAction SilentlyContinue
            if ($rawLoad) {
                $parts = $rawLoad.Trim().Split()
                if ($parts.Length -ge 3) {
                    $loadStr = "$($parts[0]), $($parts[1]), $($parts[2])"
                }
            }
        }
        elseif ($IsMacOS) {
            $rawLoad = & sysctl -n vm.loadavg 2>$null
            if ($rawLoad -match '\{\s*([0-9.]+)\s+([0-9.]+)\s+([0-9.]+)\s*\}') {
                $loadStr = "$($Matches[1]), $($Matches[2]), $($Matches[3])"
            }
        }
    }
    catch {}

    # Kernel, packages, WM, terminal, CPU, disk, battery (Linux only)
    if ($IsLinux) {
        try {
            $rawKernel = Get-Content "/proc/version" -Raw -ErrorAction SilentlyContinue
            if ($rawKernel -match "^Linux version\s+([\w\.\-]+)") {
                $kernelStr = $Matches[1]
            }
        } catch {}

        try {
            $pkgCount = (& rpm -qa --qf "%{NAME}\n" 2>$null | Measure-Object -Line).Lines
            if ($pkgCount) { $pkgStr = "$pkgCount rpm" }
        } catch { try {
            $pkgCount = (& dpkg-query -W -f='${Package}\n' 2>$null | Measure-Object -Line).Lines
            if ($pkgCount) { $pkgStr = "$pkgCount deb" }
        } catch {} }

        try {
            $wmStr = "Niri"
        } catch {}

        try {
            if ($env:KITTY_WINDOW_ID) { $termStr = "Kitty" }
            elseif ($env:TMUX) { $termStr = "Tmux" }
            elseif ($env:WT_SESSION) { $termStr = "Windows Terminal" }
        } catch {}

        try {
            $cpuLine = Get-Content "/proc/cpuinfo" -ErrorAction SilentlyContinue | Where-Object { $_ -match "^model name" } | Select-Object -First 1
            if ($cpuLine) { $cpuStr = $cpuLine -replace "^model name\s*:\s*","" }
        } catch {}

        try {
            $memStr = ""
            $mi = Get-Content "/proc/meminfo"
            $totKb = 0
            $availKb = 0
            foreach ($line in $mi) {
                if ($line -match "^MemTotal:\s+(\d+)") { $totKb = [int64]$Matches[1] }
                elseif ($line -match "^MemAvailable:\s+(\d+)") { $availKb = [int64]$Matches[1] }
                if ($totKb -gt 0 -and $availKb -gt 0) { break }
            }
            if ($totKb -gt 0) {
                $usedGib = [math]::Round(($totKb - $availKb) / 1048576, 1)
                $totGib = [math]::Round($totKb / 1048576, 1)
                $memStr = "$usedGib / $totGib GiB"
            }
            else {
                $memStr = "n/a"
            }
        } catch {}

        try {
            $diskLine = (& df -h / 2>$null | Select-Object -Skip 1 | Select-Object -First 1)
            if ($diskLine) {
                $parts = $diskLine -split '\s+'
                if ($parts.Count -ge 3) {
                    $diskStr = "$($parts[2]) / $($parts[1]) /"
                }
            }
        } catch {}

        try {
            if (Test-Path "/sys/class/power_supply/BAT1") {
                $cap = Get-Content "/sys/class/power_supply/BAT1/capacity" -Raw -ErrorAction SilentlyContinue
                $status = Get-Content "/sys/class/power_supply/BAT1/status" -Raw -ErrorAction SilentlyContinue
                if ($cap) { $batteryStr = "$($cap.Trim())% $($status.Trim())" }
            }
        } catch {}
    }
    elseif ($IsWindows) {
        try {
            $osObj = Get-CimInstance -ClassName Win32_OperatingSystem -Property TotalVisibleMemorySize, FreePhysicalMemory -ErrorAction Stop
            $totGib = [math]::Round($osObj.TotalVisibleMemorySize / 1048576, 1)
            $freeGib = [math]::Round($osObj.FreePhysicalMemory / 1048576, 1)
            $memStr = "$([math]::Round($totGib - $freeGib, 1)) / $totGib GiB"
        } catch { $memStr = "n/a" }
    }
    elseif ($IsMacOS) {
        try {
            $raw = & sysctl -n hw.memsize 2>$null
            if ($raw -match "^\d+$") {
                $totGib = [math]::Round([int64]$raw / 1073741824, 1)
                $memStr = "n/a / $totGib GiB"
            }
            else {
                $memStr = "n/a"
            }
        } catch { $memStr = "n/a" }
    }
    else {
        $memStr = "n/a"
    }

    # Local IP (parsed from ip -brief addr or .NET cross-platform)
    try {
        if ($IsLinux -and (Get-Command ip -ErrorAction SilentlyContinue)) {
            $ipLines = & ip -brief addr 2>$null | Where-Object { $_ -match '\s+UP\s+' -and $_ -notmatch '^lo\b' }
            foreach ($line in $ipLines) {
                if ($line -match '\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/\d+') {
                    $localIpStr = $Matches[1]
                    break
                }
            }
        }
    } catch {}

    if (-not $localIpStr) {
        try {
            $interfaces = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() |
                Where-Object { $_.OperationalStatus -eq 'Up' -and $_.NetworkInterfaceType -notin 'Loopback','Tunnel' }
            foreach ($iface in $interfaces) {
                $addr = $iface.GetIPProperties().UnicastAddresses |
                    Where-Object { $_.Address.AddressFamily -eq 'InterNetwork' -and $_.Address.ToString() -notlike '127.*' -and $_.Address.ToString() -notlike '169.254.*' } |
                    Select-Object -First 1
                if ($addr) {
                    $localIpStr = $addr.Address.ToString()
                    break
                }
            }
        } catch {}
    }

    # Public IP on-demand (only when requested via -PublicIP or setting enabled)
    $shouldFetchPublic = $PublicIP.IsPresent -or ($Global:UserSettings["Microsoft.PowerShell.Profile:ShowPublicIP"] -eq $true)
    if ($shouldFetchPublic) {
        try {
            $rawPublic = (Invoke-RestMethod -Uri "https://ifconfig.me/ip" -TimeoutSec 3 -ErrorAction Stop).ToString().Trim()
            if ($rawPublic -match '(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})') {
                $publicIpStr = $Matches[1]
            }
        }
        catch {
            try {
                $rawPublic = (Invoke-RestMethod -Uri "https://api.ipify.org" -TimeoutSec 3 -ErrorAction Stop).ToString().Trim()
                if ($rawPublic -match '(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})') {
                    $publicIpStr = $Matches[1]
                }
            }
            catch {
                $publicIpStr = "n/a"
            }
        }
    }

    $sw.Stop()

    $ansiReset = [char]27 + "[0m"
    $ansiGold  = [char]27 + "[38;5;214m"
    $ansiLabel = [char]27 + "[38;5;223m"
    $ansiValue = [char]27 + "[38;5;246m"

    $pairs = @()
    $pairs += @{L = "${ansiLabel}User:${ansiReset}"; V = "${ansiValue}$userName@$hostName${ansiReset}"}
    $pairs += @{L = "${ansiLabel}OS:${ansiReset}";   V = "${ansiValue}$osDesc ($osArch)${ansiReset}"}
    if ($kernelStr) { $pairs += @{L = "${ansiLabel}Kernel:${ansiReset}"; V = "${ansiValue}$kernelStr${ansiReset}"} }
    if ($uptimeStr) { $pairs += @{L = "${ansiLabel}Up:${ansiReset}"; V = "${ansiValue}$uptimeStr${ansiReset}"} }
    if ($pkgStr)    { $pairs += @{L = "${ansiLabel}Pkgs:${ansiReset}"; V = "${ansiValue}$pkgStr${ansiReset}"} }
    if ($wmStr)     { $pairs += @{L = "${ansiLabel}WM:${ansiReset}"; V = "${ansiValue}$wmStr${ansiReset}"} }
    if ($termStr)   { $pairs += @{L = "${ansiLabel}Term:${ansiReset}"; V = "${ansiValue}$termStr${ansiReset}"} }
    if ($cpuStr)    { $pairs += @{L = "${ansiLabel}CPU:${ansiReset}"; V = "${ansiValue}$cpuStr${ansiReset}"} }
    if ($loadStr)   { $pairs += @{L = "${ansiLabel}Load:${ansiReset}"; V = "${ansiValue}$loadStr${ansiReset}"} }
    if ($memStr)    { $pairs += @{L = "${ansiLabel}Mem:${ansiReset}"; V = "${ansiValue}$memStr${ansiReset}"} }
    if ($diskStr)   { $pairs += @{L = "${ansiLabel}Disk:${ansiReset}"; V = "${ansiValue}$diskStr${ansiReset}"} }
    if ($batteryStr){ $pairs += @{L = "${ansiLabel}Bat:${ansiReset}"; V = "${ansiValue}$batteryStr${ansiReset}"} }
    if ($localIpStr){ $pairs += @{L = "${ansiLabel}Local IP:${ansiReset}"; V = "${ansiValue}$localIpStr${ansiReset}"} }
    if ($publicIpStr){ $pairs += @{L = "${ansiLabel}Public IP:${ansiReset}"; V = "${ansiValue}$publicIpStr${ansiReset}"} }
    $pairs += @{L = "${ansiLabel}Rendered:${ansiReset}"; V = "${ansiValue}{0:N0} ms${ansiReset}" -f $sw.ElapsedMilliseconds}

    # Longitud visible máxima de etiquetas (sin códigos ANSI)
    $maxVisible = 0
    foreach ($p in $pairs) {
        $clean = $p.L -replace "\x1b\[[0-9;]*m",""
        if ($clean.Length -gt $maxVisible) { $maxVisible = $clean.Length }
    }

    Write-Host ("${ansiGold}SYSTEM${ansiReset}")
    foreach ($p in $pairs) {
        $cleanLen = ($p.L -replace "\x1b\[[0-9;]*m","").Length
        $pad = " " * ($maxVisible - $cleanLen + 1)
        Write-Host ("{0}{1}{2}" -f $p.L, $pad, $p.V)
    }
    Write-Host ""
}

# Ensure sysinfo alias is always available
Set-Alias -Name sysinfo -Value Show-SystemInfo

# Auto-show on first interactive session of the day (default: true)
if ($Global:UserSettings["Microsoft.PowerShell.Profile:ShowSystemInfo"] -eq $true) {
    try {
        $markRoot = Join-Path $HOME ".local/share/powershell-profile"
        $null = New-Item -ItemType Directory -Path $markRoot -Force -ErrorAction SilentlyContinue
        $markFile = Join-Path $markRoot ("sysinfo-" + (Get-Date).ToString("yyyyMMdd"))
        $showToday = -not (Test-Path -LiteralPath $markFile -PathType Leaf)
        if ($showToday) {
            Show-SystemInfo
            # Mark that we showed it today (best effort; failure is not fatal)
            try { $null = New-Item -ItemType File -Path $markFile -Force -ErrorAction SilentlyContinue } catch {}
        }
    }
    catch {
        Write-Warning "System info banner failed: $($_.Exception.Message)"
    }
}
