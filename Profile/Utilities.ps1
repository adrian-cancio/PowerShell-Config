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
        [String]$Language,
        [ValidateRange(1, 20)]
        [int]$MaxAttempts = 3
    )

    if (-not $Place) {
        # Get current city from IP
        for ($attempt = 1; $attempt -le $MaxAttempts -and -not $Place; $attempt++) {
            try {
                $Place = (Invoke-RestMethod -Uri "https://ipinfo.io" -TimeoutSec 10 -ErrorAction Stop).city
            }
            catch {
                $Place = $null
            }
            if (-not $Place -and $attempt -lt $MaxAttempts) {
                Start-Sleep -Seconds 1
            }
        }

        if (-not $Place) {
            Write-Error "Could not detect your location after $MaxAttempts attempt(s). Pass a place explicitly, e.g. Get-Weather -Place 'Madrid'."
            return
        }
    }

    if (-not $Language) {
        $cultureName = (Get-Culture).Name
        $Language = if ($cultureName.Length -ge 2) { $cultureName.Substring(0, 2) } else { "en" }
    }

    $Response = ""
    try {
        $RequestUri = "https://wttr.in/~$([uri]::EscapeDataString($Place))?lang=$Language"
        $Response = Invoke-RestMethod -Uri $RequestUri -TimeoutSec 15 -ErrorAction Stop
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
        [string]$ProcessName,

        [ValidateRange(10, 60000)]
        [int]$IntervalMilliseconds = 250
    )

    $i = 0
    while ($true) {
        try {
            Stop-Process -Name $ProcessName -ErrorAction Stop
            $i++
            Write-Host "[$i] - Process '$ProcessName' stopped successfully." -ForegroundColor Green
        }
        catch {
            $null = $_
        }
        Start-Sleep -Milliseconds $IntervalMilliseconds
    }
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
