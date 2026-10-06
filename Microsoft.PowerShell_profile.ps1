$ProfileModuleRoot = Join-Path $PSScriptRoot "Profile"

$ProfileParts = @(
    "Settings.ps1"
    "Common.ps1"
    "Git.ps1"
    "Prompt.ps1"
    "Utilities.ps1"
    "Shortcuts.ps1"
    "Pip.ps1"
    "Copilot.ps1"
    "SecureApiKey.ps1"
    "GeminiTools.ps1"
    "GeminiChat.ps1"
    "GeminiCommit.ps1"
    "Aliases.ps1"
    "Completions.ps1"
    "Diagnostics.ps1"
)

$Global:ProfileLoadTimings = [Collections.Generic.List[object]]::new()

foreach ($ProfilePart in $ProfileParts) {
    $ProfilePartPath = Join-Path $ProfileModuleRoot $ProfilePart
    if (-not (Test-Path -LiteralPath $ProfilePartPath)) {
        Write-Warning "Profile part not found: $ProfilePartPath"
        continue
    }
    $ProfilePartTimer = [Diagnostics.Stopwatch]::StartNew()
    try {
        . ([scriptblock]::Create([IO.File]::ReadAllText($ProfilePartPath)))
    }
    catch {
        Write-Warning "Failed to load profile part '$ProfilePart': $($_.Exception.Message)"
    }
    $Global:ProfileLoadTimings.Add([PSCustomObject]@{ Part = $ProfilePart; Milliseconds = $ProfilePartTimer.Elapsed.TotalMilliseconds })
}

if ($Global:UserSettings["Microsoft.PowerShell.Profile:EnableMathModule"] -ne $false) {
    $MathModulePath = Join-Path $ProfileModuleRoot "Math.psm1"
    $ProfilePartTimer = [Diagnostics.Stopwatch]::StartNew()
    if (Test-Path -LiteralPath $MathModulePath) {
        try {
            Import-Module $MathModulePath -Global -DisableNameChecking -ErrorAction Stop
        }
        catch {
            Write-Warning "Failed to load Math module: $($_.Exception.Message)"
        }
        $Global:ProfileLoadTimings.Add([PSCustomObject]@{ Part = "Math.psm1"; Milliseconds = $ProfilePartTimer.Elapsed.TotalMilliseconds })
    }
    else {
        Write-Warning "Profile part not found: $MathModulePath"
    }
}

Remove-Variable ProfileModuleRoot, ProfileParts, ProfilePart, ProfilePartPath, ProfilePartTimer, MathModulePath -ErrorAction SilentlyContinue
