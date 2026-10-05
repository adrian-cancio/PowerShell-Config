function .. { Set-Location -LiteralPath (Join-Path ".." "") }
function ... { Set-Location -LiteralPath (Join-Path ".." "..") }
function .... { Set-Location -LiteralPath (Join-Path ".." (Join-Path ".." "..")) }

function mkcd {
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path
    )

    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    Set-Location -LiteralPath $Path
}

function cdc {
    param(
        [Parameter(Position = 0)]
        [string]$Project = ""
    )

    $target = if ($Project) { Join-Path $CODE $Project } else { $CODE }
    if (-not (Test-Path -LiteralPath $target -PathType Container)) {
        Write-Error "Folder '$target' does not exist"
        return
    }
    Set-Location -LiteralPath $target
}

function gst { git status -sb @args }
function gd { git diff @args }
function gds { git diff --staged @args }
function ga { git add @args }
function gaa { git add --all @args }
function gco { git checkout @args }
function gsw { git switch @args }
function gpull { git pull @args }
function gpush { git push @args }
function glog { git log --oneline --graph --decorate -n 20 @args }

function gcmsg {
    param(
        [Parameter(Mandatory, Position = 0, ValueFromRemainingArguments)]
        [string[]]$Message
    )

    git commit -m ($Message -join " ")
}

function gundo {
    git reset --soft HEAD~1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Last commit undone. Its changes are staged." -ForegroundColor Yellow
    }
}

if ($Global:UserSettings["Microsoft.PowerShell.Profile:EnableZoxide"] -ne $false -and (Find-ProfileExecutable "zoxide")) {
    try {
        Invoke-Expression (& { (zoxide init powershell | Out-String) })
    }
    catch {
        Write-Warning "Could not initialize zoxide: $($_.Exception.Message)"
    }
}
