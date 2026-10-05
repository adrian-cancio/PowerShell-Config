function Test-ProfileHistorySensitive {
    param([string]$Line)

    $pattern = '(?i)(password|passwd|secret|api[_-]?key|token|bearer\s|credential|-AsPlainText|ConvertTo-SecureString|github_pat_|gh[pousr]_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{16,}|AKIA[0-9A-Z]{16})'
    return [bool]($Line -match $pattern)
}

if ($Host.Name -eq 'ConsoleHost' -and (Get-Module PSReadLine)) {
    try {
        $PredictionViewStyle = "$($Global:UserSettings["Microsoft.PowerShell.Profile:PredictionViewStyle"])"
        if ($PredictionViewStyle -notin @("ListView", "InlineView")) {
            $PredictionViewStyle = "ListView"
        }

        $PredictionMode = "$($Global:UserSettings["Microsoft.PowerShell.Profile:PredictionMode"])"
        if ($PredictionMode -notin @("OnDemand", "Always", "Off")) {
            $PredictionMode = "OnDemand"
        }
        $Global:ProfilePredictionMode = $PredictionMode
        $PredictionToggleKey = "$($Global:UserSettings["Microsoft.PowerShell.Profile:PredictionToggleKey"])"
        if (-not $PredictionToggleKey) {
            $PredictionToggleKey = "Ctrl+Alt+p"
        }

        if (-not [Console]::IsOutputRedirected -and -not [Console]::IsInputRedirected) {
            Set-PSReadLineOption -PredictionViewStyle $PredictionViewStyle
            $initialSource = if ($PredictionMode -eq "Always") { "HistoryAndPlugin" } else { "None" }
            Set-PSReadLineOption -PredictionSource $initialSource

            if ($PredictionMode -eq "OnDemand") {
                Set-PSReadLineKeyHandler -Key $PredictionToggleKey -BriefDescription TogglePredictions -LongDescription "Show or hide history suggestions" -ScriptBlock {
                    $current = (Get-PSReadLineOption).PredictionSource
                    $next = if ($current -eq "None") { "HistoryAndPlugin" } else { "None" }
                    Set-PSReadLineOption -PredictionSource $next
                }
                Set-PSReadLineKeyHandler -Key Enter -BriefDescription AcceptLineHidePredictions -LongDescription "Hide history suggestions and accept the line" -ScriptBlock {
                    if ((Get-PSReadLineOption).PredictionSource -ne "None") {
                        Set-PSReadLineOption -PredictionSource None
                    }
                    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
                }
                Set-PSReadLineKeyHandler -Key Escape -BriefDescription CancelHidePredictions -LongDescription "Hide history suggestions and clear the line" -ScriptBlock {
                    if ((Get-PSReadLineOption).PredictionSource -ne "None") {
                        Set-PSReadLineOption -PredictionSource None
                    }
                    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
                }
            }
        }
        Set-PSReadLineOption -HistoryNoDuplicates
        Set-PSReadLineOption -AddToHistoryHandler {
            param([string]$Line)
            if (Test-ProfileHistorySensitive $Line) {
                return [Microsoft.PowerShell.AddToHistoryOption]::MemoryOnly
            }
            return [Microsoft.PowerShell.AddToHistoryOption]::MemoryAndFile
        }
        Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
        Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    }
    catch {
        Write-Warning "Could not configure PSReadLine: $($_.Exception.Message)"
    }
}
