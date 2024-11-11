if ($env:USER.length -eq 0) {
    $env:USER = $env:USERNAME
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

$CODE = Join-Path -Path $HOME -ChildPath "Code"
# If code folder not exists, ask user to create it
$AskCreateCodeFolder = $true
if (!(Test-Path -Path $CODE) -and $AskCreateCodeFolder) {
    $CreateCodeFolder = Read-Host "`'$CODE`' folder not exists, create it? (Y/N)"
    if ($CreateCodeFolder -eq "Y") {
        New-Item -Path $CODE -ItemType Directory
    }
}

enum PromptColorSchemes {
    # Normal Schemes
    Default
    Blue
    Green
    Cyan
    Red
    Magenta
    Yellow
    Gray
    # Special Schemes
    Random
    Asturias
    Spain
    Hackerman
}

function Set-PromptColorScheme {
    [CmdletBinding()]
    param (
        [PromptColorSchemes]$ColorScheme = $PromptColorScheme
    )

    if ($ColorScheme -eq $ColorScheme::Hackerman) {
        Set-RandomPowerShellTitle
    }

    # Primary Colors: Blue, Green Cyan, Red, Magenta, Yellow, White, Gray
    
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
        [PromptColorSchemes]::Random    = @($Colors[$($Colors.Keys | Get-Random)][0], $Colors[$($Colors.Keys | Get-Random)][1])
        [PromptColorSchemes]::Asturias  = @($Colors["Blue"][0], $Colors["Yellow"][1])
        [PromptColorSchemes]::Spain     = @($Colors["Red"][0], $Colors["Yellow"][1])
        [PromptColorSchemes]::Hackerman = @($Colors["Green"][0], $Colors["Gray"][1])
        
    }
    Write-Debug "ColorScheme: $ColorScheme"
    # Write-Host $ColorScheme
    $Global:PromptColorScheme = $ColorScheme
    $Global:PromptColors = $ColorSchemes[$ColorScheme]
}

# Variantes para cada letra del nombre 'PowerShell'
$RandomP = @("p", "P", "ρ", "¶", "₱", "ℙ", "℗", "𝒫", "𝓟", "𝔓", "𝕻", "𝖯", "𝗣", "𝘗", "𝙋", "𝚙", "𝚙", "𝖕", "𝗽", "𝘱")
$RandomO = @("o", "O", "0", "ø", "ɵ", "º", "θ", "ω", "ჿ", "ᴏ", "ᴑ", "⊝", "Ο", "ο", "𝐨", "𝐎", "𝑂", "𝑜", "𝒐", "𝒪")
$RandomW = @("w", "W", "ω", "ѡ", "ẁ", "ẃ", "ẅ", "ẇ", "ѡ", "ѿ", "ᴡ", "𝐰", "𝑤", "𝑾", "𝒲", "𝓌", "𝔀", "𝔚", "𝔴", "𝕎")
$RandomE = @("e", "E", "3", "€", "є", "ё", "ē", "ė", "ę", "ε", "ξ", "ℯ", "𝐞", "𝐄", "𝑒", "𝐸", "𝑬", "𝓮", "𝔢", "𝔼")
$RandomR = @("r", "R", "®", "ř", "я", "г", "ɾ", "ṛ", "ɼ", "ṟ", "ṙ", "ṝ", "ℛ", "ℜ", "ℝ", "𝐫", "𝑅", "𝓻", "𝔯", "𝕣")
$RandomS = @("s", "S", "5", "$", "§", "∫", "š", "ś", "ş", "ς", "ș", "ƨ", "𝐬", "𝑆", "𝒔", "𝓈", "𝓢", "𝔰", "𝔖", "𝕊")
$RandomH = @("h", "H", "#", "η", "ħ", "һ", "ḥ", "ḧ", "ḩ", "ḣ", "ℎ", "ℋ", "ℌ", "𝒽", "𝐡", "𝐇", "𝐻", "𝒉", "𝓗", "𝕳")
$RandomL = @("l", "L", "1", "!", "|", "ł", "£", "ℓ", "ľ", "ĺ", "ℒ", "Ⅼ", "Ι", "𝐥", "𝐋", "𝑙", "𝐿", "𝑳", "𝓵", "𝓛")


# Función para establecer un título aleatorio de PowerShell
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

$PromptColorScheme = [PromptColorSchemes]::Random
$DefaultPrompt = $false

# Custom Prompt if enabled
function Prompt() {
	
    $Host.UI.RawUI.WindowTitle = "PowerShell"
    
    if ($DefaultPrompt) {
        Write-Host "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1))" -nonewline
        return " "
    }

    Set-PromptColorScheme -ColorScheme $PromptColorScheme

    Write-Host "||" -nonewline -ForegroundColor $PromptColors[1]
    Write-Host $env:USER -nonewline -ForegroundColor $PromptColors[0]
    Write-Host "@" -nonewline -ForegroundColor $PromptColors[1]
    Write-Host $Kernel -nonewline -ForegroundColor $PromptColors[0]
    Write-Host "|-|" -nonewline -ForegroundColor $PromptColors[1]
    
    $SPWD = if ($PWD.Path.StartsWith($HOME)) {
        "~$([IO.Path]::DirectorySeparatorChar)$($PWD.Path.Substring($HOME.Length))"
    }
    else {
        $PWD.Path 
    }
    $DirArray = $SPWD.Split([IO.Path]::DirectorySeparatorChar)

    $IsFirstFolder = $true
    foreach ($FolderName in $DirArray) {
        if ($FolderName.length -eq 0) {
            continue
        }
        if (!$IsFirstFolder -or ($FolderName -ne "~" -and !$IsWindows)) {
            Write-Host $([IO.Path]::DirectorySeparatorChar) -nonewline -ForegroundColor $PromptColors[1]
        }
        Write-Host $FolderName -nonewline -ForegroundColor $PromptColors[0]
        $IsFirstFolder = $false
    }
    
    Write-Host "||`n" -nonewline -ForegroundColor $PromptColors[1]
    Write-Host $("|>" * ($NestedPromptLevel + 1)) -nonewline -ForegroundColor $PromptColors[1]
    return " "
}

# Save the current directory to the clipboard
function Set-PWDClipboard {
    Set-Clipboard $PWD 
}

# Get Public IP
function Get-PublicIP {
    $PublicIP = Invoke-RestMethod -Uri "https://api.ipify.org"
    return $PublicIP
}

# Get Disk Space
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

# Get weather of a place
function Get-Weather {
    param (
        [string]$Place,
        [String]$Language
    )


    if (-not $Place) {
        #Get current city from IP
        $Place = (Invoke-RestMethod -Uri "https://ipinfo.io").city
        while (-not $Place) {
            $Place = (Invoke-RestMethod -Uri "https://ipinfo.io").city
            # Wait for 1 second
            Start-Sleep -Seconds 1
        }
    }

    if (-not $Language) {
        # Set default language to current System language, but only the first two characters
        $Language = (Get-Culture).Name.Substring(0, 2)
    }

    $Response = ""
    try {
        $RequestUri = "https://wttr.in/~" + $Place + "?lang=$Language"
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
        # Make the request to cht.sh and get the content
        $response = Invoke-WebRequest -Uri "https://cht.sh/$Command" -UseBasicParsing
        # Return the help content
        return $response.Content
    }
    catch {
        # Handle network or request errors
        Write-Error "Failed to retrieve help for the command '$Command'. Check your connection or the command entered."
    }
}


# Github copilot aliases generated by the command `gh copilot alias pwsh`
function ghcs {
    # Debug support provided by common PowerShell function parameters, which is natively aliased as -d or -db
    # https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_commonparameters?view=powershell-7.4#-debug
    param(
        [ValidateSet('gh', 'git', 'shell')]
        [Alias('t')]
        [String]$Target = 'shell',

        [Parameter(Position = 0, ValueFromRemainingArguments)]
        [string]$Prompt
    )
    begin {
        # Create temporary file to store potential command user wants to execute when exiting
        $executeCommandFile = New-TemporaryFile

        # Store original value of GH_DEBUG environment variable
        $envGhDebug = $Env:GH_DEBUG
    }
    process {
        if ($PSBoundParameters['Debug']) {
            $Env:GH_DEBUG = 'api'
        }

        gh copilot suggest -t $Target -s "$executeCommandFile" $Prompt
    }
    end {
        # Execute command contained within temporary file if it is not empty
        if ($executeCommandFile.Length -gt 0) {
            # Extract command to execute from temporary file
            $executeCommand = (Get-Content -Path $executeCommandFile -Raw).Trim()

            # Insert command into PowerShell up/down arrow key history
            [Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory($executeCommand)

            # Insert command into PowerShell history
            $now = Get-Date
            $executeCommandHistoryItem = [PSCustomObject]@{
                CommandLine        = $executeCommand
                ExecutionStatus    = [Management.Automation.Runspaces.PipelineState]::NotStarted
                StartExecutionTime = $now
                EndExecutionTime   = $now.AddSeconds(1)
            }
            Add-History -InputObject $executeCommandHistoryItem

            # Execute command
            Write-Host "`n"
            Invoke-Expression $executeCommand
        }
    }
    clean {
        # Clean up temporary file used to store potential command user wants to execute when exiting
        Remove-Item -Path $executeCommandFile

        # Restore GH_DEBUG environment variable to its original value
        $Env:GH_DEBUG = $envGhDebug
    }
}

function ghce {
    # Debug support provided by common PowerShell function parameters, which is natively aliased as -d or -db
    # https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_commonparameters?view=powershell-7.4#-debug
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments)]
        [string[]]$Prompt
    )
    begin {
        # Store original value of GH_DEBUG environment variable
        $envGhDebug = $Env:GH_DEBUG
    }
    process {
        if ($PSBoundParameters['Debug']) {
            $Env:GH_DEBUG = 'api'
        }

        gh copilot explain $Prompt
    }
    clean {
        # Restore GH_DEBUG environment variable to its original value
        $Env:GH_DEBUG = $envGhDebug
    }
}

# Alias
Set-Alias -Name vim -Value nvim
Set-Alias -Name vi -Value vim
Set-Alias -Name gvim -Value vim
Set-Alias -Name wrh -Value Write-Host
Set-Alias -Name cpwd -Value Set-PWDClipboard

