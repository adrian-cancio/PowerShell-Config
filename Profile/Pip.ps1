# ---------------------------------------------------------------------------
# PIP WRAPPER FUNCTIONS
# ---------------------------------------------------------------------------

# Find original pip executables by their full path to avoid alias conflicts
$Global:OriginalPipPath = $null
$Global:OriginalPip3Path = $null

function Get-OriginalPipPath {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('pip', 'pip3')]
        [string]$Name
    )

    $variableName = if ($Name -eq 'pip') { 'OriginalPipPath' } else { 'OriginalPip3Path' }
    $cachedPath = Get-Variable -Name $variableName -Scope Global -ValueOnly -ErrorAction SilentlyContinue
    if ($cachedPath -and (Test-Path -LiteralPath $cachedPath)) {
        return $cachedPath
    }

    $command = Get-Command -Name $Name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    $resolvedPath = if ($command) { $command.Source } else { $null }
    Set-Variable -Name $variableName -Scope Global -Value $resolvedPath
    return $resolvedPath
}

function Invoke-PipCommand {
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateSet('pip', 'pip3')]
        [string]$Name,

        [Parameter(Position = 1)]
        [object[]]$PipArguments = @()
    )

    $pipPath = Get-OriginalPipPath -Name $Name
    if (-not $pipPath) {
        Write-Error "${Name}: command not found"
        return
    }

    # If this is an install command and we're not in a virtual environment, show warning
    if ($PipArguments -and $PipArguments[0] -eq "install" -and -not $env:VIRTUAL_ENV -and -not $env:CONDA_DEFAULT_ENV) {
        $hasGlobalFlag = $PipArguments -contains "--global"

        if (-not $hasGlobalFlag) {
            Write-Host ""
            Write-Host "⚠️  WARNING: Installing packages globally (not in virtual environment)." -ForegroundColor Yellow
            Write-Host "Recommended: " -ForegroundColor Gray -NoNewline
            Write-Host "python -m venv venv" -ForegroundColor Green -NoNewline
            Write-Host " then activate it." -ForegroundColor Gray
            Write-Host "Or use: " -ForegroundColor Gray -NoNewline
            Write-Host "$Name install $($PipArguments[1]) --global" -ForegroundColor Yellow
            Write-Host ""
            if ([Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
                Write-Host "Press Enter to continue or Ctrl+C to cancel."
                $null = Read-Host
            }
        }

        # Remove custom --global flag
        $cleanArgs = $PipArguments | Where-Object { $_ -ne "--global" }
        & $pipPath @cleanArgs
    }
    else {
        # For all other commands, just pass through directly
        & $pipPath @PipArguments
    }
}

function Invoke-PipWrapper {
    Invoke-PipCommand 'pip' $args
}

function Invoke-Pip3Wrapper {
    Invoke-PipCommand 'pip3' $args
}
