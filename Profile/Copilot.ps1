# Copilot aliases
function ghcs {
    param(
        [ValidateSet('gh', 'git', 'shell')]
        [Alias('t')]
        [String]$Target = 'shell',

        [Parameter(Position = 0, ValueFromRemainingArguments)]
        [string]$Prompt
    )
    begin {
        $executeCommandFile = New-TemporaryFile
        $envGhDebug = $Env:GH_DEBUG
    }
    process {
        if ($PSBoundParameters['Debug']) {
            $Env:GH_DEBUG = 'api'
        }
        gh copilot suggest -t $Target -s "$executeCommandFile" $Prompt
    }
    end {
        if ($executeCommandFile.Length -gt 0) {
            $executeCommand = (Get-Content -Path $executeCommandFile -Raw).Trim()
            [Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory($executeCommand)

            $now = Get-Date
            $executeCommandHistoryItem = [PSCustomObject]@{
                CommandLine        = $executeCommand
                ExecutionStatus    = [Management.Automation.Runspaces.PipelineState]::NotStarted
                StartExecutionTime = $now
                EndExecutionTime   = $now.AddSeconds(1)
            }
            Add-History -InputObject $executeCommandHistoryItem

            Write-Host "`n"
            $isRisky = Test-PowerShellCodeRisk -Code $executeCommand
            Write-Host "Suggested command:" -ForegroundColor Cyan
            Write-Host $executeCommand -ForegroundColor Gray
            if ($isRisky) {
                Write-Host "[SECURITY WARNING]" -ForegroundColor White -BackgroundColor DarkRed -NoNewline
                Write-Host " This command may affect your system." -ForegroundColor Yellow
            }

            $canPrompt = [Environment]::UserInteractive -and -not [Console]::IsInputRedirected
            $confirmation = if ($canPrompt) { Read-Host "Run it? (y/N)" } else { "n" }
            if ("$confirmation".Trim().ToLower() -in @("y", "yes")) {
                Invoke-Expression $executeCommand
            }
            else {
                Write-Host "Command not executed. It was added to your history." -ForegroundColor Yellow
            }
        }
    }
    clean {
        Remove-Item -Path $executeCommandFile
        $Env:GH_DEBUG = $envGhDebug
    }
}

function ghce {
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments)]
        [string[]]$Prompt
    )
    begin {
        $envGhDebug = $Env:GH_DEBUG
    }
    process {
        if ($PSBoundParameters['Debug']) {
            $Env:GH_DEBUG = 'api'
        }
        gh copilot explain $Prompt
    }
    clean {
        $Env:GH_DEBUG = $envGhDebug
    }
}
