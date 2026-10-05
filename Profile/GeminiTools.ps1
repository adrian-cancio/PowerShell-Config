# ---------------------------------------------------------------------------
# GEMINI CHAT FUNCTIONS (Cross-Platform)
# ---------------------------------------------------------------------------

<#
.SYNOPSIS
Analyzes PowerShell code for potential system risks.

.DESCRIPTION
This function analyzes PowerShell code to determine if it contains commands that could
affect the system (files, users, network, etc.) and require user confirmation.

.PARAMETER Code
The PowerShell code to analyze.

.RETURNS
Returns $true if the code is potentially risky and requires confirmation, $false otherwise.
#>
function Test-PowerShellCodeRisk {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Code
    )

    # Define risky command patterns (cross-platform)
    $riskyPatterns = @(
        # File system operations
        '(Remove-Item|rm|del|Delete)',
        '(New-Item|mkdir|md)',
        '(Copy-Item|cp|copy)',
        '(Move-Item|mv|move)',
        '(Rename-Item|ren|rename)',
        '(Set-Content|Out-File)',
        '(Add-Content|>>)',
        '>\s*[^|]',  # Redirection to file (not pipe)
        '>\s*\$',    # Redirection to end of line

        # Registry operations (Windows)
        '(New-ItemProperty|Set-ItemProperty|Remove-ItemProperty)',
        '(New-PSDrive|Remove-PSDrive)',
        'HKEY_|HKLM:|HKCU:|Registry::',

        # Service and process management
        '(Start-Service|Stop-Service|Restart-Service)',
        '(Start-Process|Stop-Process|Kill)',
        '(Get-Service|Set-Service)',

        # Network operations
        '(Invoke-WebRequest|Invoke-RestMethod|wget|curl)',
        '(Start-Job|Receive-Job)',
        '(Enter-PSSession|New-PSSession)',

        # User and security management
        '(New-LocalUser|Remove-LocalUser|Set-LocalUser)',
        '(Add-LocalGroupMember|Remove-LocalGroupMember)',
        '(Set-ExecutionPolicy)',
        '(Import-Module.*-Force)',

        # System configuration
        '(Set-ItemProperty.*-Path.*HKLM)',
        '(Set-Location.*System32|Set-Location.*Windows)',
        '(Start-Sleep\s+\d{4,})', # Very long sleeps

        # Dangerous cmdlets
        '(Invoke-Expression|iex)',
        '(Invoke-Command)',
        '(Start-Transcript|Stop-Transcript)',

        # File downloads or execution
        '(DownloadString|DownloadFile)',
        '(Start-BitsTransfer)',
        '\.exe\s|\.msi\s|\.bat\s|\.cmd\s',

        # Unix/Linux specific dangerous operations
        '(sudo|su\s)',
        '(chmod\s+[0-7]{3,4})',
        '(chown|chgrp)',
        '(mount|umount)',
        '(fdisk|mkfs)',
        '(systemctl|service)',
        '(useradd|userdel|usermod)',
        '(groupadd|groupdel)',
        '(passwd|chpasswd)',
        '(crontab|at\s)',
        '(iptables|ufw)',
        '(ssh-keygen|ssh-copy-id)',

        # Package management (risky installations)
        '(apt|yum|dnf|brew|pip|npm).*install',
        '(dpkg|rpm).*-i',

        # macOS specific operations
        '(launchctl)',
        '(dscl|dseditgroup)',
        '(csrutil|spctl)',
        '(diskutil)',

        # Shell execution patterns
        '(bash|sh|zsh|fish).*-c',
        '(/bin/|/usr/bin/)',
        '&\s*$',  # Background execution
        ';\s*(rm|del)'  # Command chaining with deletion
    )

    # Check for risky patterns
    foreach ($pattern in $riskyPatterns) {
        if ($Code -match $pattern) {
            return $true
        }
    }

    # Check for file paths that could be system critical (cross-platform)
    $systemPaths = @(
        # Windows critical paths
        'C:\\Windows\\',
        'C:\\Program Files',
        'C:\\Users\\.*\\AppData',
        '\$env:WINDIR',
        '\$env:PROGRAMFILES',
        '\$env:PROGRAMDATA',
        '\$env:SYSTEMROOT',

        # Linux/Unix critical paths
        '/etc/',
        '/bin/',
        '/sbin/',
        '/usr/bin/',
        '/usr/sbin/',
        '/usr/local/bin/',
        '/root/',
        '/boot/',
        '/sys/',
        '/proc/',
        '/dev/',
        '/var/log/',
        '/var/run/',
        '/tmp/.*\.sh',
        '/opt/',
        '\$HOME/\.config',
        '\$HOME/\.local',

        # macOS specific paths
        '/System/',
        '/Library/',
        '/Applications/',
        '/Users/.*/Library/',
        '/private/',
        '/usr/local/',
        '\$HOME/Library/'
    )

    foreach ($path in $systemPaths) {
        if ($Code -match $path) {
            return $true
        }
    }

    return $false
}

<#
.SYNOPSIS
Executes PowerShell code safely with risk analysis.

.DESCRIPTION
This function executes PowerShell code after analyzing it for potential risks.
Risky code requires user confirmation before execution.

.PARAMETER Code
The PowerShell code to execute.

.PARAMETER AutoApprove
If true, skips confirmation for risky code (use with caution).

.RETURNS
Returns an object with ExecutionResult, Output, Error, and WasRisky properties.
#>
function Invoke-SafePowerShellCode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Code,

        [switch]$AutoApprove
    )

    $result = [PSCustomObject]@{
        ExecutionResult = $null
        Output = ""
        Error = ""
        WasRisky = $false
        UserApproved = $false
        Executed = $false
    }

    # Clean the code (remove code block markers if present)
    $cleanCode = $Code -replace '^```(?:powershell|ps1)?\s*', '' -replace '```\s*$', ''
    $cleanCode = $cleanCode.Trim()

    if ([string]::IsNullOrWhiteSpace($cleanCode)) {
        $result.Error = "No code provided to execute"
        return $result
    }

    # Analyze code for risks
    $isRisky = Test-PowerShellCodeRisk -Code $cleanCode
    $result.WasRisky = $isRisky

    # If risky and not auto-approved, ask for confirmation
    if ($isRisky -and -not $AutoApprove.IsPresent) {
        Write-Host "`n" -NoNewline
        Write-Host "[SECURITY WARNING]" -ForegroundColor White -BackgroundColor DarkRed
        Write-Host " The following code may affect your system:" -ForegroundColor Yellow
        Write-Host "`n--- CODE TO EXECUTE ---" -ForegroundColor Cyan
        Write-Host $cleanCode -ForegroundColor Gray
        Write-Host "--- END CODE ---`n" -ForegroundColor Cyan

        do {
            $confirmation = Read-Host "Do you want to execute this code? (y/N/s=show again)"
            $confirmation = $confirmation.ToLower()

            if ($confirmation -eq 's') {
                Write-Host "`n--- CODE TO EXECUTE ---" -ForegroundColor Cyan
                Write-Host $cleanCode -ForegroundColor Gray
                Write-Host "--- END CODE ---`n" -ForegroundColor Cyan
                continue
            }
        } while ($confirmation -eq 's')

        if ($confirmation -ne 'y' -and $confirmation -ne 'yes') {
            $result.Error = "Code execution cancelled by user"
            return $result
        }

        $result.UserApproved = $true
    }

    # Execute the code
    try {
        $result.Executed = $true

        # Capture both output and errors
        $scriptBlock = [ScriptBlock]::Create($cleanCode)
        $job = Start-Job -ScriptBlock $scriptBlock

        # Wait for job completion with timeout (30 seconds)
        $timeoutSeconds = 30
        $job | Wait-Job -Timeout $timeoutSeconds | Out-Null

        if ($job.State -eq 'Running') {
            $job | Stop-Job
            $result.Error = "Code execution timed out after $timeoutSeconds seconds"
        }
        elseif ($job.State -eq 'Completed') {
            $output = Receive-Job -Job $job 2>&1

            # Separate output and errors
            $outputLines = @()
            $errorLines = @()

            foreach ($item in $output) {
                if ($item -is [System.Management.Automation.ErrorRecord]) {
                    $errorLines += $item.ToString()
                }
                else {
                    $outputLines += $item.ToString()
                }
            }

            $result.Output = ($outputLines -join "`n").Trim()
            $result.Error = ($errorLines -join "`n").Trim()
            $result.ExecutionResult = "Success"
        }
        else {
            $result.Error = "Code execution failed with state: $($job.State)"
            $result.ExecutionResult = "Failed"
        }

        # Clean up the job
        Remove-Job -Job $job -Force
    }
    catch {
        $result.Error = "Execution error: $($_.Exception.Message)"
        $result.ExecutionResult = "Error"
    }

    return $result
}

<#
.SYNOPSIS
Processes PowerShell format commands embedded in text and renders them with proper styling.

.DESCRIPTION
This function processes special format commands that Gemini can use to apply text styling
in PowerShell terminals. It supports colors, formatting, and cross-platform compatibility.

.PARAMETER Text
The text containing format commands to process.

.EXAMPLE
Format-GeminiText "This is [FG:Red]red text[/FG] and [BG:Yellow]yellow background[/BG]"
#>
function Format-GeminiText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    # Split text by format commands while preserving the commands
    $parts = $Text -split '(\[(?:FG|BG|STYLE):[^\]]+\]|\[/(?:FG|BG|STYLE)\])'

    $currentFG = $null
    $currentBG = $null
    $currentStyle = @()

    foreach ($part in $parts) {
        if ([string]::IsNullOrEmpty($part)) { continue }

        # Check if this part is a format command
        if ($part -match '^\[(\w+):([^\]]+)\]$') {
            $command = $matches[1]
            $value = $matches[2]

            switch ($command) {
                "FG" {
                    $currentFG = $value
                }
                "BG" {
                    $currentBG = $value
                }
                "STYLE" {
                    if ($value -notin $currentStyle) {
                        $currentStyle += $value
                    }
                }
            }
        }
        elseif ($part -match '^\[/(\w+)\]$') {
            $command = $matches[1]

            switch ($command) {
                "FG" { $currentFG = $null }
                "BG" { $currentBG = $null }
                "STYLE" { $currentStyle = @() }
            }
        }
        else {
            # This is regular text, output it with current formatting
            $writeParams = @{
                Object    = $part
                NoNewline = $true
            }

            if ($currentFG) {
                try {
                    $writeParams.ForegroundColor = [ConsoleColor]$currentFG
                }
                catch {
                    # If color name is invalid, ignore it
                }
            }

            if ($currentBG) {
                try {
                    $writeParams.BackgroundColor = [ConsoleColor]$currentBG
                }
                catch {
                    # If color name is invalid, ignore it
                }
            }

            Write-Host @writeParams
        }
    }
}
