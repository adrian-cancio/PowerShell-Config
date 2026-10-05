# ----------------------------------
# PromptColorSchemes enum
# ----------------------------------
enum PromptColorSchemes {
    Default
    Blue
    Green
    Cyan
    Red
    Magenta
    Yellow
    Gray
    Random
    Asturias
    Spain
    Hackerman
}

# ----------------------------------
# Color palette (built once per session)
# ----------------------------------
$PromptPalette = @(
    , @([ConsoleColor]::Blue, [ConsoleColor]::DarkBlue)
    , @([ConsoleColor]::Green, [ConsoleColor]::DarkGreen)
    , @([ConsoleColor]::Cyan, [ConsoleColor]::DarkCyan)
    , @([ConsoleColor]::Red, [ConsoleColor]::DarkRed)
    , @([ConsoleColor]::Magenta, [ConsoleColor]::DarkMagenta)
    , @([ConsoleColor]::Yellow, [ConsoleColor]::DarkYellow)
    , @([ConsoleColor]::White, [ConsoleColor]::DarkGray)
    , @([ConsoleColor]::Gray, [ConsoleColor]::DarkGray)
)

$PromptFixedSchemes = @{
    [PromptColorSchemes]::Default   = [ConsoleColor[]]@([ConsoleColor]::White, [ConsoleColor]::DarkGray)
    [PromptColorSchemes]::Blue      = [ConsoleColor[]]@([ConsoleColor]::Blue, [ConsoleColor]::DarkBlue)
    [PromptColorSchemes]::Green     = [ConsoleColor[]]@([ConsoleColor]::Green, [ConsoleColor]::DarkGreen)
    [PromptColorSchemes]::Cyan      = [ConsoleColor[]]@([ConsoleColor]::Cyan, [ConsoleColor]::DarkCyan)
    [PromptColorSchemes]::Red       = [ConsoleColor[]]@([ConsoleColor]::Red, [ConsoleColor]::DarkRed)
    [PromptColorSchemes]::Magenta   = [ConsoleColor[]]@([ConsoleColor]::Magenta, [ConsoleColor]::DarkMagenta)
    [PromptColorSchemes]::Yellow    = [ConsoleColor[]]@([ConsoleColor]::Yellow, [ConsoleColor]::DarkYellow)
    [PromptColorSchemes]::Gray      = [ConsoleColor[]]@([ConsoleColor]::Gray, [ConsoleColor]::DarkGray)
    [PromptColorSchemes]::Asturias  = [ConsoleColor[]]@([ConsoleColor]::Blue, [ConsoleColor]::DarkYellow)
    [PromptColorSchemes]::Spain     = [ConsoleColor[]]@([ConsoleColor]::Red, [ConsoleColor]::DarkYellow)
    [PromptColorSchemes]::Hackerman = [ConsoleColor[]]@([ConsoleColor]::Green, [ConsoleColor]::DarkGray)
}

# ----------------------------------
# Function to set the color scheme
# ----------------------------------
function Set-PromptColorScheme {
    [CmdletBinding()]
    param (
        [PromptColorSchemes]$ColorScheme
    )

    if ($ColorScheme -eq [PromptColorSchemes]::Hackerman) {
        if ($Global:UserSettings["Microsoft.PowerShell.Profile:EnableRandomTitle"]) {
            Set-RandomPowerShellTitle
        }
    }

    if ($ColorScheme -eq [PromptColorSchemes]::Random) {
        $Global:PromptColors = [ConsoleColor[]]@(
            $PromptPalette[[Random]::Shared.Next($PromptPalette.Count)][0],
            $PromptPalette[[Random]::Shared.Next($PromptPalette.Count)][1]
        )
    }
    else {
        $Global:PromptColors = $PromptFixedSchemes[$ColorScheme]
    }
    $Global:UserSettings["Microsoft.PowerShell.Profile:PromptColorScheme"] = $ColorScheme.toString()
}

# ----------------------------------
# Variations for 'Hackerman' title
# ----------------------------------
$RandomP = @("p", "P", "ρ", "¶", "₱", "ℙ", "℗", "𝒫", "𝓟", "𝔓", "𝕻", "𝖯", "𝗣", "𝘗", "𝙋", "𝚙", "𝚙", "𝖕", "𝗽", "𝘱")
$RandomO = @("o", "O", "0", "ø", "ɵ", "º", "θ", "ω", "ჿ", "ᴏ", "ᴑ", "⊝", "Ο", "ο", "𝐨", "𝐎", "𝑂", "𝑜", "𝒐", "𝒪")
$RandomW = @("w", "W", "ω", "ѡ", "ẁ", "ẃ", "ẅ", "ẇ", "ѡ", "ѿ", "ᴡ", "𝐰", "𝑤", "𝑾", "𝒲", "𝓌", "𝔀", "𝔚", "𝔴", "𝕎")
$RandomE = @("e", "E", "3", "€", "є", "ё", "ē", "ė", "ę", "ε", "ξ", "ℯ", "𝐞", "𝐄", "𝑒", "𝐸", "𝑬", "𝓮", "𝔢", "𝔼")
$RandomR = @("r", "R", "®", "ř", "я", "г", "ɾ", "ṛ", "ɼ", "ṟ", "ṙ", "ṝ", "ℛ", "ℜ", "ℝ", "𝐫", "𝑅", "𝓻", "𝔯", "𝕣")
$RandomS = @("s", "S", "5", "$", "§", "∫", "š", "ś", "ş", "ς", "ș", "ƨ", "𝐬", "𝑆", "𝒔", "𝓈", "𝓢", "𝔰", "𝔖", "𝕊")
$RandomH = @("h", "H", "#", "η", "ħ", "һ", "ḥ", "ḧ", "ḩ", "ḣ", "ℎ", "ℋ", "ℌ", "𝒽", "𝐡", "𝐇", "𝐻", "𝒉", "𝓗", "𝕳")
$RandomL = @("l", "L", "1", "!", "|", "ł", "£", "ℓ", "ľ", "ĺ", "ℒ", "Ⅼ", "Ι", "𝐥", "𝐋", "𝑙", "𝐿", "𝑳", "𝓵", "𝓛")

function Set-RandomPowerShellTitle {
    $title = ""
    $title += $RandomP | Get-Random
    $title += $RandomO | Get-Random
    $title += $RandomW | Get-Random
    $title += $RandomE | Get-Random
    $title += $RandomR | Get-Random
    $title += $RandomS | Get-Random
    $title += $RandomH | Get-Random
    $title += $RandomE | Get-Random
    $title += $RandomL | Get-Random
    $title += $RandomL | Get-Random
    $Host.UI.RawUI.WindowTitle = $title
}

[ConsoleColor[]]$PromptColors = @()

# Read if we want the default prompt
$DefaultPrompt = $Global:UserSettings["Microsoft.PowerShell.Profile:DefaultPrompt"]

$Global:PromptTitleSet = $false
$Global:LastPromptHistoryId = -1
$Global:LastSeenExitCode = 0


function Format-PromptDuration {
    param([TimeSpan]$Duration)

    if ($Duration.TotalSeconds -ge 3600) { return "{0}h{1:00}m" -f [int]$Duration.TotalHours, $Duration.Minutes }
    if ($Duration.TotalSeconds -ge 60) { return "{0}m{1:00}s" -f [int]$Duration.TotalMinutes, $Duration.Seconds }
    return "{0:N1}s" -f $Duration.TotalSeconds
}

# ----------------------------------
# Custom Prompt
# ----------------------------------
function Prompt() {
    $LastSuccess = $?
    $LastExitCode = $global:LASTEXITCODE

    if (-not $Global:PromptTitleSet) {
        $Host.UI.RawUI.WindowTitle = "PowerShell"
        $Global:PromptTitleSet = $true
    }

    if ($DefaultPrompt) {
        Write-Host "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1))" -NoNewline
        return " "
    }

    Set-PromptColorScheme -ColorScheme $Global:UserSettings["Microsoft.PowerShell.Profile:PromptColorScheme"]

    $LastCommand = Get-History -Count 1
    $HistoryId = if ($LastCommand) { $LastCommand.Id } else { 0 }
    $IsNewCommand = $HistoryId -ne $Global:LastPromptHistoryId
    $Global:LastPromptHistoryId = $HistoryId

    Write-Host "$OsIcon " -NoNewline -ForegroundColor $PromptColors[1]
    Write-Host "||" -NoNewline -ForegroundColor $PromptColors[1]
    Write-Host $env:USER -NoNewline -ForegroundColor $PromptColors[0]
    Write-Host "@" -NoNewline -ForegroundColor $PromptColors[1]
    Write-Host $HostName -NoNewline -ForegroundColor $PromptColors[0]
    Write-Host "|-|" -NoNewline -ForegroundColor $PromptColors[1]

    $SPWD = if ($PWD.Path.StartsWith($HOME)) {
        "~$([IO.Path]::DirectorySeparatorChar)$($PWD.Path.Substring($HOME.Length))"
    }
    else {
        $PWD.Path
    }
    $DirArray = $SPWD.Split([IO.Path]::DirectorySeparatorChar)

    $IsFirstFolder = $true
    foreach ($FolderName in $DirArray) {
        if ($FolderName.Length -eq 0) {
            continue
        }
        if (!$IsFirstFolder -or ($FolderName -ne "~" -and !$IsWindows)) {
            Write-Host $([IO.Path]::DirectorySeparatorChar) -NoNewline -ForegroundColor $PromptColors[1]
        }
        Write-Host $FolderName -NoNewline -ForegroundColor $PromptColors[0]
        $IsFirstFolder = $false
    }
    Write-Host "||" -NoNewline -ForegroundColor $PromptColors[1]

    if ($IsNewCommand -and $LastCommand) {
        $Failed = -not $LastSuccess
        $Duration = $LastCommand.EndExecutionTime - $LastCommand.StartExecutionTime
        $MinSeconds = [double]$Global:UserSettings["Microsoft.PowerShell.Profile:PromptMinDurationSeconds"]
        if ($MinSeconds -le 0) { $MinSeconds = 2 }

        if ($Failed) {
            $Code = if ($LastExitCode -is [int] -and $LastExitCode -ne 0 -and $LastExitCode -ne $Global:LastSeenExitCode) { $LastExitCode } else { "" }
            Write-Host " ✗$Code" -NoNewline -ForegroundColor Red
        }
        if ($Duration.TotalSeconds -ge $MinSeconds) {
            Write-Host " $(Format-PromptDuration $Duration)" -NoNewline -ForegroundColor $PromptColors[1]
        }
    }
    Write-Host "`n" -NoNewline

    $Git = Get-GitPromptInfo -HistoryId $HistoryId
    if ($Git) {
        Write-Host "|" -NoNewline -ForegroundColor $PromptColors[1]
        Write-Host $Git.Branch -NoNewline -ForegroundColor $PromptColors[0]

        if ($Git.TimedOut) {
            Write-Host " …" -NoNewline -ForegroundColor Yellow
        }
        else {
            if ($Git.Ahead -or $Git.Behind) {
                Write-Host " " -NoNewline
                if ($Git.Ahead) { Write-Host "↑$($Git.Ahead)" -NoNewline -ForegroundColor Green }
                if ($Git.Behind) { Write-Host "↓$($Git.Behind)" -NoNewline -ForegroundColor Red }
            }

            $Flags = @(
                @{ Text = "+$($Git.Staged)"; Count = $Git.Staged; Color = "Green" }
                @{ Text = "~$($Git.Modified)"; Count = $Git.Modified; Color = "Yellow" }
                @{ Text = "?$($Git.Untracked)"; Count = $Git.Untracked; Color = "Gray" }
                @{ Text = "!$($Git.Conflicts)"; Count = $Git.Conflicts; Color = "Red" }
                @{ Text = "`$$($Git.Stash)"; Count = $Git.Stash; Color = "Cyan" }
            )
            $HasChanges = $false
            foreach ($Flag in $Flags) {
                if ($Flag.Count -gt 0) {
                    Write-Host " $($Flag.Text)" -NoNewline -ForegroundColor $Flag.Color
                    $HasChanges = $true
                }
            }
            if (!$HasChanges) {
                Write-Host " ✓" -NoNewline -ForegroundColor Green
            }
        }
    }
    Write-Host $("|>" * ($NestedPromptLevel + 1)) -NoNewline -ForegroundColor $PromptColors[1]

    if ($IsNewCommand) {
        $Global:LastSeenExitCode = $LastExitCode
    }
    $global:LASTEXITCODE = $LastExitCode
    return " "
}