# PowerShell Config (Cross-Platform)

This repository/folder contains a **custom PowerShell profile** that works on Windows, Linux, or macOS. It includes:

- A JSON-based settings system
- A customizable prompt (with multiple color schemes)
- Helper functions and aliases for convenience
- Google Gemini AI integration with terminal-optimized responses
- Mathematical constants and functions
- GitHub Copilot integration (ghcs/ghce)
- Cross-platform secure API key storage
- Directory tree visualization with .gitignore support
- File content extraction with pattern matching

## 1. Cross-Platform Profile Basics

PowerShell 7 and above supports multiple platforms. The **location** of your PowerShell profile file (`$PROFILE`) can vary:

- **Windows (PowerShell 7+):** `C:\Users\<YourName>\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`
- **Linux:** `~/.config/powershell/Microsoft.PowerShell_profile.ps1`
- **macOS:** `~/.config/powershell/Microsoft.PowerShell_profile.ps1`

In all cases, you can **check** the exact path by running:
```powershell
$PROFILE
```
in your PowerShell session. This will tell you where your current user profile is being loaded from.

## 2. Installation

### 2.1. System Requirements

- **PowerShell 7+** (cross-platform support)
- **For Linux/macOS Gemini integration**: OpenSSL must be installed
  - **Ubuntu/Debian**: `sudo apt-get install openssl`
  - **CentOS/RHEL**: `sudo yum install openssl` or `sudo dnf install openssl`
  - **macOS**: Usually pre-installed, or install via Homebrew: `brew install openssl`
  - **Arch Linux**: `sudo pacman -S openssl`
- **For GitHub Copilot integration** (optional):
  - GitHub Copilot subscription
  - GitHub CLI (`gh`) installed and authenticated
  - GitHub Copilot CLI extension: `gh extension install github/gh-copilot`

### 2.2. Profile Installation

1. **Create the folder** for your profile if it doesn't exist. For example, on Linux:
   ```bash
   mkdir -p ~/.config/powershell
   ```
   On Windows, the directory typically already exists under `Documents\PowerShell`.

2. **Place the content** of the provided script (the `.ps1` file) into the path shown by `$PROFILE`. For example:
   - Windows: `C:\Users\<YourName>\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`
   - Linux: `~/.config/powershell/Microsoft.PowerShell_profile.ps1`

3. **Open a new PowerShell session** (or reload your current session) to apply the custom profile:
   ```powershell
   . $PROFILE
   ```

4. The profile will automatically attempt to **create** (if missing) a JSON settings file named `powershell.config.json` in the **same folder** as your `$PROFILE`.

## 3. How It Works

### 3.1. JSON Settings File

- The profile reads and writes from a file named `powershell.config.json`, which lives alongside your `Microsoft.PowerShell_profile.ps1`.
- If the JSON file is **not found**, the script **creates it** using [default settings](#32-default-settings).
- If the JSON is **invalid** or **empty**, the script warns you and proceeds with defaults.

### 3.2. Default Settings

The default settings (written in a PowerShell hashtable) look like this:

```json
{
    "Microsoft.PowerShell.Profile:PromptColorScheme": "Default",
    "Microsoft.PowerShell.Profile:DefaultPrompt": false,
    "Microsoft.PowerShell.Profile:AskCreateCodeFolder": true,
    "Microsoft.PowerShell.Profile:CodeFolderName": "Code",
    "Microsoft.PowerShell.Profile:EnableRandomTitle": false
}
```

- **Microsoft.PowerShell.Profile:PromptColorScheme**: Custom prompt color scheme. Options include `Default`, `Blue`, `Green`, `Cyan`, `Red`, `Magenta`, `Yellow`, `Gray`, `Random`, `Asturias`, `Spain`, `Hackerman`.
- **Microsoft.PowerShell.Profile:DefaultPrompt**: If `true`, uses the standard PowerShell prompt instead of the custom one.
- **Microsoft.PowerShell.Profile:AskCreateCodeFolder**: If `true`, prompts whether to create a `Code` folder under `$HOME` if it doesn't exist.
- **Microsoft.PowerShell.Profile:CodeFolderName**: Defines the name of the folder to create under `$HOME` (e.g. `"Code"`).
- **Microsoft.PowerShell.Profile:EnableRandomTitle**: If `true` and you use the `Hackerman` color scheme, sets a random "Hackerman-like" title in the PowerShell window.

You can **manually edit** `powershell.config.json` at any time to change these settings.

### 3.3. Custom Prompt

The script sets a custom prompt that typically looks like:
```
||username@Windows|-|~\Documents\Powershell||
|>
```
(or on Linux):
```
||username@Linux|-|~/.config/powershell||
|>
```
The **colors** are controlled by your `PromptColorScheme`. If you set `"DefaultPrompt": true` in your JSON, then the script will **not** apply the custom prompt, and you'll see the standard PowerShell prompt.

### 3.4. Additional Functions

- **Set-PWDClipboard** (`cpwd` alias): Copies the current directory path to your clipboard.
- **Get-PublicIP**: Retrieves your public IP via `https://api.ipify.org`.
- **Get-DiskSpace**: Shows a table of used/free/total space for your drives.
- **Get-Weather**: Fetches weather information from `wttr.in` for a given location.
- **Get-ChtShHelp** / **Get-PowershellChtShHelp**: Queries [cht.sh](https://cht.sh) for command-line or PowerShell-specific help.
- **Stop-ProcessConstantly**: Repeatedly attempts to stop a process by name.
- **Show-DirectoryTree** (`tree` alias): Displays a directory tree structure in the console with .gitignore support.
- **Get-ContentRecursiveIgnore**: Recursively retrieves content from non-ignored files, respecting `.gitignore` and additional ignore patterns.

### 3.5. GitHub Copilot Integration

The profile includes integration with GitHub Copilot CLI for enhanced command-line assistance:

- **ghcs** (GitHub Copilot Suggest): Interactive command suggestion for shell, git, or GitHub CLI
  - Usage: `ghcs "how to find large files"` or `ghcs -Target git "revert last commit"`
  - Supports shell (default), git, and gh targets
  - Automatically adds suggested commands to PowerShell history
  - Executes commands interactively after confirmation

- **ghce** (GitHub Copilot Explain): Explains complex commands or code
  - Usage: `ghce "docker run -it --rm ubuntu bash"`
  - Provides detailed explanations of command syntax and parameters

**Requirements for GitHub Copilot Integration:**
- GitHub Copilot subscription
- GitHub CLI (`gh`) installed and authenticated
- GitHub Copilot CLI extension: `gh extension install github/gh-copilot`

### 3.6. Mathematical Constants and Functions

The profile includes a set of mathematical constants and helper functions based on the `[Math]` class:

**Constants:**
- `$Global:PI`: The mathematical constant Pi.
- `$Global:E`: The mathematical constant e (Euler's number).

**Functions:**
- `Get-Sin($angle)`: Calculates the sine of an angle (in radians).
- `Get-Cos($angle)`: Calculates the cosine of an angle (in radians).
- `Get-Tan($angle)`: Calculates the tangent of an angle (in radians).
- `Get-Asin($value)`: Calculates the arcsine of a value.
- `Get-Acos($value)`: Calculates the arccosine of a value.
- `Get-Atan($value)`: Calculates the arctangent of a value.
- `Get-Atan2($y, $x)`: Calculates the arctangent of the quotient of two numbers.
- `Get-Sqrt($number)`: Calculates the square root of a number.
- `Get-Pow($base, $exponent)`: Raises a number to a specified power.
- `Get-Log($number)`: Calculates the natural (base e) logarithm of a number.
- `Get-Log10($number)`: Calculates the base 10 logarithm of a number.
- `Get-Exp($power)`: Calculates e raised to a specified power.
- `Get-Abs($value)`: Returns the absolute value of a number.
- `Get-Round($value, $digits)`: Rounds a value to a specified number of decimal places (default is 0).
- `Get-Ceiling($value)`: Returns the smallest integer greater than or equal to a number.
- `Get-Floor($value)`: Returns the largest integer less than or equal to a number.
- `Get-Max($val1, $val2)`: Returns the larger of two numbers.
- `Get-Min($val1, $val2)`: Returns the smaller of two numbers.
- `Get-Truncate($value)`: Calculates the integer part of a number.
- `Get-Sign($value)`: Returns an integer indicating the sign of a number.

### 3.7. Google Gemini Chat Integration (Cross-Platform)

The profile includes advanced Google Gemini AI integration with terminal-optimized responses:

- **Invoke-GeminiChat** (aliases: `gemini`, `hola`): Interactive AI chat with Google Gemini
  - Usage: `gemini "explain PowerShell objects"` or `hola "¿cómo funciona el pipeline?"`
  - Terminal-optimized responses with proper formatting
  - Cross-platform secure API key storage
  - Code analysis and execution safety features
  - Support for PowerShell-specific formatting commands

**Key Features:**
- **Terminal Optimization**: Responses formatted specifically for terminal display
- **Code Safety**: Automatic risk analysis before executing suggested PowerShell code
- **Cross-Platform Security**: Secure API key storage using platform-specific methods
  - Windows: DPAPI (Data Protection API)
  - Linux/macOS: OpenSSL encryption with user-specific keys
- **Multilingual Support**: Works with multiple languages (Spanish alias `hola` included)
- **PowerShell Integration**: Deep understanding of PowerShell syntax and best practices

**Setup Requirements:**
- Google Gemini API key (stored securely using `Set-SecureApiKey`)
- Internet connection for API calls
- OpenSSL for Linux/macOS secure storage

### 3.8. Internal Security Functions

The profile includes advanced security functions for safe code analysis:

- **Test-PowerShellCodeRisk**: Analyzes PowerShell code for potential system risks
  - Cross-platform risk pattern detection
  - Identifies dangerous operations (file system, registry, services, network, etc.)
  - Supports Windows, Linux, and macOS specific risky patterns
  - Returns boolean indicating if code requires user confirmation

- **Invoke-SafePowerShellCode**: Executes PowerShell code safely with risk analysis
  - Automatic risk assessment before execution
  - User confirmation for risky operations
  - Timeout protection (30 seconds)
  - Separate output and error handling
  - Background job execution for safety

- **Format-GeminiText**: Processes PowerShell format commands for terminal styling
  - Supports `[FG:Color]text[/FG]` and `[BG:Color]text[/BG]` formatting
  - Cross-platform color support
  - Safe handling of invalid color names

### 3.9. Aliases

- `vim` = `nvim`
- `vi` = `vim`
- `gvim` = `vim`
- `wrh` = `Write-Host`
- `cpwd` = `Set-PWDClipboard`
- `tree` = `Show-DirectoryTree`
- `gemini` = `Invoke-GeminiChat`
- `hola` = `Invoke-GeminiChat` (Alternative Spanish alias)

### 3.10. Managing Settings

You can **edit** `powershell.config.json` directly, or from within PowerShell you can modify `$Global:UserSettings` in memory and then call:
```powershell
Save-UserSettings
```
to **persist** your changes to the JSON file.

**Note**: All configuration properties follow the PowerShell naming convention with the prefix `Microsoft.PowerShell.Profile:` to maintain consistency with PowerShell's modular configuration approach.

**Available Configuration Functions:**
- **Get-UserSettings**: Loads settings from JSON file with default fallbacks
- **Save-UserSettings**: Persists current settings to JSON file

**Future Modular Configuration**: In upcoming versions, the configuration will support module management:
```json
{
    "Microsoft.PowerShell.Profile:PromptColorScheme": "Default",
    "Microsoft.PowerShell.Profile:DefaultPrompt": false,
    "Microsoft.PowerShell.Profile:AskCreateCodeFolder": true,
    "Microsoft.PowerShell.Profile:CodeFolderName": "Code",
    "Microsoft.PowerShell.Profile:EnableRandomTitle": false,
    "Microsoft.PowerShell.Profile:EnabledModules": ["AI", "Math", "GitHub"],
    "Microsoft.PowerShell.Profile:ModuleAutoUpdate": true
}
```

## 4. Complete Function Reference

### Core Profile Functions
- `Get-UserSettings` - Load user configuration from JSON
- `Save-UserSettings` - Save user configuration to JSON
- `Set-PromptColorScheme` - Configure prompt colors
- `Set-RandomPowerShellTitle` - Set randomized "Hackerman" title
- `Prompt` - Custom prompt function

### Utility Functions
- `Set-PWDClipboard` (alias: `cpwd`) - Copy current directory to clipboard
- `Get-PublicIP` - Retrieve public IP address
- `Get-DiskSpace` - Display drive space information
- `Get-Weather` - Get weather information for location
- `Get-ChtShHelp` - Query cht.sh for command help
- `Get-PowershellChtShHelp` - PowerShell-specific cht.sh queries
- `Stop-ProcessConstantly` - Continuously stop a process by name

### File System Functions
- `Show-DirectoryTree` (alias: `tree`) - Display directory tree with .gitignore support
- `Get-ContentRecursiveIgnore` - Recursively get file contents with ignore patterns

### Mathematical Functions
- `Get-Sin`, `Get-Cos`, `Get-Tan` - Trigonometric functions
- `Get-Asin`, `Get-Acos`, `Get-Atan`, `Get-Atan2` - Inverse trigonometric functions
- `Get-Sqrt`, `Get-Pow` - Power and root functions
- `Get-Log`, `Get-Log10`, `Get-Exp` - Logarithmic and exponential functions
- `Get-Abs`, `Get-Round`, `Get-Ceiling`, `Get-Floor`, `Get-Truncate` - Rounding functions
- `Get-Max`, `Get-Min`, `Get-Sign` - Comparison and sign functions

### AI Integration Functions
- `Invoke-GeminiChat` (alias: `gemini`, `hola`) - Google Gemini AI chat with terminal optimization
- `Format-GeminiText` - Process Gemini formatting commands
- `Test-PowerShellCodeRisk` - Analyze code for security risks
- `Invoke-SafePowerShellCode` - Execute code with safety checks
- `Set-SecureApiKey`, `Get-SecureApiKey` - Cross-platform secure API key storage
- `Set-SecureApiKeyUnix`, `Get-SecureApiKeyUnix` - Unix-specific key storage

### GitHub Copilot Functions
- `ghcs` - GitHub Copilot Suggest (command suggestions)
- `ghce` - GitHub Copilot Explain (command explanations)

## 5. Future Plans

- **Installation Script**: A script that automatically installs the profile for Windows/Linux/macOS by placing it in the right folder, generating the JSON file, etc.
- **Modular Function Installation**: Implementation of an optional module system where additional functionality can be installed on-demand:
  - **Core Profile**: Basic prompt, settings system, and essential utilities (default installation)
  - **AI Integration Module**: Google Gemini chat functionality with terminal optimization (`Install-ProfileModule -Name "AI"`)
  - **Mathematics Module**: Mathematical constants and calculation functions (`Install-ProfileModule -Name "Math"`)
  - **GitHub Module**: GitHub Copilot integration and Git operations (`Install-ProfileModule -Name "GitHub"`)
  - **Development Module**: Docker commands, development tools, and code analysis (`Install-ProfileModule -Name "Dev"`)
  - **System Module**: Advanced system monitoring and management functions (`Install-ProfileModule -Name "System"`)
  - **Security Module**: Enhanced security analysis and safe code execution (`Install-ProfileModule -Name "Security"`)
  - **Custom Modules**: Allow users to create and share their own function modules
  - Each module would be stored separately and loaded conditionally based on user preferences
- **Enhanced Terminal Integration**: 
  - Better integration with Windows Terminal, iTerm2, and other modern terminals
  - Support for terminal-specific features (tabs, panes, etc.)
  - Terminal theme synchronization with prompt colors
- **Cloud Synchronization**: Optional cloud sync for settings and customizations across multiple machines
- **Package Manager Integration**: Direct integration with package managers (winget, brew, apt) for tool installation
- **More AI Providers**: Support for additional AI providers (OpenAI, Claude, etc.) beyond Gemini
- **Advanced Security Features**:
  - Code sandboxing for safer execution
  - Enhanced risk analysis with machine learning
  - Integration with security scanning tools
