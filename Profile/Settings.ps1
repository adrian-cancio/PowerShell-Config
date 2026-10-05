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
    "Microsoft.PowerShell.Profile:EnableMathModule"    = $true
    "Microsoft.PowerShell.Profile:GitPrompt"           = $true           # Show git branch and status in the prompt
    "Microsoft.PowerShell.Profile:GitPromptTimeoutMs"  = 1500            # Max time to wait for git status before showing a placeholder
    "Microsoft.PowerShell.Profile:PromptMinDurationSeconds" = 2          # Show the last command duration only above this threshold
    "Microsoft.PowerShell.Profile:PredictionViewStyle" = "ListView"      # PSReadLine prediction style: ListView or InlineView
    "Microsoft.PowerShell.Profile:PredictionMode"      = "OnDemand"      # History suggestions: OnDemand (toggle key below), Always, or Off
    "Microsoft.PowerShell.Profile:PredictionToggleKey" = "Ctrl+Alt+p"    # Key that shows or hides history suggestions in OnDemand mode
    "Microsoft.PowerShell.Profile:EnableZoxide"        = $true           # Initialize zoxide when it is installed
}

# ----------------------------------
# 3) Function to Load User Settings
# ----------------------------------
function Get-UserSettings {
    param(
        [string]$Path = $Global:SettingsFile
    )

    $Global:UserSettingsPersistable = $false

    # If the file does not exist, create it using default values
    if (-not (Test-Path $Path)) {
        Write-Host "File '$Path' does not exist. Creating default settings file..."
        $DefaultJson = ($Global:DefaultSettings | ConvertTo-Json -Depth 10)
        $DefaultJson | Out-File -FilePath $Path -Encoding UTF8
        $Global:UserSettingsPersistable = $true
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
            $Global:UserSettingsPersistable = $true
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
        [System.Collections.IDictionary]$NewSettings = $Global:Usersettings
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

$HostName = [Environment]::MachineName
$OsIcon = @{ Windows = "⊞"; Linux = "λ"; MacOS = "⌘" }[$Kernel.ToString()]

# ------------------------------------------------------
# Handle 'Code' folder based on loaded User Settings
# ------------------------------------------------------
$CODE = Join-Path -Path $HOME -ChildPath $Global:UserSettings["Microsoft.PowerShell.Profile:CodeFolderName"]
$AskCreateCodeFolder = $Global:UserSettings["Microsoft.PowerShell.Profile:AskCreateCodeFolder"]

if (!(Test-Path -Path $CODE) -and $AskCreateCodeFolder -and [Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
    $CreateCodeFolder = $null
    $CreateCodeFolderAnswered = $false
    try {
        $CreateCodeFolder = Read-Host "`'$CODE`' folder does not exist, create it? (Y/N)"
        $CreateCodeFolderAnswered = $true
    }
    catch {
        Write-Verbose "Could not read an answer for the '$CODE' folder prompt: $($_.Exception.Message)"
    }

    if ($CreateCodeFolderAnswered) {
        if ("$CreateCodeFolder".Trim() -in @("Y", "YES")) {
            try {
                New-Item -Path $CODE -ItemType Directory -ErrorAction Stop | Out-Null
            }
            catch {
                Write-Warning "Could not create '$CODE': $($_.Exception.Message)"
            }
        }
        else {
            $Global:UserSettings["Microsoft.PowerShell.Profile:AskCreateCodeFolder"] = $false
            if ($Global:UserSettingsPersistable) {
                try {
                    Save-UserSettings
                }
                catch {
                    Write-Warning "Could not save settings to '$Global:SettingsFile': $($_.Exception.Message)"
                }
            }
        }
    }
}
