# Real OMP rendering with environment overrides confined to child processes.
param([string]$ScratchRoot = (Join-Path ([IO.Path]::GetTempPath()) 'posh-context-tests'))
$ErrorActionPreference = 'Stop'
function Assert($Condition, $Message) { if (-not $Condition) { throw $Message } }
$Theme = Join-Path (Split-Path -Parent $PSScriptRoot) 'Themes/gruvbox.omp.json'
$Omp = (Get-Command oh-my-posh -CommandType Application | Select-Object -First 1).Source
$Python = (Get-Command python3, python -CommandType Application | Select-Object -First 1).Source
$Scratch = Join-Path $ScratchRoot ([guid]::NewGuid().ToString())
$null = New-Item $Scratch -ItemType Directory -Force
$Venv = Join-Path $Scratch 'context-trial'
& $Python -m venv --without-pip $Venv
Assert ($LASTEXITCODE -eq 0) 'Could not create temporary venv'
$Project = Join-Path $Scratch 'project'
$null = New-Item $Project -ItemType Directory
Set-Content (Join-Path $Project 'main.py') 'print("test")'
Set-Content (Join-Path $Project 'pyproject.toml') '[project]'
if ($IsWindows) {
    $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Elevated = ([Security.Principal.WindowsPrincipal]::new($Identity)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
} else {
    $Elevated = ((& id -u) -eq '0')
}
function Render([string]$Label, [hashtable]$Overrides, [string]$Directory = $Scratch) {
    $Info = [Diagnostics.ProcessStartInfo]::new($Omp)
    $Info.UseShellExecute = $false
    $Info.RedirectStandardOutput = $true
    $Info.RedirectStandardError = $true
    $Info.WorkingDirectory = $Directory
    foreach ($Name in @('VIRTUAL_ENV', 'CONDA_DEFAULT_ENV', 'CONDA_PREFIX', 'SSH_CONNECTION', 'SSH_CLIENT', 'SSH_TTY')) { $null = $Info.Environment.Remove($Name) }
    foreach ($Name in $Overrides.Keys) { $Info.Environment[$Name] = $Overrides[$Name] }
    foreach ($Argument in @('print', 'primary', '--config', $Theme, '--plain', '--shell', 'pwsh', '--pwd', $Directory, '--status', '0')) { $Info.ArgumentList.Add($Argument) }
    $Process = [Diagnostics.Process]::Start($Info)
    $Text = $Process.StandardOutput.ReadToEnd()
    $Errors = $Process.StandardError.ReadToEnd()
    $Process.WaitForExit()
    Assert ($Process.ExitCode -eq 0) "$Label failed: $Errors"
    Assert ($Text -notmatch 'template error|unable to create|<nil>') "$Label template error: $Text"
    Assert (($Text.TrimEnd() -split '\r?\n').Count -eq 2) "$Label changed two-line layout"
    Assert ($Text.Contains('[ADMIN]') -eq $Elevated) "$Label elevation disagrees with actual identity"
    Write-Host "PASS $Label`n$Text"
    return $Text
}
$Default = Render 'Default environment' @{}
Assert ($Default -notmatch '\[py:|\[SSH\]') 'Default has conditional clutter'
$Ssh = Render 'Simulated SSH environment' @{ SSH_CONNECTION = '192.0.2.1 12345 192.0.2.2 22' }
Assert ($Ssh -match '\[SSH\]') 'SSH environment not detected'
$Active = Render 'Actual temporary venv via activation environment' @{ VIRTUAL_ENV = $Venv; PATH = ((Join-Path $Venv $(if ($IsWindows) { 'Scripts' } else { 'bin' })) + [IO.Path]::PathSeparator + $env:PATH) }
Assert ($Active -match '\[py:context-trial\]') 'Active venv name missing'
$Inactive = Render 'Python project without active environment' @{} $Project
Assert ($Inactive -notmatch '\[py:') 'Python project alone enabled environment indicator'
$Conda = Render 'Simulated conda activation environment' @{ CONDA_DEFAULT_ENV = 'context-conda'; CONDA_PREFIX = $Venv }
Assert ($Conda -match '\[py:context-conda\]') 'Conda environment name missing'
Write-Host "Actual identity elevated: $Elevated. No elevation was simulated. Scratch retained: $Scratch"
