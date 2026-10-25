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

    $memStr = ""
    try {
        if ($IsLinux -and (Test-Path "/proc/meminfo")) {
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
        }
        elseif ($IsWindows) {
            $osObj = Get-CimInstance -ClassName Win32_OperatingSystem -Property TotalVisibleMemorySize, FreePhysicalMemory -ErrorAction Stop
            $totGib = [math]::Round($osObj.TotalVisibleMemorySize / 1048576, 1)
            $freeGib = [math]::Round($osObj.FreePhysicalMemory / 1048576, 1)
            $memStr = "$([math]::Round($totGib - $freeGib, 1)) / $totGib GiB"
        }
        elseif ($IsMacOS) {
            $raw = & sysctl -n hw.memsize 2>$null
            if ($raw -match "^\d+$") {
                $totGib = [math]::Round([int64]$raw / 1073741824, 1)
                $memStr = "n/a / $totGib GiB"
            }
            else {
                $memStr = "n/a"
            }
        }
        else {
            $memStr = "n/a"
        }
    }
    catch {
        $memStr = "n/a"
    }

    $sw.Stop()

    $ansiGray = [char]27 + "[38;5;242m"
    $ansiGold = [char]27 + "[38;5;214m"
    $ansiReset = [char]27 + "[0m"

    Write-Host ""
    Write-Host ("  ${ansiGold}SYSTEM${ansiReset}")
    Write-Host ("  ${ansiGray}User:${ansiReset}   $userName@$hostName")
    Write-Host ("  ${ansiGray}OS:${ansiReset}      $osDesc ($osArch)")
    if ($uptimeStr) { Write-Host ("  ${ansiGray}Up:${ansiReset}      $uptimeStr") }
    if ($memStr)    { Write-Host ("  ${ansiGray}Mem:${ansiReset}     $memStr") }
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
