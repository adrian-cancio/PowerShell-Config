# ----------------------------------
# System info banner (lightweight neofetch-style)
# ----------------------------------
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

    $ansiReset = [char]27 + "[0m"
    $ansiGray  = [char]27 + "[38;5;223m"
    $ansiGold  = [char]27 + "[38;5;214m"

    # Colores Gruvbox por etiqueta (fg256)
    $cUser   = [char]27 + "[38;5;142m"  # green
    $cOS     = [char]27 + "[38;5;131m"  # blue
    $cKernel = [char]27 + "[38;5;175m"  # purple
    $cUp     = [char]27 + "[38;5;208m"  # orange
    $cPkgs   = [char]27 + "[38;5;144m"  # cyan-green
    $cWm     = [char]27 + "[38;5;174m"  # magenta
    $cTerm   = [char]27 + "[38;5;164m"  # light gray-green
    $cCpu    = [char]27 + "[38;5;167m"  # red
    $cMem    = [char]27 + "[38;5;214m"  # yellow
    $cDisk   = [char]27 + "[38;5;241m"  # gray
    $cBat    = [char]27 + "[38;5;142m"  # green
    $cRender = [char]27 + "[38;5;241m"  # gray

    $maxLabelLen = 10
    $pairs = @()
    $pairs += @{L = "${cUser}User:${ansiReset}"; V = "$userName@$hostName"}
    $pairs += @{L = "${cOS}OS:${ansiReset}";   V = "$osDesc ($osArch)"}
    if ($kernelStr) { $pairs += @{L = "${cKernel}Kernel:${ansiReset}"; V = $kernelStr} }
    if ($uptimeStr) { $pairs += @{L = "${cUp}Up:${ansiReset}"; V = $uptimeStr} }
    if ($pkgStr)    { $pairs += @{L = "${cPkgs}Pkgs:${ansiReset}"; V = $pkgStr} }
    if ($wmStr)     { $pairs += @{L = "${cWm}WM:${ansiReset}"; V = $wmStr} }
    if ($termStr)   { $pairs += @{L = "${cTerm}Term:${ansiReset}"; V = $termStr} }
    if ($cpuStr)    { $pairs += @{L = "${cCpu}CPU:${ansiReset}"; V = $cpuStr} }
    if ($memStr)    { $pairs += @{L = "${cMem}Mem:${ansiReset}"; V = $memStr} }
    if ($diskStr)   { $pairs += @{L = "${cDisk}Disk:${ansiReset}"; V = $diskStr} }
    if ($batteryStr){ $pairs += @{L = "${cBat}Bat:${ansiReset}"; V = $batteryStr} }
    $pairs += @{L = "${cRender}Rendered:${ansiReset}"; V = "{0:N0} ms" -f $sw.ElapsedMilliseconds}

    # Longitud visible máxima de etiquetas (sin códigos ANSI)
    $maxVisible = 0
    foreach ($p in $pairs) {
        $clean = $p.L -replace "\x1b\[[0-9;]*m",""
        if ($clean.Length -gt $maxVisible) { $maxVisible = $clean.Length }
    }

    Write-Host ""
    Write-Host ("  ${ansiGold}SYSTEM${ansiReset}")
    foreach ($p in $pairs) {
        $cleanLen = ($p.L -replace "\x1b\[[0-9;]*m","").Length
        $pad = " " * ($maxVisible - $cleanLen + 1)
        Write-Host ("{0}{1}{2}" -f $p.L, $pad, $p.V)
    }
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
