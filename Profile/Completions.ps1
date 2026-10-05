function Get-ProfileCompletionCachePath {
    param([string]$Name)

    return Join-Path (Get-ProfileDataDirectory) "completion-$Name.ps1"
}

function Update-ProfileCompletions {
    [CmdletBinding()]
    param()

    if (Find-ProfileExecutable "gh") {
        $script = (& gh completion -s powershell 2>$null) -join "`n"
        if ($LASTEXITCODE -eq 0 -and $script) {
            Set-Content -LiteralPath (Get-ProfileCompletionCachePath "gh") -Value $script -Encoding UTF8
            Write-Host "gh completion cache updated." -ForegroundColor Green
        }
    }
}

if (Find-ProfileExecutable "gh") {
    Register-ArgumentCompleter -Native -CommandName gh -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)

        $cache = Get-ProfileCompletionCachePath "gh"
        if (-not (Test-Path -LiteralPath $cache)) {
            Update-ProfileCompletions *>$null
        }
        if (-not (Test-Path -LiteralPath $cache)) {
            return
        }
        . $cache
        if ($__ghCompleterBlock) {
            & $__ghCompleterBlock $wordToComplete $commandAst $cursorPosition
        }
    }
}
Register-ArgumentCompleter -Native -CommandName git -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)

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

Register-ArgumentCompleter -CommandName cdc -ParameterName Project -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete)

    if (-not (Test-Path -LiteralPath $CODE -PathType Container)) {
        return
    }
    Get-ChildItem -LiteralPath $CODE -Directory -Filter "$wordToComplete*" | ForEach-Object {
        [Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', $_.FullName)
    }
}
