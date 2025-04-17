# ----------------------------------
# 1) Path for the Settings File
# ----------------------------------
$ProfileFolder = Split-Path -Parent $PROFILE
$SettingsFileName = "pwshProfileSettings.json"
$Global:SettingsFile = Join-Path $ProfileFolder $SettingsFileName

# ----------------------------------
# 2) Default Values
# ----------------------------------
$Global:DefaultSettings = [ordered]@{
    "PromptColorScheme"   = "Default"        # Default prompt color scheme
    "DefaultPrompt"       = $false          # If true, use PowerShell's default prompt instead of the custom one
    "AskCreateCodeFolder" = $true           # Whether to ask for the creation of the "Code" folder if missing
    "CodeFolderName"      = "Code"          # Default name for the code folder
    "EnableRandomTitle"   = $false          # Enables "Hackerman" style random PowerShell title
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

    $Global:PromptColors = $ColorSchemes[$ColorScheme]    
    $Global:UserSettings["PromptColorScheme"] = $ColorScheme.toString()
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
    Set-PromptColorScheme -ColorScheme $Global:UserSettings["PromptColorScheme"]

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
                $rel = $fullPath.Substring($r.BaseDir.Length).TrimStart('\','/').Replace('\','/')
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
        $dirs  = @($dirs)
        $files = @($files)
        $entries = $dirs + $files

        for ($i = 0; $i -lt $entries.Count; $i++) {
            $item   = $entries[$i]
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
