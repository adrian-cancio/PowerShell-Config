# PowerShell Custom Profile

![PowerShell](https://img.shields.io/badge/PowerShell-7+-blue?logo=powershell)
![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey)
![License](https://img.shields.io/badge/License-MIT-green)

A powerful, cross-platform PowerShell profile that enhances your terminal experience with AI integration, mathematical functions, advanced utilities, and beautiful customizable prompts.

## ✨ Features

- 🎨 **Customizable Prompt**: 11 different color schemes including dynamic themes
- 🤖 **AI Integration**: Google Gemini chat with terminal-optimized responses
- 🧮 **Mathematical Functions**: Complete set of trigonometric and mathematical operations
- � **Smart Pip Wrappers**: Intelligent warnings for global package installations
- �🐙 **GitHub Copilot**: Built-in command suggestions and explanations
- 🔒 **Secure Storage**: Cross-platform encrypted API key management
- 📁 **Smart File Operations**: Directory trees with .gitignore support
- ⚙️ **JSON Configuration**: Persistent settings with easy customization
- 🌍 **Cross-Platform**: Works seamlessly on Windows, Linux, and macOS

## 🚀 Quick Start

### Prerequisites

- **PowerShell 7+** (cross-platform support)
- **OpenSSL** (for Linux/macOS Gemini integration)
- **GitHub CLI** (optional, for Copilot features)

### Installation

1. **Clone or download** this profile to your PowerShell directory:

   **Windows:**
   ```powershell
   # Check your profile path
   $PROFILE
   # Usually: C:\Users\<YourName>\Documents\PowerShell\
   ```

   **Linux/macOS:**
   ```bash
   # Create directory if it doesn't exist
   mkdir -p ~/.config/powershell
   # Profile path: ~/.config/powershell/Microsoft.PowerShell_profile.ps1
   ```

2. **Copy the profile file** to your PowerShell directory as `Microsoft.PowerShell_profile.ps1`

3. **Reload your PowerShell session**:
   ```powershell
   . $PROFILE
   ```

4. **Configure your settings** (optional):
   - The profile will create `powershell.config.json` automatically
   - Edit this file to customize your experience

## 📖 Usage

### Basic Commands

```powershell
# Get weather information
Get-Weather "Madrid"

# Show directory tree
tree

# Copy current path to clipboard
cpwd

# Get your public IP
Get-PublicIP

# Show disk space
Get-DiskSpace

# Smart pip installations (with global warnings)
pip install package-name       # Shows warning if not in venv
pip install package-name --global  # Skips warning
```

### AI Integration

```powershell
# Start Gemini chat (English)
gemini "how to find large files in PowerShell"

# GitHub Copilot suggestions
ghcs "compress a folder"

# GitHub Copilot explanations  
ghce "Get-ChildItem -Recurse | Where-Object {$_.Length -gt 100MB}"
```

### Mathematical Functions

```powershell
# Use mathematical constants
$PI
$E

# Calculate trigonometric functions
Get-Sin 1.5708  # π/2
Get-Cos 0       # 1
Get-Sqrt 16     # 4
Get-Pow 2 3     # 8
```

### Pip Wrapper Functions

The profile includes intelligent wrappers for `pip` and `pip3` commands that warn you when installing packages globally outside of a virtual environment:

```powershell
# Installing globally will show a warning
pip install requests

# Output:
# ⚠️  WARNING: Installing packages globally (not in virtual environment).
# Recommended: python -m venv venv then activate it.
# Or use: pip install requests --global
# 
# Press Enter to continue or Ctrl+C to cancel.

# Skip warning with --global flag
pip install requests --global

# In a virtual environment, works normally (no warning)
python -m venv myenv
.\myenv\Scripts\Activate.ps1  # Windows
pip install requests  # No warning shown
```

**Features:**
- ⚠️ **Smart warnings**: Only warns for `install` commands when not in a virtual environment
- 🔍 **Environment detection**: Automatically detects `venv` and `conda` environments
- 🛠️ **Cross-platform**: Works on Windows, Linux, and macOS
- 🚫 **Skip warnings**: Use `--global` flag to bypass warnings
- 🔧 **Transparent**: All other pip commands work exactly as normal
- 🎯 **Independent**: `pip` and `pip3` work independently with their respective binaries

The wrapper detects virtual environments by checking:
- `$env:VIRTUAL_ENV` (standard Python virtual environments)
- `$env:CONDA_DEFAULT_ENV` (Conda environments)

### Prompt Customization

Available color schemes:
- `Default`, `Blue`, `Green`, `Cyan`, `Red`, `Magenta`, `Yellow`, `Gray`
- `Random`, `Asturias`, `Spain`, `Hackerman`

```powershell
# Change color scheme
Set-PromptColorScheme -ColorScheme "Hackerman"

# Or edit powershell.config.json:
{
    "Microsoft.PowerShell.Profile:PromptColorScheme": "Hackerman"
}
```

## ⚙️ Configuration

The profile uses a JSON configuration file (`powershell.config.json`) for settings:

```json
{
    "Microsoft.PowerShell.Profile:PromptColorScheme": "Default",
    "Microsoft.PowerShell.Profile:DefaultPrompt": false,
    "Microsoft.PowerShell.Profile:AskCreateCodeFolder": true,
    "Microsoft.PowerShell.Profile:CodeFolderName": "Code",
    "Microsoft.PowerShell.Profile:EnableRandomTitle": false
}
```

### Configuration Options

| Setting | Description | Default |
|---------|-------------|---------|
| `PromptColorScheme` | Color scheme for the prompt | `"Default"` |
| `DefaultPrompt` | Use standard PowerShell prompt | `false` |
| `AskCreateCodeFolder` | Prompt to create Code folder | `true` |
| `CodeFolderName` | Name of the code directory | `"Code"` |
| `EnableRandomTitle` | Enable randomized window titles | `false` |

## 🔧 Advanced Features

### Secure API Key Storage

The profile includes cross-platform secure storage for API keys:

```powershell
# Store API key securely
Set-SecureApiKey -ApiKey "your-gemini-api-key" -KeyName "GeminiAPI"

# Retrieve stored key
$apiKey = Get-SecureApiKey -KeyName "GeminiAPI"
```

**Storage Methods:**
- **Windows**: DPAPI (Data Protection API)
- **Linux/macOS**: OpenSSL encryption with user-specific keys

### Code Safety Features

The profile includes automatic risk analysis for PowerShell code:

```powershell
# Test code for potential risks
Test-PowerShellCodeRisk "Remove-Item C:\Important -Force"
# Returns: $true (risky operation detected)

# Execute code safely with confirmation
Invoke-SafePowerShellCode "Get-Process | Stop-Process"
# Prompts for confirmation on risky operations
```

### File Operations

```powershell
# Show directory tree with .gitignore support
Show-DirectoryTree -Path "C:\Projects" -IncludeFiles -RespectGitIgnore

# Get file contents recursively (respecting .gitignore)
Get-ContentRecursiveIgnore -Path "C:\Projects" -UseMarkdownFence $true
```

## 🛠️ System Requirements

### Core Requirements
- **PowerShell 7+** on Windows, Linux, or macOS

### Optional Dependencies

**For AI Features:**
- Google Gemini API key
- Internet connection
- **Linux/macOS**: OpenSSL
  ```bash
  # Ubuntu/Debian
  sudo apt-get install openssl
  
  # macOS (usually pre-installed)
  brew install openssl
  
  # Arch Linux
  sudo pacman -S openssl
  ```

**For GitHub Copilot:**
- GitHub Copilot subscription
- GitHub CLI: [Download here](https://cli.github.com/)
- GitHub Copilot CLI extension:
  ```bash
  gh extension install github/gh-copilot
  ```

## 🧪 Function Reference

### Core Profile Functions
- `Get-UserSettings` - Load configuration from JSON
- `Save-UserSettings` - Save configuration to JSON
- `Set-PromptColorScheme` - Configure prompt colors
- `Prompt` - Custom prompt function

### Utility Functions
- `Set-PWDClipboard` (`cpwd`) - Copy current directory to clipboard
- `Get-PublicIP` - Retrieve public IP address
- `Get-DiskSpace` - Display drive space information
- `Get-Weather` - Get weather for location
- `Get-ChtShHelp` - Query cht.sh for command help
- `Stop-ProcessConstantly` - Continuously stop a process

### File System Functions
- `Show-DirectoryTree` (`tree`) - Display directory tree
- `Get-ContentRecursiveIgnore` - Get file contents with ignore patterns

### Mathematical Functions
- **Trigonometric**: `Get-Sin`, `Get-Cos`, `Get-Tan`, `Get-Asin`, `Get-Acos`, `Get-Atan`, `Get-Atan2`
- **Power/Root**: `Get-Sqrt`, `Get-Pow`, `Get-Exp`
- **Logarithmic**: `Get-Log`, `Get-Log10`
- **Rounding**: `Get-Round`, `Get-Ceiling`, `Get-Floor`, `Get-Truncate`
- **Utility**: `Get-Abs`, `Get-Max`, `Get-Min`, `Get-Sign`

### AI Integration Functions
- `Invoke-GeminiChat` (`gemini`) - Google Gemini AI chat
- `Format-GeminiText` - Process Gemini formatting commands
- `Test-PowerShellCodeRisk` - Analyze code for security risks
- `Invoke-SafePowerShellCode` - Execute code with safety checks

### GitHub Copilot Functions
- `ghcs` - GitHub Copilot Suggest (command suggestions)
- `ghce` - GitHub Copilot Explain (command explanations)

### Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `vim` | `nvim` | Neovim editor |
| `vi` | `vim` | Vim editor |
| `cpwd` | `Set-PWDClipboard` | Copy working directory |
| `tree` | `Show-DirectoryTree` | Directory tree display |
| `gemini` | `Invoke-GeminiChat` | AI chat |
| `wrh` | `Write-Host` | Write to host |

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Fork** this repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Development Setup

1. Clone the repository
2. Make your changes to `Microsoft.PowerShell_profile.ps1`
3. Test with: `. $PROFILE`
4. Update documentation if needed

### Guidelines

- Follow PowerShell best practices
- Add documentation for new functions
- Test on multiple platforms when possible
- Update the README for new features

## 🗺️ Roadmap

- [ ] **Installation Script**: Automated cross-platform installation
- [ ] **Modular System**: Optional modules for different feature sets
  - [ ] Core Profile (basic functionality)
  - [ ] AI Integration Module
  - [ ] Mathematics Module  
  - [ ] GitHub Module
  - [ ] Development Tools Module
  - [ ] Security Module
- [ ] **Enhanced Terminal Integration**: Better terminal-specific features
- [ ] **Cloud Synchronization**: Settings sync across machines
- [ ] **Package Manager Integration**: Direct tool installation
- [ ] **Additional AI Providers**: OpenAI, Claude, etc.
- [ ] **Advanced Security**: Code sandboxing and ML-based risk analysis

## 🆘 Support

Need help? Here are your options:

- 📝 **Issues**: [GitHub Issues](https://github.com/adrian-cancio/PowerShell-Config/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/adrian-cancio/PowerShell-Config/discussions)
- 📧 **Email**: [Contact maintainer](mailto:adrian.cancio@example.com)

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **PowerShell Team**: For creating an amazing cross-platform shell
- **Google**: For the Gemini AI API
- **GitHub**: For Copilot integration
- **Community**: For feedback and contributions

## 📊 Project Status

🟢 **Active Development** - This project is actively maintained and new features are being added regularly.

---

<div align="center">

**[⭐ Star this repo](https://github.com/adrian-cancio/PowerShell-Config)** • **[🍴 Fork it](https://github.com/adrian-cancio/PowerShell-Config/fork)** • **[📝 Report an issue](https://github.com/adrian-cancio/PowerShell-Config/issues)**

Made with ❤️ by [Adrián Cancio](https://github.com/adrian-cancio)

</div>
