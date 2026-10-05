function Get-ProfileDataDirectory {
    if ($env:POWERSHELL_PROFILE_DATA) {
        $path = $env:POWERSHELL_PROFILE_DATA
    }
    else {
        $base = if ($IsWindows) {
            $env:LOCALAPPDATA
        }
        elseif ($env:XDG_DATA_HOME) {
            $env:XDG_DATA_HOME
        }
        else {
            Join-Path $HOME ".local/share"
        }
        $path = Join-Path $base "PowerShell-Profile"
    }

    if (-not (Test-Path -LiteralPath $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
    return $path
}

function Find-ProfileExecutable {
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name
    )

    $extensions = if ($IsWindows -and -not [IO.Path]::HasExtension($Name)) {
        @(".exe", ".cmd", ".bat", ".com")
    }
    else {
        @("")
    }

    foreach ($directory in ($env:PATH -split [IO.Path]::PathSeparator)) {
        if (-not $directory) {
            continue
        }
        foreach ($extension in $extensions) {
            $candidate = [IO.Path]::Combine($directory, $Name + $extension)
            if ([IO.File]::Exists($candidate)) {
                return $candidate
            }
        }
    }
    return $null
}
