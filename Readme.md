# PowerShell Config (Cross-Platform)

This repository/folder contains a **custom PowerShell profile** that works on Windows, Linux, or macOS. It includes:

- A JSON-based settings system
- A customizable prompt (with multiple color schemes)
- Helper functions and aliases for convenience

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

1. **Create the folder** for your profile if it doesn’t exist. For example, on Linux:
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
- If the JSON file is **not found**, the script **creates it** using [default settings](#default-settings).
- If the JSON is **invalid** or **empty**, the script warns you and proceeds with defaults.

### 3.2. Default Settings

The default settings (written in a PowerShell hashtable) look like this:

```json
{
    "PromptColorScheme": "Default",
    "DefaultPrompt": false,
    "AskCreateCodeFolder": true,
    "CodeFolderName": "Code",
    "EnableRandomTitle": false
}
```

- **PromptColorScheme**: Custom prompt color scheme. Options include `Default`, `Blue`, `Green`, `Cyan`, `Red`, `Magenta`, `Yellow`, `Gray`, `Random`, `Asturias`, `Spain`, `Hackerman`.
- **DefaultPrompt**: If `true`, uses the standard PowerShell prompt instead of the custom one.
- **AskCreateCodeFolder**: If `true`, prompts whether to create a `Code` folder under `$HOME` if it doesn’t exist.
- **CodeFolderName**: Defines the name of the folder to create under `$HOME` (e.g. `"Code"`).
- **EnableRandomTitle**: If `true` and you use the `Hackerman` color scheme, sets a random “Hackerman-like” title in the PowerShell window.

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
The **colors** are controlled by your `PromptColorScheme`. If you set `"DefaultPrompt": true` in your JSON, then the script will **not** apply the custom prompt, and you’ll see the standard PowerShell prompt.

### 3.4. Additional Functions

- **Set-PWDClipboard** (`cpwd` alias): Copies the current directory path to your clipboard.
- **Get-PublicIP**: Retrieves your public IP via `https://api.ipify.org`.
- **Get-DiskSpace**: Shows a table of used/free/total space for your drives.
- **Get-Weather**: Fetches weather information from `wttr.in` for a given location.
- **Get-ChtShHelp** / **Get-PowershellChtShHelp**: Queries [cht.sh](https://cht.sh) for command-line or PowerShell-specific help.
- **Stop-ProcessConstantly**: Repeatedly attempts to stop a process by name.
- **Show-DirectoryTree**: Recursively retrieves non-ignored files' content respecting .gitignore.
- **Get-ContentRecursiveIgnore**: Recursively retrieves content from non-ignored files, respecting `.gitignore` and additional ignore patterns.

### 3.5. Mathematical Constants and Functions

The profile now includes a set of mathematical constants and helper functions based on the `[Math]` class:

- **Constants**:
    - `$PI`: The mathematical constant Pi.
    - `$E`: The mathematical constant e (Euler's number).
- **Functions**:
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

### 3.6. Aliases

- `vim` = `nvim`
- `vi` = `vim`
- `gvim` = `vim`
- `wrh` = `Write-Host`
- `cpwd` = `Set-PWDClipboard`

### 3.7. Managing Settings

You can **edit** `powershell.config.json` directly, or from within PowerShell you can modify `$Global:UserSettings` in memory and then call:
```powershell
Save-UserSettings
```
to **persist** your changes to the JSON file.

## 4. Future Plans

- **Installation Script**: A script that automatically installs the profile for Windows/Linux/macOS by placing it in the right folder, generating the JSON file, etc.
- **More Custom Commands**: Additional aliases or functions to streamline various tasks (e.g., Git operations, Docker commands, etc.).