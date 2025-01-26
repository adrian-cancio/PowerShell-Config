# ----------------------------------
# 1) Path for the Settings File
# ----------------------------------
$ProfileFolder = Split-Path -Parent $PROFILE
$Global:SettingsFile = Join-Path $ProfileFolder "pwshProfileSettings.json"

# ----------------------------------
# 2) Default Values
# ----------------------------------
$Global:DefaultSettings = [ordered]@{
    "PromptColorScheme"    = "Random"        # Default prompt color scheme
    "DefaultPrompt"        = $false          # If true, use PowerShell's default prompt instead of the custom one
    "AskCreateCodeFolder"  = $true           # Whether to ask for the creation of the "Code" folder if missing
    "CodeFolderName"       = "Code"          # Default name for the code folder
    "EnableRandomTitle"    = $false          # Enables "Hackerman" style random PowerShell title
}

# ----------------------------------
# 3) Function to Load User Settings
# ----------------------------------
function Load-UserSettings {
    param(
        [string]$Path
    )

    # If the file does not exist, create it using default values
    if (-not (Test-Path $Path)) {
        Write-Host "File '$Path' does not exist. Creating default settings file..."
        $DefaultJson = ($Global:DefaultSettings | ConvertTo-Json -Depth 10)
        $DefaultJson | Out-File -FilePath $Path -Encoding UTF8
        return $Global:DefaultSettings
    }
    else {
        # Try to read and parse JSON
        try {
            $jsonContent = Get-Content -Path $Path -Raw
            $parsed = $null
            if ($jsonContent) {
                $parsed = $jsonContent | ConvertFrom-Json
            }

            if (-not $parsed) {
                Write-Warning "The file '$Path' is empty or not valid JSON. Default values will be used."
                return $Global:DefaultSettings
            }

            # Convert the $parsed object to a hashtable and merge with DefaultSettings
            $userSettings = @{}
            foreach ($key in $parsed.psobject.Properties.Name) {
                $userSettings[$key] = $parsed."$key"
            }

            # For each default key, if not present in userSettings, assign the default one
            foreach ($defaultKey in $Global:DefaultSettings.Keys) {
                if (-not $userSettings.ContainsKey($defaultKey)) {
                    $userSettings[$defaultKey] = $Global:DefaultSettings[$defaultKey]
                }
            }

            return $userSettings
        }
        catch {
            Write-Warning "Could not read or parse '$Path': $_"
            Write-Warning "Default values will be used."
            return $Global:DefaultSettings
        }
    }
}

# ----------------------------------
# 4) Load settings into a global variable
# ----------------------------------
$Global:UserSettings = Load-UserSettings $Global:SettingsFile

# ----------------------------------
# 5) Functions to Save User Settings (optional)
#    Use them if you want to modify values and
#    persist them into the JSON file.
# ----------------------------------
function Save-UserSettings {
    param(
        [hashtable]$NewSettings
    )
    $json = $NewSettings | ConvertTo-Json -Depth 10
    $json | Out-File -FilePath $Global:SettingsFile -Encoding UTF8
}

Enum OS {
    Windows
    Linux
    MacOS
}

$Kernel = if ($IsWindows) {
    [OS]::Windows
}
elseif ($IsLinux) {
    [OS]::Linux
}
elseif ($IsMacOS) {
    [OS]::MacOS
}

[String]$SPWD
$DirArray = @()

# ------------------------------------------------------
# Handle 'Code' folder based on loaded User Settings
# ------------------------------------------------------
$CODE = Join-Path -Path $HOME -ChildPath $Global:UserSettings["CodeFolderName"]
$AskCreateCodeFolder = $Global:UserSettings["AskCreateCodeFolder"]

if (!(Test-Path -Path $CODE) -and $AskCreateCodeFolder) {
    $CreateCodeFolder = Read-Host "`'$CODE`' folder not exists, create it? (Y/N)"
    if ($CreateCodeFolder -eq "Y") {
        New-Item -Path $CODE -ItemType Directory | Out-Null
    }
}

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
# Function to set the color scheme
# ----------------------------------
function Set-PromptColorScheme {
    [CmdletBinding()]
    param (
        [PromptColorSchemes]$ColorScheme
    )

    if ($ColorScheme -eq [PromptColorSchemes]::Hackerman) {
        if ($Global:UserSettings["EnableRandomTitle"]) {
            Set-RandomPowerShellTitle
        }
    }

    # Color palette
    $Colors = @{
        "Blue"    = @([ConsoleColor]::Blue, [ConsoleColor]::DarkBlue)
        "Green"   = @([ConsoleColor]::Green, [ConsoleColor]::DarkGreen)
        "Cyan"    = @([ConsoleColor]::Cyan, [ConsoleColor]::DarkCyan)
        "Red"     = @([ConsoleColor]::Red, [ConsoleColor]::DarkRed)
        "Magenta" = @([ConsoleColor]::Magenta, [ConsoleColor]::DarkMagenta)
        "Yellow"  = @([ConsoleColor]::Yellow, [ConsoleColor]::DarkYellow)
        "White"   = @([ConsoleColor]::White, [ConsoleColor]::DarkGray)
        "Gray"    = @([ConsoleColor]::Gray, [ConsoleColor]::DarkGray)
    }

    $ColorSchemes = @{
        [PromptColorSchemes]::Default   = $Colors["White"]
        [PromptColorSchemes]::Blue      = $Colors["Blue"]
        [PromptColorSchemes]::Green     = $Colors["Green"]
        [PromptColorSchemes]::Cyan      = $Colors["Cyan"]
        [PromptColorSchemes]::Red       = $Colors["Red"]
        [PromptColorSchemes]::Magenta   = $Colors["Magenta"]
        [PromptColorSchemes]::Yellow    = $Colors["Yellow"]
        [PromptColorSchemes]::Gray      = $Colors["Gray"]
        [PromptColorSchemes]::Random    = @(
            $Colors[$($Colors.Keys | Get-Random)][0],
            $Colors[$($Colors.Keys | Get-Random)][1]
        )
        [PromptColorSchemes]::Asturias  = @($Colors["Blue"][0], $Colors["Yellow"][1])
        [PromptColorSchemes]::Spain     = @($Colors["Red"][0], $Colors["Yellow"][1])
        [PromptColorSchemes]::Hackerman = @($Colors["Green"][0], $Colors["Gray"][1])
    }

    $Global:PromptColorScheme = $ColorScheme
    $Global:PromptColors = $ColorSchemes[$ColorScheme]
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

# Read preferred color scheme from the settings
$desiredColorScheme = $Global:UserSettings["PromptColorScheme"] -as [PromptColorSchemes]
if (-not $desiredColorScheme) {
    $desiredColorScheme = [PromptColorSchemes]::Random
}

# Read if we want the default prompt
$DefaultPrompt = $Global:UserSettings["DefaultPrompt"]

# ----------------------------------
# Custom Prompt
# ----------------------------------
function Prompt() {

    # Always set a window title
    $Host.UI.RawUI.WindowTitle = "PowerShell"

    if ($DefaultPrompt) {
        Write-Host "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1))" -NoNewline
        return " "
    }

    # Set the color scheme
    Set-PromptColorScheme -ColorScheme $desiredColorScheme

    Write-Host "||" -NoNewline -ForegroundColor $PromptColors[1]
    Write-Host $env:USER -NoNewline -ForegroundColor $PromptColors[0]
    Write-Host "@" -NoNewline -ForegroundColor $PromptColors[1]
    Write-Host $Kernel -NoNewline -ForegroundColor $PromptColors[0]
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

    Write-Host "||`n" -NoNewline -ForegroundColor $PromptColors[1]
    Write-Host $("|>" * ($NestedPromptLevel + 1)) -NoNewline -ForegroundColor $PromptColors[1]
    return " "
}

# ---------------------------------------------------------------------------
# OTHER FUNCTIONS (mostly unchanged, just relocated in the profile)
# ---------------------------------------------------------------------------
function Set-PWDClipboard {
    Set-Clipboard $PWD
}

function Get-PublicIP {
    $PublicIP = Invoke-RestMethod -Uri "https://api.ipify.org"
    return $PublicIP
}

function Get-DiskSpace {
    $drives = Get-PSDrive -PSProvider FileSystem | ForEach-Object {
        [PSCustomObject]@{
            Drive   = $_.Name
            UsedGB  = [math]::round(($_.Used / 1GB), 2)
            FreeGB  = [math]::round(($_.Free / 1GB), 2)
            TotalGB = [math]::round(($_.Used + $_.Free) / 1GB, 2)
        }
    }
    $drives | Format-Table -AutoSize
}

function Get-Weather {
    param (
        [string]$Place,
        [String]$Language
    )

    if (-not $Place) {
        # Get current city from IP
        $Place = (Invoke-RestMethod -Uri "https://ipinfo.io").city
        while (-not $Place) {
            $Place = (Invoke-RestMethod -Uri "https://ipinfo.io").city
            Start-Sleep -Seconds 1
        }
    }

    if (-not $Language) {
        $Language = (Get-Culture).Name.Substring(0, 2)
    }

    $Response = ""
    try {
        $RequestUri = "https://wttr.in/~$Place?lang=$Language"
        $Response = Invoke-RestMethod -Uri $RequestUri -ErrorAction SilentlyContinue
    }
    catch {
        return "Error: The place '$Place' is not found"
    }

    return $Response
}

function Get-ChtShHelp {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Command
    )
    try {
        $response = Invoke-WebRequest -Uri "https://cht.sh/$Command" -UseBasicParsing
        return $response.Content
    }
    catch {
        Write-Error "Failed to retrieve help for the command '$Command'. Check your connection or the command entered."
    }
}

function Get-PowershellChtShHelp {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Command
    )
    Get-ChtShHelp -Command "powershell/$Command"
}

function Stop-ProcessConstantly {
    param (
        [Parameter(Mandatory)]
        [string]$ProcessName
    )

    $i = 0
    while ($true) {
        try {
            Stop-Process -Name $ProcessName -ErrorAction Stop
            $i++
            Write-Host "[$i] - Process '$ProcessName' stopped successfully." -ForegroundColor Green
        }
        catch {
            continue
        }
    }
}

# Aliases
Set-Alias -Name vim -Value nvim
Set-Alias -Name vi -Value vim
Set-Alias -Name gvim -Value vim
Set-Alias -Name wrh -Value Write-Host
Set-Alias -Name cpwd -Value Set-PWDClipboard

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
            Invoke-Expression $executeCommand
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
