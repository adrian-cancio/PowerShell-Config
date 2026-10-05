function Show-ProfileInfo {
    [CmdletBinding()]
    param()

    $tools = "git", "gh", "python", "pip", "docker", "nvim", "zoxide", "openssl"
    $toolInfo = foreach ($tool in $tools) {
        $path = Find-ProfileExecutable $tool
        [PSCustomObject]@{
            Name   = $tool
            Found  = [bool]$path
            Path   = $path
        }
    }

    $info = [ordered]@{
        PowerShell    = $PSVersionTable.PSVersion.ToString()
        OS            = [Runtime.InteropServices.RuntimeInformation]::OSDescription
        Host          = $Host.Name
        Profile       = $PROFILE
        ProfileParts  = $Global:ProfileLoadTimings.Count
        ProfileLoadMs = [int]($Global:ProfileLoadTimings | Measure-Object Milliseconds -Sum).Sum
        ColorScheme   = $Global:UserSettings["Microsoft.PowerShell.Profile:PromptColorScheme"]
        DataDirectory = Get-ProfileDataDirectory
    }

    Write-Host "Profile" -ForegroundColor Cyan
    $info.GetEnumerator() | ForEach-Object { Write-Host ("  {0,-14} {1}" -f $_.Key, $_.Value) }

    Write-Host "`nLoad time per part" -ForegroundColor Cyan
    $Global:ProfileLoadTimings | Sort-Object Milliseconds -Descending | ForEach-Object {
        Write-Host ("  {0,-24} {1,6:N0} ms" -f $_.Part, $_.Milliseconds)
    }

    Write-Host "`nTools" -ForegroundColor Cyan
    foreach ($tool in $toolInfo) {
        $mark = if ($tool.Found) { "✓" } else { "✗" }
        $color = if ($tool.Found) { "Green" } else { "Yellow" }
        Write-Host ("  {0} {1,-10} {2}" -f $mark, $tool.Name, $tool.Path) -ForegroundColor $color
    }

    Write-Host "`nEffective execution policy" -ForegroundColor Cyan
    if ($IsWindows) {
        Get-ExecutionPolicy -List | Format-Table -AutoSize | Out-String | Write-Host
    }
    else {
        Write-Host "  Not applicable on this platform"
    }
}
