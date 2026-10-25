# ----------------------------------
# System info banner (lightweight neofetch-style)
# ----------------------------------
function Show-DistroLogo {
    [CmdletBinding()]
    param()

    $id = ""
    if ($IsLinux -and (Test-Path "/etc/os-release")) {
        $release = Get-Content "/etc/os-release" -Raw -ErrorAction SilentlyContinue
        $line = ($release -split "`n") | Where-Object { $_ -match '^ID=' } | Select-Object -First 1
        if ($line -match 'ID="?(?<id>[^"\n]+)"?') { $id = $Matches['id'] }
    }

    $ansiYellow = [char]27 + "[38;5;214m"
    $ansiReset = [char]27 + "[0m"

    $logo = @()

    switch ($id) {
        "fedora" {
            $logo = @(
                "   ___",
                "  / __|",
                "  \__ \"
            )
        }
        "ubuntu" {
            $logo = @(
                "   __",
                "  / /",
                " / /"
            )
        }
        "debian" {
            $logo = @(
                "  _ ",
                " (_)"
            )
        }
        "arch" {
            $logo = @(
                "  /\",
                " /  \",
                "/ /\ \"
            )
        }
        default {
            $logo = @(
                "  _ ",
                " (_)"
            )
        }
    }

    foreach ($line in $logo) {
        Write-Host ("  ${ansiYellow}" + $line + "${ansiReset}")
    }
    Write-Host ""
}

function Show-SystemInfo {
    [CmdletBinding()]
    param()

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
    $batteryStr = ""
    $diskStr = ""
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

    $sw.Stop()

    $ansiGray = [char]27 + "[38;5;223m"
    $ansiGold = [char]27 + "[38;5;214m"
    $ansiReset = [char]27 + "[0m"

    Write-Host ""
    Show-DistroLogo
    Write-Host ("  ${ansiGold}SYSTEM${ansiReset}")
    Write-Host ("  ${ansiGray}User:${ansiReset}   $userName@$hostName")
    Write-Host ("  ${ansiGray}OS:${ansiReset}      $osDesc ($osArch)")
    if ($kernelStr) { Write-Host ("  ${ansiGray}Kernel:${ansiReset}  $kernelStr") }
    if ($uptimeStr) { Write-Host ("  ${ansiGray}Up:${ansiReset}      $uptimeStr") }
    if ($pkgStr)    { Write-Host ("  ${ansiGray}Pkgs:${ansiReset}    $pkgStr") }
    if ($wmStr)     { Write-Host ("  ${ansiGray}WM:${ansiReset}      $wmStr") }
    if ($termStr)   { Write-Host ("  ${ansiGray}Term:${ansiReset}    $termStr") }
    if ($cpuStr)    { Write-Host ("  ${ansiGray}CPU:${ansiReset}     $cpuStr") }
    if ($memStr)    { Write-Host ("  ${ansiGray}Mem:${ansiReset}     $memStr") }
    if ($diskStr)   { Write-Host ("  ${ansiGray}Disk:${ansiReset}    $diskStr") }
    if ($batteryStr){ Write-Host ("  ${ansiGray}Bat:${ansiReset}     $batteryStr") }
    Write-Host ("  ${ansiGray}Rendered:${ansiReset} $($sw.ElapsedMilliseconds) ms")
    Write-Host ""
}

# Auto-show on startup when enabled (default: true)
if ($Global:UserSettings["Microsoft.PowerShell.Profile:ShowSystemInfo"] -eq $true) {
    try {
        Show-SystemInfo
    }
    catch {
        Write-Warning "System info banner failed: $($_.Exception.Message)"
    }
}
