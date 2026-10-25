# ----------------------------------
# On-demand lazy loaders for non-essential profile parts
# ----------------------------------

$Global:LazyLoadedParts = @{}

function Import-LazyProfilePart {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PartName
    )

    if ($Global:LazyLoadedParts.ContainsKey($PartName)) {
        return
    }

    $profileRoot = if ($Global:ProfileDirectory) { $Global:ProfileDirectory }
    elseif (Test-Path -LiteralPath (Join-Path (Split-Path -Parent $PROFILE) "Profile")) {
        Join-Path (Split-Path -Parent $PROFILE) "Profile"
    }
    else {
        Join-Path $PSScriptRoot "Profile"
    }

    $partPath = Join-Path $profileRoot $PartName
    if (-not (Test-Path -LiteralPath $partPath)) {
        Write-Warning "Profile part not found for lazy loading: $partPath"
        return
    }

    $Global:LazyLoadedParts[$PartName] = $true
    $partTimer = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $partSource = [System.IO.File]::ReadAllText($partPath)
        # Dot-sourcing inside this function defines functions in local scope only;
        # remember the top-level names so they can be promoted to global scope below.
        $partAst = [System.Management.Automation.Language.Parser]::ParseInput($partSource, [ref]$null, [ref]$null)
        $partFunctions = @($partAst.EndBlock.Statements |
            Where-Object { $_ -is [System.Management.Automation.Language.FunctionDefinitionAst] } |
            ForEach-Object { $_.Name })
        . ([scriptblock]::Create($partSource))
        foreach ($functionName in $partFunctions) {
            $realFunction = Get-Item -LiteralPath "Function:$functionName" -ErrorAction SilentlyContinue
            if ($realFunction) {
                Set-Item -LiteralPath "Function:global:$functionName" -Value $realFunction.ScriptBlock
            }
        }
        if ($Global:ProfileLoadTimings -is [System.Collections.Generic.List[object]]) {
            $Global:ProfileLoadTimings.Add([PSCustomObject]@{ Part = "$PartName (lazy)"; Milliseconds = $partTimer.Elapsed.TotalMilliseconds })
        }
    }
    catch {
        $Global:LazyLoadedParts.Remove($PartName)
        Write-Warning "Failed to lazy-load profile part '$PartName': $($_.Exception.Message)"
    }
}

function Register-LazyFunction {
    param(
        [Parameter(Mandatory = $true)][string]$FunctionName,
        [Parameter(Mandatory = $true)][string]$PartName
    )

    # After the real part is loaded, the global function is replaced by the real one.
    # If it is still this wrapper, fail loudly instead of recursing forever.
    $sb = [scriptblock]::Create(@"
        `$wrapper = `$MyInvocation.MyCommand.ScriptBlock
        Import-LazyProfilePart "$PartName"
        `$real = Get-Command -Name "$FunctionName" -CommandType Function
        if (-not `$real -or `$real.ScriptBlock -eq `$wrapper) {
            throw "Lazy profile part '$PartName' did not define '$FunctionName'."
        }
        & `$real @args
"@)
    Set-Item -Path "Function:global:$FunctionName" -Value $sb
}

# 1. Copilot.ps1
Register-LazyFunction -FunctionName "ghcs" -PartName "Copilot.ps1"
Register-LazyFunction -FunctionName "ghce" -PartName "Copilot.ps1"

# 2. SecureApiKey.ps1
Register-LazyFunction -FunctionName "Set-SecureApiKey" -PartName "SecureApiKey.ps1"
Register-LazyFunction -FunctionName "Get-SecureApiKey" -PartName "SecureApiKey.ps1"
Register-LazyFunction -FunctionName "Get-ApiKeyFilePath" -PartName "SecureApiKey.ps1"
Register-LazyFunction -FunctionName "Set-SecureApiKeyUnix" -PartName "SecureApiKey.ps1"
Register-LazyFunction -FunctionName "Get-SecureApiKeyUnix" -PartName "SecureApiKey.ps1"

# 3. GeminiTools.ps1
Register-LazyFunction -FunctionName "Test-PowerShellCodeRisk" -PartName "GeminiTools.ps1"
Register-LazyFunction -FunctionName "Invoke-SafePowerShellCode" -PartName "GeminiTools.ps1"
Register-LazyFunction -FunctionName "Format-GeminiText" -PartName "GeminiTools.ps1"

# 4. GeminiChat.ps1
Register-LazyFunction -FunctionName "Invoke-GeminiChat" -PartName "GeminiChat.ps1"
Register-LazyFunction -FunctionName "Get-DefaultGeminiFlashModel" -PartName "GeminiChat.ps1"

# 5. GeminiCommit.ps1
Register-LazyFunction -FunctionName "Invoke-SuggestCommitMessage" -PartName "GeminiCommit.ps1"

# 6. Completions.ps1
Register-LazyFunction -FunctionName "Update-ProfileCompletions" -PartName "Completions.ps1"
Register-LazyFunction -FunctionName "Get-ProfileCompletionCachePath" -PartName "Completions.ps1"

Register-ArgumentCompleter -Native -CommandName git -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    Import-LazyProfilePart "Completions.ps1"
    $elements = @($commandAst.CommandElements | ForEach-Object { $_.ToString() })
    $wordIsNew = $wordToComplete -eq ""
    $position = if ($wordIsNew) { $elements.Count } else { $elements.Count - 1 }
    $results = [Collections.Generic.List[string]]::new()
    if ($position -le 1) {
        $commands = "add", "bisect", "branch", "checkout", "cherry-pick", "clone", "commit", "diff", "fetch", "init", "log", "merge", "pull", "push", "rebase", "remote", "reset", "restore", "revert", "show", "stash", "status", "switch", "tag", "worktree"
        foreach ($command in $commands) { $results.Add($command) }
    }
    else {
        $subcommand = $elements[1]
        if ($subcommand -in "checkout", "switch", "merge", "rebase", "branch", "cherry-pick", "diff", "log", "show", "reset", "push", "pull", "fetch") {
            $refs = git for-each-ref --format="%(refname:short)" refs/heads refs/remotes refs/tags 2>$null
            foreach ($ref in $refs) { $results.Add($ref) }
        }
    }
    $results | Where-Object { $_ -like "$wordToComplete*" } | Sort-Object -Unique | ForEach-Object {
        [Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

if (Find-ProfileExecutable "gh") {
    Register-ArgumentCompleter -Native -CommandName gh -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)
        Import-LazyProfilePart "Completions.ps1"
        $cache = Get-ProfileCompletionCachePath "gh"
        if (-not (Test-Path -LiteralPath $cache)) {
            Update-ProfileCompletions *>$null
        }
        if (Test-Path -LiteralPath $cache) {
            . $cache
            if ($__ghCompleterBlock) {
                & $__ghCompleterBlock $wordToComplete $commandAst $cursorPosition
            }
        }
    }
}

Register-ArgumentCompleter -CommandName cdc -ParameterName Project -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete)
    Import-LazyProfilePart "Completions.ps1"
    if (-not (Test-Path -LiteralPath $CODE -PathType Container)) {
        return
    }
    Get-ChildItem -LiteralPath $CODE -Directory -Filter "$wordToComplete*" | ForEach-Object {
        [Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', $_.FullName)
    }
}

# 7. Diagnostics.ps1
Register-LazyFunction -FunctionName "Show-ProfileInfo" -PartName "Diagnostics.ps1"
