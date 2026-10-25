# Dependency-free regression checks. Run with pwsh -NoProfile -NonInteractive -File.
param([string]$Case)
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
function Assert($Condition, $Message) { if (-not $Condition) { throw $Message } }
Get-ChildItem (Join-Path $Root 'Profile') -Filter *.ps1 | ForEach-Object {
    $ParseErrors = $null
    $null = [Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$ParseErrors)
    Assert (-not $ParseErrors) "Syntax errors: $($_.Name): $ParseErrors"
}
$Source = Get-Content (Join-Path $Root 'Profile/Prompt.ps1') -Raw
if (-not $Case) {
    foreach ($Scenario in @('Custom', 'Default', 'MissingExecutable', 'MissingTheme', 'ExitFailure', 'Empty', 'BadScript', 'Partial', 'NoPrompt', 'Real')) {
        & pwsh -NoProfile -NonInteractive -File $PSCommandPath -Case $Scenario
        Assert ($LASTEXITCODE -eq 0) "Failed scenario: $Scenario"
    }
    return
}
# Run at session scope, like the actual dot-sourced profile loader.

        $ProfileModuleRoot = Join-Path $Root 'Profile'
        $Global:UserSettings = @{
            'Microsoft.PowerShell.Profile:PromptEngine' = 'OhMyPosh'
            'Microsoft.PowerShell.Profile:DefaultPrompt' = ($Case -eq 'Default')
            'Microsoft.PowerShell.Profile:OhMyPoshTheme' = 'Themes/gruvbox.omp.json'
            'Microsoft.PowerShell.Profile:PromptColorScheme' = 'Default'
        }
        if ($Case -eq 'Custom') { $Global:UserSettings['Microsoft.PowerShell.Profile:PromptEngine'] = 'Custom' }
        if ($Case -eq 'MissingTheme') { $Global:UserSettings['Microsoft.PowerShell.Profile:OhMyPoshTheme'] = 'missing.omp.json' }
        $global:LASTEXITCODE = 73
        if ($Case -notin @('Custom', 'Default', 'Real', 'MissingTheme')) {
            function Get-Command {
                param($Name, $CommandType, $ErrorAction)
                if ($Case -eq 'MissingExecutable') { throw 'not installed' }
                [pscustomobject]@{ Source = 'Invoke-FakePosh' }
            }
            function Invoke-FakePosh {
                $global:LASTEXITCODE = 0
                switch ($Case) {
                    'ExitFailure' { $global:LASTEXITCODE = 9; 'throw "should not evaluate"' }
                    'Empty' { '' }
                    'BadScript' { 'function {' }
                    'Partial' { 'function global:prompt { "BROKEN" }; throw "partial init"' }
                    'NoPrompt' { '$null = 1' }
                }
            }
        }
        . ([scriptblock]::Create($Source))
        Assert ($global:LASTEXITCODE -eq 73) "$Case changed LASTEXITCODE"
        if ($Case -eq 'Real') {
            Assert ($function:prompt.ToString() -notmatch 'Get-GitPromptInfo') 'Real OMP did not replace Custom'
            $Rendered = prompt
            Assert ($Rendered -notmatch 'Get-GitPromptInfo|template error|unable to create') 'Real prompt rendering failed'
        }
        else {
            Assert ($function:prompt.ToString() -match 'Get-GitPromptInfo') "$Case did not preserve Custom"
        }
        Write-Host "PASS $Case"
Write-Host 'PASS syntax and loader-compatible relative theme resolution'
