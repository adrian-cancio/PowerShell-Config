# ----------------------------------
# Git status for the prompt
# Returns $null outside a repository, on slow paths, or when disabled.
# ----------------------------------
$Global:GitPromptCache = $null
$Global:GitSlowRoots = @{}

function Test-GitPathIsSlow {
    param([string]$Path)

    if ($Path.StartsWith("\\") -or $Path.StartsWith("//")) {
        return $true
    }
    if (-not $IsWindows) {
        return $false
    }

    $Root = [IO.Path]::GetPathRoot($Path)
    if (-not $Root) {
        return $false
    }
    if (-not $Global:GitSlowRoots.ContainsKey($Root)) {
        $Slow = $false
        try {
            $Slow = [IO.DriveInfo]::new($Root).DriveType -eq [IO.DriveType]::Network
        }
        catch {
            $Slow = $false
        }
        $Global:GitSlowRoots[$Root] = $Slow
    }
    return $Global:GitSlowRoots[$Root]
}

function Resolve-GitDirectory {
    param([string]$DotGit)

    if ([IO.Directory]::Exists($DotGit)) {
        return $DotGit
    }
    try {
        $Content = [IO.File]::ReadAllText($DotGit).Trim()
    }
    catch {
        return $null
    }
    if ($Content -match '^gitdir:\s*(.+)$') {
        $Target = $Matches[1].Trim()
        if (-not [IO.Path]::IsPathRooted($Target)) {
            $Target = [IO.Path]::GetFullPath([IO.Path]::Combine([IO.Path]::GetDirectoryName($DotGit), $Target))
        }
        return $Target
    }
    return $null
}

function Get-GitHeadName {
    param([string]$GitDir)

    try {
        $Head = [IO.File]::ReadAllText([IO.Path]::Combine($GitDir, "HEAD")).Trim()
    }
    catch {
        return "?"
    }
    if ($Head.StartsWith("ref: refs/heads/")) { return $Head.Substring(16) }
    if ($Head.StartsWith("ref: ")) { return $Head.Substring(5) }
    return ":" + $Head.Substring(0, [Math]::Min(7, $Head.Length))
}

function Get-GitStashCount {
    param([string]$GitDir)

    try {
        $Common = $GitDir
        $CommonFile = [IO.Path]::Combine($GitDir, "commondir")
        if ([IO.File]::Exists($CommonFile)) {
            $Relative = [IO.File]::ReadAllText($CommonFile).Trim()
            $Common = [IO.Path]::GetFullPath([IO.Path]::Combine($GitDir, $Relative))
        }
        $StashLog = [IO.Path]::Combine($Common, "logs", "refs", "stash")
        if (-not [IO.File]::Exists($StashLog)) {
            return 0
        }
        return [IO.File]::ReadAllLines($StashLog).Count
    }
    catch {
        return 0
    }
}

function Invoke-GitStatusPorcelain {
    param(
        [string]$Executable,
        [string]$WorkingDirectory,
        [int]$TimeoutMs
    )

    $StartInfo = [Diagnostics.ProcessStartInfo]::new($Executable)
    foreach ($Argument in @("--no-optional-locks", "status", "--porcelain=v2", "--branch")) {
        $StartInfo.ArgumentList.Add($Argument)
    }
    $StartInfo.WorkingDirectory = $WorkingDirectory
    $StartInfo.RedirectStandardOutput = $true
    $StartInfo.RedirectStandardError = $true
    $StartInfo.UseShellExecute = $false
    $StartInfo.CreateNoWindow = $true
    $StartInfo.StandardOutputEncoding = [Text.Encoding]::UTF8

    $Process = [Diagnostics.Process]::Start($StartInfo)
    try {
        $OutputTask = $Process.StandardOutput.ReadToEndAsync()
        $null = $Process.StandardError.ReadToEndAsync()
        if (-not $Process.WaitForExit($TimeoutMs)) {
            try { $Process.Kill($true) } catch { $null = $_ }
            return @{ TimedOut = $true }
        }
        $Process.WaitForExit()
        return @{ TimedOut = $false; ExitCode = $Process.ExitCode; Output = $OutputTask.Result }
    }
    finally {
        $Process.Dispose()
    }
}

function Get-GitPromptInfo {
    param([int]$HistoryId = -1)

    if ($Global:UserSettings["Microsoft.PowerShell.Profile:GitPrompt"] -eq $false) {
        return $null
    }
    if ($PWD.Provider.Name -ne "FileSystem") {
        return $null
    }
    if ($null -eq $Global:GitExecutable) {
        $Command = Get-Command git -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        $Global:GitExecutable = if ($Command) { $Command.Source } else { "" }
    }
    if (-not $Global:GitExecutable) {
        return $null
    }

    $Path = $PWD.ProviderPath
    if (Test-GitPathIsSlow $Path) {
        return $null
    }

    $Cache = $Global:GitPromptCache
    if ($Cache -and $Cache.Path -eq $Path -and $Cache.HistoryId -eq $HistoryId) {
        $MaxAge = if ($Cache.Info -and $Cache.Info.TimedOut) { 30 } else { 5 }
        if (([DateTime]::UtcNow - $Cache.Time).TotalSeconds -lt $MaxAge) {
            return $Cache.Info
        }
    }

    $DotGit = $null
    for ($Dir = $Path; $Dir; $Dir = [IO.Path]::GetDirectoryName($Dir)) {
        $Candidate = [IO.Path]::Combine($Dir, ".git")
        if ([IO.Directory]::Exists($Candidate) -or [IO.File]::Exists($Candidate)) {
            $DotGit = $Candidate
            break
        }
    }

    $Info = $null
    if ($DotGit) {
        $GitDir = Resolve-GitDirectory $DotGit
        if ($GitDir) {
            $Info = Get-GitStatusInfo -GitDir $GitDir -WorkingDirectory $Path
        }
    }

    $Global:GitPromptCache = @{ Path = $Path; HistoryId = $HistoryId; Time = [DateTime]::UtcNow; Info = $Info }
    return $Info
}

function Get-GitStatusInfo {
    param(
        [string]$GitDir,
        [string]$WorkingDirectory
    )

    $TimeoutMs = [int]$Global:UserSettings["Microsoft.PowerShell.Profile:GitPromptTimeoutMs"]
    if ($TimeoutMs -le 0) {
        $TimeoutMs = 1500
    }

    $Result = Invoke-GitStatusPorcelain -Executable $Global:GitExecutable -WorkingDirectory $WorkingDirectory -TimeoutMs $TimeoutMs
    $Info = @{ Branch = ""; Ahead = 0; Behind = 0; Staged = 0; Modified = 0; Untracked = 0; Conflicts = 0; Stash = 0; TimedOut = $false }

    if ($Result.TimedOut) {
        $Info.TimedOut = $true
        $Info.Branch = Get-GitHeadName $GitDir
        return $Info
    }
    if ($Result.ExitCode -ne 0 -or -not $Result.Output) {
        return $null
    }

    $Oid = ""
    foreach ($Line in $Result.Output.Split("`n")) {
        if ($Line.StartsWith("# branch.head ")) { $Info.Branch = $Line.Substring(14).Trim() }
        elseif ($Line.StartsWith("# branch.oid ")) { $Oid = $Line.Substring(13).Trim() }
        elseif ($Line.StartsWith("# branch.ab ")) {
            if ($Line -match '\+(\d+) -(\d+)') {
                $Info.Ahead = [int]$Matches[1]
                $Info.Behind = [int]$Matches[2]
            }
        }
        elseif ($Line.StartsWith("1 ") -or $Line.StartsWith("2 ")) {
            if ($Line[2] -ne ".") { $Info.Staged++ }
            if ($Line[3] -ne ".") { $Info.Modified++ }
        }
        elseif ($Line.StartsWith("u ")) { $Info.Conflicts++ }
        elseif ($Line.StartsWith("? ")) { $Info.Untracked++ }
    }

    if ($Info.Branch -eq "(detached)") {
        $Info.Branch = ":" + $Oid.Substring(0, [Math]::Min(7, $Oid.Length))
    }
    $Info.Stash = Get-GitStashCount $GitDir
    return $Info
}
