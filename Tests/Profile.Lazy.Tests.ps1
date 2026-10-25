# Startup, lazy loading and sysinfo checks. Each scenario runs in a child pwsh with a timeout.
# Run with: pwsh -NoProfile -NonInteractive -File Tests/Profile.Lazy.Tests.ps1
param(
    [string]$Scenario,
    [string]$ScratchRoot = (Join-Path ([IO.Path]::GetTempPath()) 'posh-lazy-tests')
)
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
function Assert($Condition, $Message) { if (-not $Condition) { throw $Message } }

if (-not $Scenario) {
    $pwsh = (Get-Command pwsh -CommandType Application | Select-Object -First 1).Source
    # Child processes get an isolated home so real profile data, settings and secrets are never touched.
    $FakeHome = Join-Path $ScratchRoot ([guid]::NewGuid().ToString())
    $null = New-Item $FakeHome -ItemType Directory -Force
    foreach ($Name in @('Startup', 'Sysinfo', 'SysinfoPublic', 'LazyEach', 'Completer')) {
        $Info = [Diagnostics.ProcessStartInfo]::new($pwsh)
        $Info.UseShellExecute = $false
        $Info.RedirectStandardOutput = $true
        $Info.RedirectStandardError = $true
        foreach ($Var in 'HOME', 'USERPROFILE', 'XDG_CONFIG_HOME', 'XDG_DATA_HOME', 'XDG_CACHE_HOME', 'LOCALAPPDATA', 'APPDATA') { $Info.Environment[$Var] = $FakeHome }
        $Info.Environment.Remove('POWERSHELL_PROFILE_DATA') | Out-Null
        foreach ($Arg in @('-NoProfile', '-NonInteractive', '-File', $PSCommandPath, '-Scenario', $Name)) { $Info.ArgumentList.Add($Arg) }
        $Process = [Diagnostics.Process]::Start($Info)
        $Out = $Process.StandardOutput.ReadToEndAsync()
        $Err = $Process.StandardError.ReadToEndAsync()
        if (-not $Process.WaitForExit(60000)) { $Process.Kill($true); throw "Scenario timed out (possible lazy-wrapper recursion): $Name" }
        $Out.Result.TrimEnd() | Write-Host
        Assert ($Process.ExitCode -eq 0) "Scenario failed: $Name`n$($Err.Result)"
    }
    return
}

$LazyParts = 'Copilot.ps1', 'SecureApiKey.ps1', 'GeminiTools.ps1', 'GeminiChat.ps1', 'GeminiCommit.ps1', 'Completions.ps1', 'Diagnostics.ps1'

switch ($Scenario) {
    'Startup' {
        . (Join-Path $Root 'Microsoft.PowerShell_profile.ps1') *>$null
        Assert ($Global:LazyLoadedParts.Count -eq 0) 'Lazy parts were loaded at startup'
        $Loaded = @($Global:ProfileLoadTimings.Part)
        foreach ($Part in $LazyParts) { Assert ($Loaded -notcontains $Part) "$Part was dot-sourced at startup" }
        foreach ($Name in 'ghcs', 'ghce', 'Invoke-GeminiChat', 'Invoke-SuggestCommitMessage', 'Show-ProfileInfo', 'Test-PowerShellCodeRisk', 'Get-SecureApiKey', 'Update-ProfileCompletions', 'sysinfo') {
            Assert (Get-Command $Name -ErrorAction SilentlyContinue) "Missing command: $Name"
        }
        Assert ($Global:UserSettings['Microsoft.PowerShell.Profile:ShowPublicIP'] -eq $false) 'ShowPublicIP must default to false'
        Write-Host 'PASS Startup: no lazy parts loaded, wrappers/aliases present, ShowPublicIP false'
    }
    'Sysinfo' {
        $Global:UserSettings = @{ 'Microsoft.PowerShell.Profile:ShowSystemInfo' = $false }
        . (Join-Path $Root 'Profile/SystemInfo.ps1')
        $Text = (sysinfo 6>&1 | Out-String) -replace "\x1b\[[0-9;]*m", ''
        Assert ($Text -match 'SYSTEM') 'sysinfo printed no banner'
        Assert ($Text -match 'Local IP:\s+\d+\.\d+\.\d+\.\d+') 'Local IP missing'
        if ($IsLinux) { Assert ($Text -match 'Load:\s+[\d.]+, [\d.]+, [\d.]+') 'Load average missing' }
        Assert ($Text -notmatch 'Public IP') 'Public IP shown without request'
        Write-Host 'PASS Sysinfo: banner with load average and local IP, no public IP by default'
    }
    'SysinfoPublic' {
        $Global:UserSettings = @{ 'Microsoft.PowerShell.Profile:ShowSystemInfo' = $false }
        . (Join-Path $Root 'Profile/SystemInfo.ps1')
        # Deterministic: simulate the HTTP response so the test needs no network.
        function Invoke-RestMethod { param($Uri, $TimeoutSec, $ErrorAction) Assert ($TimeoutSec -eq 3) 'Timeout must be 3s'; '203.0.113.7' }
        $Text = (Show-SystemInfo -PublicIP 6>&1 | Out-String) -replace "\x1b\[[0-9;]*m", ''
        Assert ($Text -match 'Public IP:\s+203\.0\.113\.7') 'Simulated public IP not shown'
        Assert ($Text -match 'Local IP:') 'Local IP missing with -PublicIP'
        function Invoke-RestMethod { param($Uri, $TimeoutSec, $ErrorAction) throw 'offline' }
        $Text = (sysinfo -PublicIP 6>&1 | Out-String) -replace "\x1b\[[0-9;]*m", ''
        Assert ($Text -match 'Public IP:\s+n/a') 'Offline failure not handled'
        Write-Host 'PASS SysinfoPublic: simulated success and offline fallback, 3s timeout'
    }
    'LazyEach' {
        . (Join-Path $Root 'Microsoft.PowerShell_profile.ps1') *>$null
        $Cases = [ordered]@{
            'Show-ProfileInfo.Diagnostics.ps1'           = { Show-ProfileInfo *>$null }
            'Test-PowerShellCodeRisk.GeminiTools.ps1'    = { Assert (Test-PowerShellCodeRisk 'Remove-Item foo') 'Risk not detected' }
            'Get-DefaultGeminiFlashModel.GeminiChat.ps1' = { Assert ((Get-DefaultGeminiFlashModel) -eq 'gemini-flash-latest') 'Wrong model' }
            'Get-SecureApiKey.SecureApiKey.ps1'          = { $null = Get-SecureApiKey -KeyName 'LazyTest' -ErrorAction SilentlyContinue }
            'Get-ProfileCompletionCachePath.Completions.ps1' = { Assert ((Get-ProfileCompletionCachePath 'gh') -like '*completion-gh.ps1') 'Wrong cache path' }
        }
        foreach ($Key in $Cases.Keys) {
            $Part = ($Key -split '\.', 2)[1]
            Assert (-not $Global:LazyLoadedParts.ContainsKey($Part)) "$Part loaded before first call"
            & $Cases[$Key]
            Assert $Global:LazyLoadedParts.ContainsKey($Part) "$Part not loaded by first call"
            # The wrapper must now be replaced by the real function (no recursion on second call).
            $Name = ($Key -split '\.', 2)[0]
            Assert ((Get-Command $Name -CommandType Function).ScriptBlock.ToString() -notmatch 'Import-LazyProfilePart') "$Name is still a wrapper after load"
            & $Cases[$Key]
        }
        # ghcs/ghce and Invoke-SuggestCommitMessage would call gh/Gemini, so load their parts directly
        # and check the real functions replaced the wrappers.
        foreach ($Pair in @(@('Copilot.ps1', 'ghcs'), @('Copilot.ps1', 'ghce'), @('GeminiCommit.ps1', 'Invoke-SuggestCommitMessage'))) {
            Import-LazyProfilePart $Pair[0]
            Assert ((Get-Command $Pair[1] -CommandType Function).ScriptBlock.ToString() -notmatch 'Import-LazyProfilePart') "$($Pair[1]) is still a wrapper after load"
        }
        Write-Host "PASS LazyEach: first call loads real part and replaces wrapper ($($Global:LazyLoadedParts.Keys -join ', '))"
    }
    'Completer' {
        . (Join-Path $Root 'Microsoft.PowerShell_profile.ps1') *>$null
        Assert (-not $Global:LazyLoadedParts.ContainsKey('Completions.ps1')) 'Completions loaded at startup'
        $First = [Management.Automation.CommandCompletion]::CompleteInput('git che', 7, $null)
        Assert ($First.CompletionMatches.CompletionText -contains 'checkout') 'First lazy git completion failed'
        Assert $Global:LazyLoadedParts.ContainsKey('Completions.ps1') 'Completer did not load Completions.ps1'
        $Second = [Management.Automation.CommandCompletion]::CompleteInput('git com', 7, $null)
        Assert ($Second.CompletionMatches.CompletionText -contains 'commit') 'Second git completion failed'
        Write-Host 'PASS Completer: lazy git completion works on first and later calls'
    }
}
