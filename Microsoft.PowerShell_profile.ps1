# ----------------------------------
# 1) Path for the Settings File
# ----------------------------------
$ProfileFolder = Split-Path -Parent $PROFILE
$SettingsFileName = "powershell.config.json"
$Global:SettingsFile = Join-Path $ProfileFolder $SettingsFileName

# ----------------------------------
# 2) Default Values
# ----------------------------------
$Global:DefaultSettings = [ordered]@{
    "Microsoft.PowerShell.Profile:PromptColorScheme"   = "Default"        # Default prompt color scheme
    "Microsoft.PowerShell.Profile:DefaultPrompt"       = $false          # If true, use PowerShell's default prompt instead of the custom one
    "Microsoft.PowerShell.Profile:AskCreateCodeFolder" = $true           # Whether to ask for the creation of the "Code" folder if missing
    "Microsoft.PowerShell.Profile:CodeFolderName"      = "Code"          # Default name for the code folder
    "Microsoft.PowerShell.Profile:EnableRandomTitle"   = $false          # Enables "Hackerman" style random PowerShell title
}

# ----------------------------------
# 3) Function to Load User Settings
# ----------------------------------
function Get-UserSettings {
    param(
        [string]$Path = $Global:SettingsFile
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

            $Global:UserSettings = $userSettings
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
$Global:UserSettings = Get-UserSettings $Global:SettingsFile

# ----------------------------------
# 5) Functions to Save User Settings (optional)
#    Use them if you want to modify values and
#    persist them into the JSON file.
# ----------------------------------
function Save-UserSettings {
    param(
        [hashtable]$NewSettings = $Global:Usersettings
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

if ($IsWindows) {
    $env:USER = $env:USERNAME
}

[String]$SPWD
$DirArray = @()

# ------------------------------------------------------
# Handle 'Code' folder based on loaded User Settings
# ------------------------------------------------------
$CODE = Join-Path -Path $HOME -ChildPath $Global:UserSettings["Microsoft.PowerShell.Profile:CodeFolderName"]
$AskCreateCodeFolder = $Global:UserSettings["Microsoft.PowerShell.Profile:AskCreateCodeFolder"]

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
        if ($Global:UserSettings["Microsoft.PowerShell.Profile:EnableRandomTitle"]) {
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

    $Global:PromptColors = $ColorSchemes[$ColorScheme]    
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
    Set-PromptColorScheme -ColorScheme $Global:UserSettings["Microsoft.PowerShell.Profile:PromptColorScheme"]

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

<#
.SYNOPSIS
Displays a directory tree structure in the console.

.DESCRIPTION
The `Show-DirectoryTree` function recursively lists the contents of a directory in a tree-like format. 
It supports displaying both folders and files, with options to customize recursion depth and respect `.gitignore` rules.

.PARAMETER Path
Specifies the path of the directory to list. Defaults to the current directory (`.`).

.PARAMETER Depth
Specifies the maximum depth of recursion. Defaults to unlimited depth (`[int]::MaxValue`).

.PARAMETER IncludeFiles
Includes files in the output in addition to folders. This is an optional switch parameter.

.PARAMETER RespectGitIgnore
Respects `.gitignore` rules when listing files and directories. This is an optional switch parameter.

.PARAMETER AdditionalIgnore
An array of additional ignore patterns to apply.

.EXAMPLE
Show-DirectoryTree

Displays the directory tree of the current directory.

.EXAMPLE
Show-DirectoryTree -Path "C:\Projects" -Depth 2

Displays the directory tree of "C:\Projects" up to a depth of 2 levels.

.EXAMPLE
Show-DirectoryTree -Path "C:\Projects" -IncludeFiles

Displays the directory tree of "C:\Projects", including files.

.EXAMPLE
Show-DirectoryTree -Path "C:\Projects" -IncludeFiles -RespectGitIgnore

Displays the directory tree of "C:\Projects", including files, while respecting `.gitignore` rules.

.NOTES
This function uses recursion to traverse directories and outputs a tree-like structure with proper indentation.
#>
function Show-DirectoryTree {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, HelpMessage = 'Path of the directory to list')]
        [string] $Path = '.',

        [Parameter(HelpMessage = 'Maximum recursion depth (omit = unlimited)')]
        [int] $Depth = [int]::MaxValue,

        [Parameter(HelpMessage = 'Include files in addition to folders')]
        [switch] $IncludeFiles,

        [Parameter(HelpMessage = 'When listing files, omit those matching .gitignore or AdditionalIgnore')]
        [switch] $RespectGitIgnore,

        [Parameter(HelpMessage = 'Array of extra ignore patterns (in .gitignore syntax)')]
        [string[]] $AdditionalIgnore = @()
    )

    # Validate path exists before proceeding
    if (-not (Test-Path -Path $Path)) {
        Write-Error "Path '$Path' does not exist"
        return
    }

    # Get full path safely
    $rootFull = (Resolve-Path -Path $Path).ProviderPath

    # Write the name of the root directory
    $rootName = Split-Path -Path $rootFull -Leaf
    Write-Output $rootName

    # Prepare Convert-GitignoreLine helper
    function Convert-GitignoreLine {
        param([string] $line, [string] $baseDir)
        $t = $line.Trim()
        if ($t -match '^(#|\s*$)') { return }
        $neg = $t.StartsWith('!'); if ($neg) { $t = $t.Substring(1).Trim() }
        $anch = $t.StartsWith('/'); if ($anch) { $t = $t.Substring(1) }
        $dirOnly = $t.EndsWith('/'); if ($dirOnly) { $t = $t.TrimEnd('/') }
        [PSCustomObject]@{
            Pattern  = $t
            Negated  = $neg
            Anchored = $anch
            DirOnly  = $dirOnly
            BaseDir  = $baseDir
        }
    }

    # Build patterns array if needed
    if ($IncludeFiles.IsPresent -and $RespectGitIgnore.IsPresent) {
        $patterns = @()

        # 1) AdditionalIgnore entries (base is root)
        foreach ($pat in $AdditionalIgnore) {
            if ($p = Convert-GitignoreLine $pat $rootFull) {
                $patterns += $p
            }
        }

        # 2) All .gitignore under tree
        Get-ChildItem -Path $rootFull -Filter '.gitignore' -File -Recurse -Force |
        ForEach-Object {
            $dir = Split-Path $_.FullName -Parent
            Get-Content -LiteralPath $_.FullName | ForEach-Object {
                if ($p = Convert-GitignoreLine $_ $dir) {
                    $patterns += $p
                }
            }
        }

        # testIgnore uses combined patterns
        $testIgnore = {
            param($fullPath, $isDir)
            foreach ($r in $patterns) {
                if ($fullPath -notlike "$($r.BaseDir)*") { continue }
                $rel = $fullPath.Substring($r.BaseDir.Length).TrimStart('\', '/').Replace('\', '/')
                if ($r.DirOnly -and -not $isDir) { continue }
                $match = $false
                if ($r.Anchored) {
                    if ($rel -like $r.Pattern -or $rel -like "$($r.Pattern)/*") { $match = $true }
                }
                elseif ($r.Pattern.Contains('/')) {
                    if ($rel -like "*$($r.Pattern)*") { $match = $true }
                }
                else {
                    $leaf = if ($rel) { Split-Path $rel -Leaf } else { '' }
                    if ($leaf -like $r.Pattern) { $match = $true }
                }
                if ($match) { return (-not $r.Negated) }
            }
            return $false
        }
    }
    else {
        # never ignore
        $testIgnore = { return $false }
    }

    # Recursive walker
    function Walk {
        param(
            [string] $dir,
            [string] $prefix,
            [int]    $level
        )
        if ($level -ge $Depth) { return }

        $items = Get-ChildItem -LiteralPath $dir -Force |
        Where-Object { -not ($_.Name.StartsWith('.') -or ($_.Attributes -band [IO.FileAttributes]::Hidden)) }

        $dirs = $items |
        Where-Object { $_.PSIsContainer -and -not (& $testIgnore $_.FullName $true) } |
        Sort-Object Name

        $files = if ($IncludeFiles) {
            $items |
            Where-Object { -not $_.PSIsContainer -and -not (& $testIgnore $_.FullName $false) } |
            Sort-Object Name
        }
        else { @() }

        # Force arrays
        $dirs = @($dirs)
        $files = @($files)
        $entries = $dirs + $files

        for ($i = 0; $i -lt $entries.Count; $i++) {
            $item = $entries[$i]
            $isLast = ($i -eq $entries.Count - 1)
            $branch = if ($isLast) { '└── ' } else { '├── ' }

            Write-Output ($prefix + $branch + $item.Name)

            if ($item.PSIsContainer) {
                $newPrefix = if ($isLast) { "$prefix    " } else { "$prefix│   " }
                Walk -dir $item.FullName -prefix $newPrefix -level ($level + 1)
            }
        }
    }

    # Start walking
    Walk -dir $rootFull -prefix '' -level 0
}




<#
.SYNOPSIS
Recursively retrieves the content of files in a directory while respecting .gitignore rules and additional ignore patterns.

.DESCRIPTION
The `Get-ContentRecursiveIgnore` function enumerates files in a specified directory and its subdirectories, ignoring files and directories based on .gitignore rules and additional ignore patterns provided by the user. It outputs the content of the files, optionally formatted with Markdown fenced code blocks.

.PARAMETER Path
Specifies the root directory to start the recursive enumeration. Defaults to the current directory (".").

.PARAMETER AdditionalIgnore
An array of additional ignore patterns to apply, in addition to the patterns specified in .gitignore files.

.PARAMETER UseMarkdownFence
A boolean flag indicating whether to format the output with Markdown fenced code blocks. Defaults to `$true`.

.EXAMPLE
Get-ContentRecursiveIgnore -Path "C:\Projects" -AdditionalIgnore @("*.log", "!important.log") -UseMarkdownFence $false
Retrieves the content of all files in the "C:\Projects" directory and its subdirectories, ignoring files matching the patterns in .gitignore and the additional patterns "*.log" (except "important.log"). Outputs the content without Markdown formatting.

.EXAMPLE
Get-ContentRecursiveIgnore -Path "C:\Projects" -UseMarkdownFence $true
Retrieves the content of all files in the "C:\Projects" directory and its subdirectories, ignoring files matching the patterns in .gitignore. Outputs the content formatted with Markdown fenced code blocks.

.NOTES
- The function respects .gitignore rules found in the directory tree.
- Additional ignore patterns can be specified using the `AdditionalIgnore` parameter.
- The function supports syntax highlighting for various file types when `UseMarkdownFence` is enabled, based on file extensions.

#> 

function Get-ContentRecursiveIgnore {
    [CmdletBinding()]
    param(
        [string]   $Path = ".",
        [string[]] $AdditionalIgnore = @(),
        [bool]     $UseMarkdownFence = $true
    )

    # Validate path exists before proceeding
    if (-not (Test-Path -Path $Path)) {
        Write-Error "Path '$Path' does not exist"
        return
    }

    

    # Show the directory tree before processing file contents
    Show-DirectoryTree -Path $Path -IncludeFiles -RespectGitIgnore -AdditionalIgnore $AdditionalIgnore

    Write-Output "`n`n"


    # Get full path safely
    $baseFull = (Resolve-Path -Path $Path).ProviderPath

    # Build a case-insensitive extension → Markdown language map
    $extensionMap = [hashtable]::new([System.StringComparer]::OrdinalIgnoreCase)
    $literalMap = @{
        ps1 = 'powershell'; py = 'python'; js = 'javascript'; ts = 'typescript'; html = 'html'; css = 'css';
        json = 'json'; md = 'markdown'; sh = 'bash'; c = 'c'; cpp = 'cpp'; cs = 'csharp'; java = 'java';
        go = 'go'; php = 'php'; rb = 'ruby'; rs = 'rust'; kt = 'kotlin'; swift = 'swift'; sql = 'sql'
    }
    foreach ($entry in $literalMap.GetEnumerator()) {
        $extensionMap[$entry.Key] = $entry.Value
    }

    # Parse a .gitignore line into a pattern object
    function Convert-GitignoreLine {
        param([string] $line, [string] $baseDir)
        $text = $line.Trim()
        if ($text -match '^(#|\s*$)') { return }
        $negated = $text.StartsWith('!')
        if ($negated) { $text = $text.Substring(1).Trim() }
        $anchored = $text.StartsWith('/')
        if ($anchored) { $text = $text.Substring(1) }
        $dirOnly = $text.EndsWith('/')
        if ($dirOnly) { $text = $text.TrimEnd('/') }
        return [PSCustomObject]@{
            Pattern  = $text
            Negated  = $negated
            Anchored = $anchored
            DirOnly  = $dirOnly
            BaseDir  = $baseDir
        }
    }

    # Load ignore patterns from .gitignore files
    $baseFull = (Resolve-Path $Path).ProviderPath
    $patterns = @()
    foreach ($ignore in $AdditionalIgnore) {
        if ($p = Convert-GitignoreLine $ignore $baseFull) { $patterns += $p }
    }
    Get-ChildItem -Path $baseFull -Filter '.gitignore' -File -Recurse -Force | ForEach-Object {
        $dir = Split-Path $_.FullName -Parent
        Get-Content $_.FullName | ForEach-Object {
            if ($p = Convert-GitignoreLine $_ $dir) { $patterns += $p }
        }
    }

    # Scriptblock to test whether a path should be ignored
    $testIgnore = {
        param([string] $fullPath, [bool] $isDirectory)
        foreach ($rule in $patterns) {
            if ($fullPath -notlike "$($rule.BaseDir)*") { continue }
            $relative = $fullPath.Substring($rule.BaseDir.Length).TrimStart('\', '/').Replace('\', '/')
            if ($rule.DirOnly -and -not $isDirectory) { continue }
            $matched = $false
            if ($rule.Anchored) {
                if ($relative -like "$($rule.Pattern)" -or $relative -like "$($rule.Pattern)/*") { $matched = $true }
            }
            elseif ($rule.Pattern.Contains('/')) {
                if ($relative -like "*$($rule.Pattern)*") { $matched = $true }
            }
            else {
                $leaf = if ($relative) { Split-Path $relative -Leaf } else { "" }
                if ($leaf -like $rule.Pattern) { $matched = $true }
            }
            if ($matched) { return -not $rule.Negated }
        }
        return $false
    }

    # Recursively enumerate files that are not ignored
    function Enumerate {
        param([string] $directory)
        Get-ChildItem -Path $directory -Force | ForEach-Object {
            if ($_.Name.StartsWith('.') -or ($_.Attributes -band [IO.FileAttributes]::Hidden)) { return }
            if (& $testIgnore $_.FullName $_.PSIsContainer) { return }
            if ($_.PSIsContainer) {
                Enumerate $_.FullName
            }
            else {
                [PSCustomObject]@{
                    FullPath = $_.FullName
                    RelPath  = $_.FullName.Substring($baseFull.Length).TrimStart('\', '/').Replace('\', '/')
                }
            }
        }
    }

    # Generate output with fenced code blocks
    $files = Enumerate $baseFull
    $output = $files | Sort-Object FullPath | ForEach-Object {
        $relPath = $_.RelPath
        $ext = [IO.Path]::GetExtension($_.FullPath).TrimStart('.')
        $lang = if ($extensionMap.ContainsKey($ext)) { $extensionMap[$ext] } else { '' }
        $openFence = '```' + $lang
        $closeFence = '```'
        $content = Get-Content -Raw -LiteralPath $_.FullPath

        if ($UseMarkdownFence) {
            "$relPath`n$openFence`n$content`n$closeFence"
        }
        else {
            "$relPath`n$content"
        }
    }

    return ($output -join "`n`n")
}

# Aliases
Set-Alias -Name vim -Value nvim
Set-Alias -Name vi -Value vim
Set-Alias -Name gvim -Value vim
Set-Alias -Name wrh -Value Write-Host
Set-Alias -Name cpwd -Value Set-PWDClipboard
Set-Alias -Name tree -Value Show-DirectoryTree
Set-Alias -Name gemini -Value Invoke-GeminiChat
Set-Alias -Name hola -Value Invoke-GeminiChat

# ---------------------------------------------------------------------------
# MATHEMATICAL CONSTANTS AND FUNCTIONS
# ---------------------------------------------------------------------------

# Constants
$Global:PI = [Math]::PI
$Global:E = [Math]::E

# Functions
function Get-Sin {
    param([double]$Angle)
    return [Math]::Sin($Angle)
}

function Get-Cos {
    param([double]$Angle)
    return [Math]::Cos($Angle)
}

function Get-Tan {
    param([double]$Angle)
    return [Math]::Tan($Angle)
}

function Get-Asin {
    param([double]$Value)
    return [Math]::Asin($Value)
}

function Get-Acos {
    param([double]$Value)
    return [Math]::Acos($Value)
}

function Get-Atan {
    param([double]$Value)
    return [Math]::Atan($Value)
}

function Get-Atan2 {
    param([double]$y, [double]$x)
    return [Math]::Atan2($y, $x)
}

function Get-Sqrt {
    param([double]$Number)
    return [Math]::Sqrt($Number)
}

function Get-Pow {
    param([double]$Base, [double]$Exponent)
    return [Math]::Pow($Base, $Exponent)
}

function Get-Log {
    param([double]$Number)
    return [Math]::Log($Number)
}

function Get-Log10 {
    param([double]$Number)
    return [Math]::Log10($Number)
}

function Get-Exp {
    param([double]$Power)
    return [Math]::Exp($Power)
}

function Get-Abs {
    param([double]$Value)
    return [Math]::Abs($Value)
}

function Get-Round {
    param([double]$Value, [int]$Digits = 0)
    return [Math]::Round($Value, $Digits)
}

function Get-Ceiling {
    param([double]$Value)
    return [Math]::Ceiling($Value)
}

function Get-Floor {
    param([double]$Value)
    return [Math]::Floor($Value)
}

function Get-Max {
    param([double]$Val1, [double]$Val2)
    return [Math]::Max($Val1, $Val2)
}

function Get-Min {
    param([double]$Val1, [double]$Val2)
    return [Math]::Min($Val1, $Val2)
}

function Get-Truncate {
    param([double]$Value)
    return [Math]::Truncate($Value)
}

function Get-Sign {
    param([double]$Value)
    return [Math]::Sign($Value)
}

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

# ---------------------------------------------------------------------------
# GEMINI CHAT FUNCTIONS (Cross-Platform)
# ---------------------------------------------------------------------------

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

<#
.SYNOPSIS
Securely stores an encrypted API key using platform-appropriate methods.

.DESCRIPTION
This function uses different encryption methods based on the operating system:
- Windows: DPAPI (Data Protection API)
- Linux: OpenSSL with user-specific salt
- macOS: Keychain (security command) or OpenSSL fallback

.PARAMETER ApiKey
The API key to store securely.

.PARAMETER KeyName
The name/identifier for the API key. Defaults to 'GeminiAPI'.
#>
function Set-SecureApiKey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ApiKey,
        
        [string]$KeyName = "GeminiAPI"
    )
    
    try {
        if ($IsWindows) {
            # Windows: Use DPAPI
            $secureString = ConvertTo-SecureString -String $ApiKey -AsPlainText -Force
            $encryptedString = ConvertFrom-SecureString -SecureString $secureString
            $keyFile = Join-Path $ProfileFolder "$KeyName.key"
            $encryptedString | Out-File -FilePath $keyFile -Encoding UTF8
            Write-Host "API key stored securely using Windows DPAPI at: $keyFile" -ForegroundColor Green
        }
        elseif ($IsMacOS) {
            # macOS: Try to use Keychain first, fallback to file-based encryption
            try {
                $serviceName = "PowerShell-Profile-$KeyName"
                $accountName = $env:USER
                
                # Store in macOS Keychain
                $process = Start-Process -FilePath "security" -ArgumentList @(
                    "add-generic-password",
                    "-a", $accountName,
                    "-s", $serviceName,
                    "-w", $ApiKey,
                    "-U"
                ) -Wait -PassThru -NoNewWindow
                
                if ($process.ExitCode -eq 0) {
                    Write-Host "API key stored securely in macOS Keychain" -ForegroundColor Green
                    return
                }
            }
            catch {
                Write-Warning "Failed to use macOS Keychain, falling back to file encryption"
            }
            
            # Fallback: File-based encryption for macOS
            Set-SecureApiKeyUnix -ApiKey $ApiKey -KeyName $KeyName
        }
        elseif ($IsLinux) {
            # Linux: File-based encryption with OpenSSL
            Set-SecureApiKeyUnix -ApiKey $ApiKey -KeyName $KeyName
        }
        else {
            Write-Error "Unsupported operating system for secure key storage"
        }
    }
    catch {
        Write-Error "Failed to store API key: $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
Unix/Linux secure key storage using OpenSSL encryption.

.DESCRIPTION
Internal function for storing API keys securely on Unix-like systems using OpenSSL.
#>
function Set-SecureApiKeyUnix {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ApiKey,
        
        [string]$KeyName = "GeminiAPI"
    )
    
    # Check if openssl is available
    $opensslPath = Get-Command openssl -ErrorAction SilentlyContinue
    if (-not $opensslPath) {
        Write-Error "OpenSSL is required for secure key storage on this platform but was not found. Please install OpenSSL."
        return
    }
    
    # Create a user-specific salt based on username and machine
    $saltData = "$env:USER$(hostname)PowerShell$KeyName"
    $salt = [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($saltData))
    $saltHex = [System.BitConverter]::ToString($salt).Replace('-', '').Substring(0, 16)
    
    # Create the key file path
    $keyFile = Join-Path $ProfileFolder "$KeyName.key"
    
    # Encrypt the API key using OpenSSL
    $tempFile = [System.IO.Path]::GetTempFileName()
    try {
        $ApiKey | Out-File -FilePath $tempFile -Encoding UTF8 -NoNewline
        
        $process = Start-Process -FilePath "openssl" -ArgumentList @(
            "enc", "-aes-256-cbc", "-salt", "-pbkdf2", "-iter", "100000",
            "-in", $tempFile, "-out", $keyFile, "-pass", "pass:$saltHex"
        ) -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -eq 0) {
            Write-Host "API key stored securely using OpenSSL encryption at: $keyFile" -ForegroundColor Green
        }
        else {
            Write-Error "Failed to encrypt API key with OpenSSL"
        }
    }
    finally {
        if (Test-Path $tempFile) {
            Remove-Item $tempFile -Force
        }
    }
}

<#
.SYNOPSIS
Retrieves and decrypts a stored API key using platform-appropriate methods.

.DESCRIPTION
This function retrieves API keys using different decryption methods based on the operating system.

.PARAMETER KeyName
The name/identifier for the API key. Defaults to 'GeminiAPI'.
#>
function Get-SecureApiKey {
    [CmdletBinding()]
    param(
        [string]$KeyName = "GeminiAPI"
    )
    
    try {
        if ($IsWindows) {
            # Windows: Use DPAPI
            $keyFile = Join-Path $ProfileFolder "$KeyName.key"
            
            if (-not (Test-Path $keyFile)) {
                return $null
            }
            
            $encryptedString = Get-Content -Path $keyFile -Raw
            $secureString = ConvertTo-SecureString -String $encryptedString.Trim()
            
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
            $apiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
            
            return $apiKey
        }
        elseif ($IsMacOS) {
            # macOS: Try Keychain first, fallback to file-based decryption
            try {
                $serviceName = "PowerShell-Profile-$KeyName"
                $accountName = $env:USER
                
                $process = Start-Process -FilePath "security" -ArgumentList @(
                    "find-generic-password",
                    "-a", $accountName,
                    "-s", $serviceName,
                    "-w"
                ) -Wait -PassThru -NoNewWindow -RedirectStandardOutput
                
                if ($process.ExitCode -eq 0) {
                    $apiKey = $process.StandardOutput.ReadToEnd().Trim()
                    if (-not [string]::IsNullOrEmpty($apiKey)) {
                        return $apiKey
                    }
                }
            }
            catch {
                # Fallback to file-based decryption
            }
            
            # Fallback: File-based decryption for macOS
            return Get-SecureApiKeyUnix -KeyName $KeyName
        }
        elseif ($IsLinux) {
            # Linux: File-based decryption
            return Get-SecureApiKeyUnix -KeyName $KeyName
        }
        else {
            Write-Error "Unsupported operating system for secure key retrieval"
            return $null
        }
    }
    catch {
        Write-Error "Failed to retrieve API key: $($_.Exception.Message)"
        return $null
    }
}

<#
.SYNOPSIS
Unix/Linux secure key retrieval using OpenSSL decryption.

.DESCRIPTION
Internal function for retrieving API keys securely on Unix-like systems using OpenSSL.
#>
function Get-SecureApiKeyUnix {
    [CmdletBinding()]
    param(
        [string]$KeyName = "GeminiAPI"
    )
    
    # Check if openssl is available
    $opensslPath = Get-Command openssl -ErrorAction SilentlyContinue
    if (-not $opensslPath) {
        Write-Error "OpenSSL is required for secure key retrieval on this platform but was not found."
        return $null
    }
    
    $keyFile = Join-Path $ProfileFolder "$KeyName.key"
    
    if (-not (Test-Path $keyFile)) {
        return $null
    }
    
    # Recreate the same salt used for encryption
    $saltData = "$env:USER$(hostname)PowerShell$KeyName"
    $salt = [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($saltData))
    $saltHex = [System.BitConverter]::ToString($salt).Replace('-', '').Substring(0, 16)
    
    # Decrypt the API key using OpenSSL
    $tempFile = [System.IO.Path]::GetTempFileName()
    try {
        $process = Start-Process -FilePath "openssl" -ArgumentList @(
            "enc", "-aes-256-cbc", "-d", "-pbkdf2", "-iter", "100000",
            "-in", $keyFile, "-out", $tempFile, "-pass", "pass:$saltHex"
        ) -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -eq 0 -and (Test-Path $tempFile)) {
            $apiKey = Get-Content -Path $tempFile -Raw
            return $apiKey.Trim()
        }
        else {
            Write-Error "Failed to decrypt API key with OpenSSL"
            return $null
        }
    }
    finally {
        if (Test-Path $tempFile) {
            Remove-Item $tempFile -Force
        }
    }
}

<#
.SYNOPSIS
Starts an interactive chat session with a Google Gemini model with PowerShell text formatting support.

.DESCRIPTION
This function sends an initial prompt to the Gemini API and establishes a chat loop.
It includes a system instruction that teaches Gemini how to use PowerShell formatting commands
for colored and styled text output, which works across all supported operating systems.
The session ends when the user types 'exit' or 'quit'.

The API key is stored securely using platform-appropriate encryption methods.

Gemini can use these formatting commands:
- [FG:ColorName]text[/FG] for colored text
- [BG:ColorName]text[/BG] for background colors
- Available colors: Black, DarkBlue, DarkGreen, DarkCyan, DarkRed, DarkMagenta, DarkYellow, Gray, DarkGray, Blue, Green, Cyan, Red, Magenta, Yellow, White

.PARAMETER InitialPrompt
The first question or message to start the conversation with the chatbot. If not provided, 
the function will start with an interactive prompt.

.PARAMETER Model
The Gemini model to use. Defaults to 'gemini-2.5-flash'.

.PARAMETER ResetApiKey
Forces the function to ask for a new API key, replacing the stored one.

.EXAMPLE
Invoke-GeminiChat -InitialPrompt "Give me a Python code example to sort a list."

.EXAMPLE
Invoke-GeminiChat -InitialPrompt "Hello" -ResetApiKey

.EXAMPLE
gemini
# Starts interactive mode directly with formatting support
#>
function Invoke-GeminiChat {
    [CmdletBinding()]
    param(
        [string]$InitialPrompt = "",

        [string]$Model = "gemini-2.5-flash",
        
        [switch]$ResetApiKey
    )

    # --- Get or Set API Key ---
    $apiKey = $null
    
    if ($ResetApiKey.IsPresent) {
        Write-Host "Resetting API key..." -ForegroundColor Yellow
        $apiKey = $null
    }
    else {
        $apiKey = Get-SecureApiKey -KeyName "GeminiAPI"
    }
    
    if ([string]::IsNullOrEmpty($apiKey)) {
        Write-Host "Google Gemini API key not found or reset requested." -ForegroundColor Yellow
        Write-Host "Please enter your Google Gemini API key:" -ForegroundColor Cyan
        $inputApiKey = Read-Host -AsSecureString
        
        # Convert secure string to plain text for this session
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($inputApiKey)
        $apiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        
        if ([string]::IsNullOrEmpty($apiKey)) {
            Write-Error "API key cannot be empty."
            return
        }
        
        # Store the API key securely
        Set-SecureApiKey -ApiKey $apiKey -KeyName "GeminiAPI"
    }

    # --- Initial Setup ---
    Write-Host "Starting chat with model '$Model' (PowerShell Formatting enabled). Type 'exit' or 'quit' to end." -ForegroundColor Cyan

    $uri = "https://generativelanguage.googleapis.com/v1beta/models/$($Model):generateContent"
    
    $headers = @{
        "Content-Type"   = "application/json"
        "X-goog-api-key" = $apiKey
    }

    $chatHistory = @()

    # --- SYSTEM INSTRUCTION ---
    # This key instruction tells the model how to behave and explains PowerShell formatting.
    $systemInstructionText = @"
You are a helpful assistant for a user in a PowerShell command-line terminal. You can use special PowerShell formatting commands to style your text responses.

AVAILABLE FORMATTING COMMANDS:
1. Text Colors (Foreground): [FG:ColorName]text[/FG]
    - Available colors: Black, DarkBlue, DarkGreen, DarkCyan, DarkRed, DarkMagenta, DarkYellow, Gray, DarkGray, Blue, Green, Cyan, Red, Magenta, Yellow, White
    - Example: [FG:Red]This text is red[/FG]

2. Background Colors: [BG:ColorName]text[/BG]
    - Same color names as foreground
    - Example: [BG:Yellow]This has yellow background[/BG]

3. You can combine formats: [FG:White][BG:DarkBlue]White text on dark blue background[/BG][/FG]

FORMATTING GUIDELINES:
- Use colors to highlight important information, warnings, or different types of content
- [FG:Green] for success messages, confirmations, or positive information
- [FG:Yellow] for warnings, cautions, or important notes
- [FG:Red] for errors, critical information, or urgent warnings
- [FG:Cyan] for commands, code snippets, or technical terms
- [FG:Magenta] for PowerShell-specific terms, variables, or parameters
- [FG:Blue] for file paths, URLs, or references
- Use background colors sparingly for emphasis: [BG:DarkRed][FG:White]CRITICAL[/FG][/BG]

EXAMPLES:
- "To run this [FG:Cyan]Get-Process[/FG] command, use [FG:Magenta]-Name[/FG] parameter"
- "[FG:Yellow]Warning:[/FG] This operation cannot be undone"
- "[FG:Green]Success![/FG] The operation completed successfully"
- "Navigate to [FG:Blue]C:\Users\YourName\Documents[/FG]"

Remember: Only use the formatting commands shown above. Do not use Markdown, HTML, Markdown or any other formatting syntax.
"@
    
    # --- Interactive Chat Loop ---
    # If no initial prompt was provided, start with interactive mode
    $currentPrompt = if ([string]::IsNullOrWhiteSpace($InitialPrompt)) {
        Write-Host ""  # Add a blank line for better spacing
        Read-Host "You"
    }
    else {
        $InitialPrompt
    }

    while ($currentPrompt -notin @("exit", "quit")) {

        $userMessage = @{
            role  = "user"
            parts = @(@{ text = $currentPrompt })
        }
        $chatHistory += $userMessage

        # Add the 'systemInstruction' to the request body
        $body = @{
            contents          = $chatHistory
            systemInstruction = @{
                parts = @( @{ text = $systemInstructionText } )
            }
        } | ConvertTo-Json -Depth 10

        # --- API Call ---
        try {
            # Add a blank line for better spacing
            Write-Host ""
            
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body -ContentType "application/json"
            
            if ($null -eq $response.candidates) {
                Write-Warning "The API did not return a valid response. The content may have been blocked."
                $modelText = "I am unable to provide a response to that."
            }
            else {
                $modelText = $response.candidates[0].content.parts[0].text
            }
        }
        catch {
            # Add a blank line for better spacing before the error
            Write-Host ""
            Write-Error "An error occurred while contacting the Gemini API: $($_.Exception.Message)"
            if ($_.Exception.Response) {
                $errorBody = $_.Exception.Response.GetResponseStream() | ForEach-Object { (New-Object System.IO.StreamReader($_)).ReadToEnd() }
                Write-Host "Error body: $errorBody" -ForegroundColor Red
            }
            break 
        }

        Write-Host "Gemini: " -ForegroundColor Green -NoNewline
        Format-GeminiText -Text $modelText
        Write-Host ""  # Add an additional blank line for better spacing
        Write-Host ""  # Add another blank line for user input separation
        Write-Host ""  # Add an extra blank line before user input

        $modelMessage = @{
            role  = "model"
            parts = @(@{ text = $modelText })
        }
        $chatHistory += $modelMessage

        $currentPrompt = Read-Host "You"
    }

    Write-Host "" # Add a final blank line before exit message
    Write-Host "Ending chat." -ForegroundColor Cyan
}
