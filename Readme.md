# PowerShell Custom Profile

![PowerShell](https://img.shields.io/badge/PowerShell-7+-blue?logo=powershell)

A cross-platform PowerShell profile with a custom or Oh My Posh prompt, a once-a-day system banner, Gemini-powered helpers, pip safety wrappers, math functions and small everyday utilities. The code has Windows, Linux and macOS code paths, but it has only been runtime-verified on Linux (see [Platform status](#-platform-status)).

## ✨ Features

- 🎨 **Customizable Prompt**: two-line custom prompt with 12 color schemes, a lightweight Git status, or an optional [Oh My Posh](https://ohmyposh.dev) engine with a bundled Gruvbox theme
- 🖥️ **System Banner**: neofetch-style summary, shown at most once per calendar day, or on demand with `sysinfo`
- 🤖 **AI Integration**: Google Gemini chat with terminal-optimized responses
- 💬 **Smart Commit Messages**: Gemini-suggested commit messages based on staged changes
- 🧮 **Mathematical Functions**: thin wrappers around .NET `[Math]`
- 🐍 **Pip Wrappers**: warning before `pip install` outside a virtual environment
- 🐙 **Copilot wrappers (legacy)**: `ghcs`/`ghce` target the archived `gh-copilot` extension (see [Optional Dependencies](#optional-dependencies))
- 🔒 **Local API Key Storage**: DPAPI on Windows, Keychain or OpenSSL on macOS, OpenSSL on Linux
- 📁 **File Operations**: directory trees and recursive file dumps with simplified `.gitignore` handling
- ⚙️ **JSON Configuration**: persistent settings in `powershell.config.json`
- ⚡ **On-demand loading**: rarely used parts are loaded on first use (see [Profile Layout](#profile-layout))

## 🚀 Quick Start

### Prerequisites

- **PowerShell 7+**. Developed and run on 7.6; `ghcs`/`ghce` use the `clean` block, which needs 7.3+. Windows PowerShell 5.1 has not been tried.
- **Git** (prompt status, shortcuts, installation)
- Everything else is optional; see [Optional Dependencies](#optional-dependencies)

### Installation

The profile is modular. `Microsoft.PowerShell_profile.ps1` is only a loader that dot-sources the files in `Profile/`, so **copying the loader alone does not work** (it warns `Profile part not found` for each part and then stops with a "Cannot index into a null array" error). Install the loader, the whole `Profile/` folder and, if you want the Oh My Posh theme, `Themes/`.

1. **Find your real profile directory.** Do not assume `~/Documents/PowerShell`: on Windows the Documents folder can be redirected (OneDrive, a network share), and on Linux/macOS it normally is `~/.config/powershell`.

   ```powershell
   $PROFILE                        # full path of the CurrentUserCurrentHost profile
   Split-Path -Parent $PROFILE     # the directory to install into
   ```

2. **Back up what is already there and install** (run in `pwsh`). The backup copies only the files this profile would replace; nothing is deleted, and files that already exist are overwritten by the new copies after the backup is taken.

   ```powershell
   $dir = Split-Path -Parent $PROFILE
   New-Item -ItemType Directory -Path $dir -Force | Out-Null

   # Back up whatever would be replaced
   $backup = Join-Path $dir ('profile-backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
   New-Item -ItemType Directory -Path $backup -Force | Out-Null
   foreach ($name in 'Microsoft.PowerShell_profile.ps1', 'powershell.config.json', 'Profile', 'Themes') {
       $item = Join-Path $dir $name
       if (Test-Path -LiteralPath $item) { Copy-Item -LiteralPath $item -Destination $backup -Recurse }
   }

   # Install the loader and the complete modular tree
   $src = Join-Path ([IO.Path]::GetTempPath()) ('PowerShell-Config-' + [guid]::NewGuid())
   git clone https://github.com/adrian-cancio/PowerShell-Config.git $src
   Copy-Item -LiteralPath (Join-Path $src 'Microsoft.PowerShell_profile.ps1'), (Join-Path $src 'Profile'), (Join-Path $src 'Themes') -Destination $dir -Recurse -Force
   ```

   Files that no longer exist upstream are not removed from an older `Profile/` folder; the loader only reads the files it lists, so leftovers are harmless.

3. **Start a new `pwsh` session** (preferred over `. $PROFILE`, which re-runs the profile inside the current session).

4. **Configure your settings** (optional). On first start the profile writes `powershell.config.json` with the defaults next to your profile. See [Configuration Options](#configuration-options) and the note above it about that file being shared with PowerShell itself.

> Only copy `powershell.config.json` over an existing one deliberately. It may already hold your own PowerShell settings (for example `Microsoft.PowerShell:ExecutionPolicy`).

## 📖 Usage

### Basic Commands

```powershell
# Weather (network: wttr.in). Without a place it first asks ipinfo.io for your city.
Get-Weather "Madrid"

# Show directory tree
tree

# Copy current path to clipboard
cpwd

# Public IP (network request to https://api.ipify.org; see the privacy note under "System banner")
Get-PublicIP

# Show disk space
Get-DiskSpace

# Smart pip installations (with global warnings)
pip install package-name           # Warns if no venv/conda environment is active
pip install package-name --global  # Skips the warning
```

`Get-Weather` parameters are `-Place`, `-Language` (defaults to your culture's two-letter code, or `en`) and `-MaxAttempts` (1-20, default 3, only used for the automatic location lookup).

### AI Integration

These commands send data to external services and need credentials or tools you provide yourself. Nothing is called until you run them.

```powershell
# Start a Gemini chat (alias: gemini-chat); the first argument is -InitialPrompt
gemini-chat "how to find large files in PowerShell"
Invoke-GeminiChat -Model "gemini-flash-latest" -ResetApiKey

# Suggest a commit message from the staged changes (alias: sgcm)
sgcm
Invoke-SuggestCommitMessage -CommitCount 50 -Model "gemini-flash-latest"
Invoke-SuggestCommitMessage -Force  # Commit without asking for confirmation
Invoke-SuggestCommitMessage -AdditionalInstructions "Use conventional commits format"

# Legacy GitHub Copilot wrappers (see Optional Dependencies before relying on them)
ghcs "compress a folder"
ghce "Get-ChildItem -Recurse | Where-Object {$_.Length -gt 100MB}"
```

The default model is the `gemini-flash-latest` alias. `Invoke-SuggestCommitMessage` sends the staged diff, the branch name and up to `-CommitCount` (default 100) recent commit subjects to the Gemini API, so do not use it on repositories whose contents you cannot share with Google.

### Mathematical Functions

```powershell
# Calculate trigonometric functions
Get-Sin 1.5708  # π/2
Get-Cos 0       # 1
Get-Sqrt 16     # 4
Get-Pow 2 3     # 8

# Constants are available straight from .NET
[Math]::PI
[Math]::E
```

The math functions live in `Profile/Math.psm1` (20 exported functions, listed in the [Function Reference](#-function-reference)) and are imported at startup unless `"Microsoft.PowerShell.Profile:EnableMathModule": false`. Several names (`Get-Max`, `Get-Min`, `Get-Round`, ...) are generic; they are thin wrappers over `[Math]`: `Get-Max` and `Get-Min` compare exactly two values (`Get-Max 1 2`), and `Get-Round` takes an optional `-Digits`.

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
.\myenv\Scripts\Activate.ps1   # Windows
./myenv/bin/Activate.ps1       # Linux/macOS
pip install requests  # No warning shown
```

**Behavior:**
- Warns only when the **first** argument is `install` and no environment is detected.
- Detects environments through `$env:VIRTUAL_ENV` (venv/virtualenv) and `$env:CONDA_DEFAULT_ENV` (Conda).
- `--global` is removed before calling pip, but only on the path where the warning would have been shown. Inside an active environment, do not pass it (pip would receive the unknown flag).
- The pause (`Press Enter to continue`) only happens in an interactive session; with redirected input the warning is printed and the install continues.
- All other pip commands are passed through unchanged. `pip` and `pip3` resolve their own executables independently (the first application found on `PATH`, cached for the session).

### Prompt engines

Two engines are available, selected with `Microsoft.PowerShell.Profile:PromptEngine`:

| Value | Behavior |
|-------|----------|
| `Custom` (default) | The built-in two-line prompt described under [Prompt Customization](#prompt-customization). |
| `OhMyPosh` | Uses an `oh-my-posh` executable that is **already installed** and on `PATH`, with the theme set in `Microsoft.PowerShell.Profile:OhMyPoshTheme` (default `Themes/gruvbox.omp.json`). Nothing is downloaded. |

Any other `PromptEngine` value behaves like `Custom` (the comparison with `OhMyPosh` is case-insensitive). To switch, edit `powershell.config.json` and open a new terminal:

```json
{
    "Microsoft.PowerShell.Profile:PromptEngine": "OhMyPosh",
    "Microsoft.PowerShell.Profile:OhMyPoshTheme": "Themes/gruvbox.omp.json"
}
```

**Theme path.** A relative path is resolved against the profile folder (the folder that holds the loader), so the bundled theme needs the `Themes/` directory installed next to `Microsoft.PowerShell_profile.ps1`. Absolute local paths also work; `~` is **not** expanded. The theme file must be valid JSON, otherwise the profile falls back (see below).

**Precedence and fallback.** `DefaultPrompt: true` wins over both engines. If `oh-my-posh` is not found, the theme is missing or is not valid JSON, `oh-my-posh init` fails or returns nothing, or no prompt gets installed, the profile prints a warning and keeps the `Custom` prompt. To roll back, set `PromptEngine` back to `Custom` and open a new terminal rather than reloading inside a session where Oh My Posh is already initialized.

**What the bundled Gruvbox theme shows.** Two lines. The first has the OS icon, optional context tags, `user@host | path`, an optional Python environment, the failed-command marker (`✗` plus the exit code) and the execution time when it is at least 2 seconds (hard-coded in the theme, independent of `PromptMinDurationSeconds`). The second has the Git segment (branch or commit, ahead/behind, staged/working changes, `✓` when clean) and the `|>` marker, red after a failed command. It does **not** display the PowerShell version or the profile load time; use `Show-ProfileInfo` for load timings.

Context tags appear only when detected:

| Tag | Shown when |
|-----|-----------|
| `[SSH]` | Oh My Posh reports an SSH session |
| `[WSL]` | Oh My Posh reports WSL, or `WSL_DISTRO_NAME` is set |
| `[CONTAINER]` | the `CONTAINER` or `DISTROBOX_ENTERED` environment variable is set (variable names are case-sensitive on Linux/macOS, so a lowercase `container` variable does not match) |
| `[ADMIN]` | the process runs as root/administrator |
| `[py:name]` | a Python virtual or Conda environment is active (an installed Python or a Python project alone does not trigger it) |

`PromptColorScheme`, `GitPrompt`, `GitPromptTimeoutMs`, `PromptMinDurationSeconds` and `EnableRandomTitle` only affect the `Custom` engine; to change the Oh My Posh look, edit the JSON theme. The theme uses icon glyphs for the OS and the branch, so a Nerd Font is probably needed to render them.

**Tests.** Run from the repository root:

```powershell
pwsh -NoProfile -NonInteractive -File Tests/Prompt.Tests.ps1
pwsh -NoProfile -NonInteractive -File Tests/Prompt.Context.Tests.ps1 -ScratchRoot <scratch-directory>
pwsh -NoProfile -NonInteractive -File Tests/Profile.Lazy.Tests.ps1 -ScratchRoot <scratch-directory>
```

- `Prompt.Tests.ps1` parses every `Profile/*.ps1` and exercises engine selection and the fallbacks, including a real activation, so it needs `oh-my-posh` installed.
- `Prompt.Context.Tests.ps1` renders the theme with the real `oh-my-posh` and a throwaway Python `venv` (no pip). SSH, WSL, container and Conda inputs are simulated through environment variables in child processes; `[ADMIN]` is compared against the real identity and elevation is never simulated.
- `Profile.Lazy.Tests.ps1` starts child `pwsh` processes with `HOME`, `XDG_*`, `LOCALAPPDATA` and `APPDATA` pointed at a scratch directory, and checks startup, lazy loading, completion and the system banner. The public IP request is simulated, so no network is needed. The scratch directories are not deleted afterwards.

### System banner

When `Microsoft.PowerShell.Profile:ShowSystemInfo` is `true` (the default) the profile prints a neofetch-style `SYSTEM` banner **at most once per calendar day**. You can always print it on demand:

```powershell
sysinfo               # alias of Show-SystemInfo; ignores the once-a-day marker
sysinfo -PublicIP     # also look up the public IP address (network request)
```

**Fields.** Rows that cannot be determined on the current platform are omitted. `Rendered` is the time taken to build the banner on your machine.

| Row | Source | Platforms |
|-----|--------|-----------|
| `User`, `OS` (with architecture), `Local IP`, `Rendered` | .NET, plus `ip -brief addr` on Linux | all |
| `Up` | `/proc/uptime`, Win32 CIM, `sysctl kern.boottime` | Linux, Windows, macOS |
| `Mem` | `/proc/meminfo`, Win32 CIM, `sysctl hw.memsize` (macOS shows only the total) | all (`n/a` if unavailable) |
| `Load` | `/proc/loadavg`, `sysctl vm.loadavg` | Linux, macOS |
| `Kernel`, `Pkgs` (`rpm -qa`, else `dpkg-query`), `Term`, `CPU`, `Disk` (`df -h /`), `Bat` (`/sys/class/power_supply/BAT1`) | local files and commands | Linux only |
| `WM` | hard-coded to the text `Niri` | Linux only (see [Known limitations](#known-limitations)) |
| `Public IP` | `https://ifconfig.me/ip`, then `https://api.ipify.org` | only with `-PublicIP` or `ShowPublicIP` |

The banner does not show the shell name or version. On Linux it runs external programs (`rpm`/`dpkg-query`, `df`, `ip`) and on macOS `sysctl`; counting packages in particular can take a noticeable fraction of a second on some systems, so no fixed render time is promised. Read the `Rendered` row on your machine.

**Once-per-day policy (as implemented).** On startup the profile looks for a marker file named `sysinfo-<yyyyMMdd>` (local date) in `$HOME/.local/share/powershell-profile/`, on every platform including Windows. If it is missing, the banner is printed and the empty marker is created; if it exists, nothing is printed. What follows directly from the code:

- The first session of the day that loads this profile uses up the banner, whatever terminal, host or action started it. The code does **not** limit the banner to a particular key binding or terminal shortcut, nor to SSH sessions, nor to any other trigger.
- There is **no interactive-session guard**. A non-interactive `pwsh -Command ...` or `pwsh -File ...` that loads the profile also prints the banner (to the host, so it can end up in captured output) and consumes the day's marker. Use `-NoProfile` for scripts, or set `ShowSystemInfo` to `false`.
- The marker directory is separate from the profile data directory (see [Other files and locations](#other-files-and-locations)), and old markers are never cleaned up (one empty file per day the banner was shown). Delete today's file to see the banner again on the next start.

**Privacy and network.** With `-PublicIP`, or when `Microsoft.PowerShell.Profile:ShowPublicIP` is `true`, the banner sends an HTTPS request to `ifconfig.me`, and to `api.ipify.org` if that fails, with a 3-second timeout each; if both fail it shows `n/a`. Those services see your public address and ordinary request metadata. With `ShowPublicIP` enabled, this request happens during the startup that prints the banner. `ShowPublicIP` is `false` by default. `Get-PublicIP` uses `https://api.ipify.org` with no explicit timeout. Separately, `Local IP` is the first IPv4 address of an active, non-loopback interface (Linux: the first `UP` interface reported by `ip -brief addr`); on a host with a directly assigned public address (some servers, VPS or cloud instances) that address **is** public. Treat banner output as sensitive when sharing screenshots or logs.

### Prompt Customization

This section describes the `Custom` engine. The prompt is two lines. An OS icon (`⊞` Windows, `λ` Linux, `⌘` macOS) comes first, then `user@hostname` and the current path (the home directory is shortened to `~`). The second line holds the Git status and the prompt marker:

```
⊞ ||user@host|-|~\Code\project|| ✗1 3.2s
|main ↑2↓1 +1 ~3 ?2 $1|>
```

- `✗N` appears when the last command failed. `N` is the exit code and is only shown for a native command whose exit code is new since the previous prompt.
- The duration appears only when the last command took at least `PromptMinDurationSeconds` (a value of `0` or less falls back to 2).
- Git status: `↑` ahead, `↓` behind, `+` staged, `~` modified, `?` untracked, `!` conflicts, `$` stashes, `✓` clean. A detached HEAD shows `:abc1234`.
- Git status is skipped on UNC paths and, on Windows, network drives. Results are cached per directory and command (5 seconds, or 30 seconds after a timeout), and `…` replaces the status if `git status` exceeds `GitPromptTimeoutMs`.
- The `Random` scheme picks new colors on every prompt.
- `EnableRandomTitle` only has an effect while the `Hackerman` scheme is applied.

There are **12** color schemes (the `PromptColorSchemes` enum):

- `Default`, `Blue`, `Green`, `Cyan`, `Red`, `Magenta`, `Yellow`, `Gray`
- `Random`, `Asturias`, `Spain`, `Hackerman`

```powershell
# Change the scheme for the current session only
Set-PromptColorScheme -ColorScheme "Hackerman"

# Persist it (writes the whole current settings object to powershell.config.json)
Save-UserSettings
```

`Set-PromptColorScheme` only updates the in-memory settings; the prompt re-applies the stored scheme on every redraw. To make the change permanent either run `Save-UserSettings` afterwards or edit `powershell.config.json`:

```json
{
    "Microsoft.PowerShell.Profile:PromptColorScheme": "Hackerman"
}
```

## ⚙️ Configuration

The profile reads its settings from `powershell.config.json`, located in the same directory as your profile (`Split-Path -Parent $PROFILE`). If the file does not exist, the first start creates it with all defaults:

```json
{
    "Microsoft.PowerShell.Profile:PromptColorScheme": "Default",
    "Microsoft.PowerShell.Profile:PromptEngine": "Custom",
    "Microsoft.PowerShell.Profile:OhMyPoshTheme": "Themes/gruvbox.omp.json",
    "Microsoft.PowerShell.Profile:DefaultPrompt": false,
    "Microsoft.PowerShell.Profile:AskCreateCodeFolder": true,
    "Microsoft.PowerShell.Profile:CodeFolderName": "Code",
    "Microsoft.PowerShell.Profile:EnableRandomTitle": false,
    "Microsoft.PowerShell.Profile:EnableMathModule": true,
    "Microsoft.PowerShell.Profile:GitPrompt": true,
    "Microsoft.PowerShell.Profile:GitPromptTimeoutMs": 1500,
    "Microsoft.PowerShell.Profile:PromptMinDurationSeconds": 2,
    "Microsoft.PowerShell.Profile:EnableZoxide": true,
    "Microsoft.PowerShell.Profile:ShowSystemInfo": true,
    "Microsoft.PowerShell.Profile:ShowPublicIP": false
}
```

Missing keys fall back to these defaults, and unknown keys in the file are kept. If the file exists but is empty or invalid JSON, the profile warns and uses the defaults for that session (without overwriting the file).

> **This file is shared with PowerShell itself.** `powershell.config.json` in the user configuration directory is also read by PowerShell at startup for its own settings (for example `Microsoft.PowerShell:ExecutionPolicy`, `PSModulePath`, `ExperimentalFeatures`). Keep any existing PowerShell keys when you add the `Microsoft.PowerShell.Profile:*` keys. Per Microsoft's documentation, invalid JSON in that file can prevent an interactive session from starting, and PowerShell ignores keys it does not recognize. `Save-UserSettings` rewrites the whole file from the settings loaded in memory.

### Configuration Options

All keys are prefixed with `Microsoft.PowerShell.Profile:` in the file.

| Setting | Description | Default |
|---------|-------------|---------|
| `PromptColorScheme` | Color scheme of the `Custom` prompt (one of the 12 schemes) | `"Default"` |
| `PromptEngine` | `Custom` or `OhMyPosh` (see [Prompt engines](#prompt-engines)) | `"Custom"` |
| `OhMyPoshTheme` | Theme used by the `OhMyPosh` engine; relative to the profile folder, or an absolute path | `"Themes/gruvbox.omp.json"` |
| `DefaultPrompt` | Use a plain `PS path>` prompt instead of either engine | `false` |
| `AskCreateCodeFolder` | Ask to create the `Code` folder if it is missing (only in interactive sessions with input not redirected; answering anything but `Y`/`YES` sets this to `false` and saves the file) | `true` |
| `CodeFolderName` | Name of the code directory under `$HOME` (used by `cdc`) | `"Code"` |
| `EnableRandomTitle` | Randomized window title when the `Hackerman` scheme is applied (`Custom` engine) | `false` |
| `EnableMathModule` | Import `Profile/Math.psm1` at startup | `true` |
| `GitPrompt` | Show branch and status in the `Custom` prompt | `true` |
| `GitPromptTimeoutMs` | Maximum wait for `git status` before showing `…` (values `<= 0` use 1500) | `1500` |
| `PromptMinDurationSeconds` | Show the last command duration at or above this threshold (values `<= 0` use 2) | `2` |
| `EnableZoxide` | Run `zoxide init powershell` when `zoxide` is on `PATH` | `true` |
| `ShowSystemInfo` | Print the system banner on the first profile load of each calendar day (see [System banner](#system-banner)) | `true` |
| `ShowPublicIP` | Make the banner request your public IP (network request) | `false` |

### Other files and locations

- **`powershell.config.json`** and **`profile.ps1`** are untracked (listed in `.gitignore`), because they hold local state. `profile.ps1` is **not** a file this loader sources: it is PowerShell's own *CurrentUserAllHosts* profile (`$PROFILE.CurrentUserAllHosts`), which PowerShell runs by itself, before the *CurrentUserCurrentHost* profile (`Microsoft.PowerShell_profile.ps1`), for every host. Create it only if you want code that runs in all hosts; this repository does not need it and does not read it.
- **Data directory** (`Get-ProfileDataDirectory`, used for the cached `gh` completion script): `$env:POWERSHELL_PROFILE_DATA` if set; otherwise `%LOCALAPPDATA%\PowerShell-Profile` on Windows, `$XDG_DATA_HOME/PowerShell-Profile`, or `~/.local/share/PowerShell-Profile`.
- **Banner marker directory:** `~/.local/share/powershell-profile/` (see [System banner](#system-banner)). Note the different capitalization and location compared with the data directory on Windows.
- **API keys:** `~/.powershell-secrets/` (see [Secure API Key Storage](#secure-api-key-storage)).

### Profile Layout

`Microsoft.PowerShell_profile.ps1` is a short loader that dot-sources the files in `Profile/` in a fixed order and records how long each took. Parts marked *lazy* are not read at startup.

| File | Loaded | Contents |
|------|--------|----------|
| `Settings.ps1` | startup | Settings file handling, OS detection, `Code` folder prompt |
| `Common.ps1` | startup | Shared helpers (fast executable lookup, data directory) |
| `Git.ps1`, `Prompt.ps1` | startup | Git status and the prompt (including the Oh My Posh switch) |
| `Utilities.ps1` | startup | Weather, IP, disk space, directory tree, `Stop-ProcessConstantly` |
| `Shortcuts.ps1` | startup | Navigation and git shortcuts, zoxide |
| `SystemInfo.ps1` | startup | `Show-SystemInfo` / `sysinfo` and the once-a-day banner |
| `Pip.ps1`, `Aliases.ps1` | startup | pip wrappers; aliases |
| `LazyLoaders.ps1` | startup | Registers stub functions and tab completers for the lazy parts below |
| `Math.psm1` | startup (unless `EnableMathModule` is `false`) | Math functions, imported as a module |
| `Copilot.ps1` | lazy | `ghcs`, `ghce` |
| `SecureApiKey.ps1` | lazy | API key storage |
| `GeminiTools.ps1`, `GeminiChat.ps1`, `GeminiCommit.ps1` | lazy | Risk analysis and text formatting, chat, commit messages |
| `Completions.ps1` | lazy | Completion helpers (`Update-ProfileCompletions`) and the implementations behind `git`, `gh` and `cdc` completion |
| `Diagnostics.ps1` | lazy | `Show-ProfileInfo` |
| `Readline.ps1` | **never** | Optional PSReadLine tuning (prediction mode and history filtering). It is present in the repository but is **not** in the loader's list, so it is not active; the `PredictionMode`, `PredictionViewStyle` and `PredictionToggleKey` keys it reads are not part of the defaults. |

**Lazy loading, as implemented.** For each lazy function the loader registers a small global stub. The first call dot-sources the real file, replaces the stub with the real function and forwards the call; later calls go straight to the real function. If the file defined no such function, the stub throws instead of recursing. Tab completion for `git`, `gh` and `cdc` is registered at startup by `LazyLoaders.ps1`; the first time you press Tab for one of them, the completer loads `Completions.ps1`. For `gh`, the first completion generates and caches the completion script by running `gh completion -s powershell` (this needs `gh`, and it is why the first `gh` completion is slower); `Update-ProfileCompletions` regenerates it after a `gh` upgrade. `Tests/Profile.Lazy.Tests.ps1` asserts that no lazy part is loaded at startup, that the first call to representative functions loads their part, and that `git` completion works on the first and later attempts. Lazy loading reduces the work done at startup, but this README makes no promise about the resulting startup time or about any warning disappearing; measure your own system with `Show-ProfileInfo` (per-part load times for the current session).

### Shortcuts

| Command | Action |
|---------|--------|
| `..`, `...`, `....` | Go up one, two or three folders |
| `mkcd <path>` | Create a folder and enter it |
| `cdc [project]` | Jump to your `Code` folder (tab-completes projects) |
| `gst`, `gd`, `gds` | `git status -sb`, `git diff`, `git diff --staged` |
| `ga`, `gaa`, `gcmsg <msg>` | `git add`, `git add --all`, `git commit -m` |
| `gco`, `gsw`, `gpull`, `gpush` | `git checkout`, `switch`, `pull`, `push` |
| `glog` | Compact graph of the last 20 commits |
| `gundo` | Undo the last commit, keeping its changes staged |
| `sysinfo [-PublicIP]` | Print the system banner now (see [System banner](#system-banner)) |
| `Show-ProfileInfo` | PowerShell version, load time per part, tool lookup (`git`, `gh`, `python`, `pip`, `docker`, `nvim`, `zoxide`, `openssl`) |
| `Update-ProfileCompletions` | Regenerate the cached `gh` completion script (needs `gh`) |

`gst`, `gd`, `ga` and the other Git shortcuts forward any extra arguments to `git`. They are plain functions, so they take precedence over any external command with the same name on your `PATH`.

## 🔧 Advanced Features

### Secure API Key Storage

API keys (by default `GeminiAPI`) can be stored per user. You normally do not need to call these functions: `gemini-chat` and `sgcm` ask for the key with masked input the first time and store it.

```powershell
Set-SecureApiKey -ApiKey "your-gemini-api-key" -KeyName "GeminiAPI"
$apiKey = Get-SecureApiKey -KeyName "GeminiAPI"
```

| Platform | Method | File |
|----------|--------|------|
| Windows | DPAPI (`ConvertFrom-SecureString`), tied to your Windows account | `~/.powershell-secrets/<KeyName>.key` |
| Linux | `openssl enc -aes-256-cbc -pbkdf2` | `~/.powershell-secrets/<KeyName>.key` |
| macOS | Keychain through `security`, with the OpenSSL file as fallback | Keychain / same file |

Keys live in `~/.powershell-secrets/` (mode `700` on Linux/macOS, file `600` only for migrated keys), outside the profile folder. A `<KeyName>.key` found next to the profile (the old location) is moved there on first use. Be realistic about the protection offered on Linux and for the macOS fallback:

- The OpenSSL passphrase is **derived from your username, hostname and key name**, not from a secret you provide. It stops casual reading of the file, but anyone who can read the file and knows those values can decrypt it.
- The passphrase is passed to `openssl` on its command line (`-pass pass:...`), so it can be visible to other local users in the process list while the command runs.
- `Get-SecureApiKey` returns the key as plain text and the value is sent to Google in an HTTP header by the Gemini functions.
- See [Known limitations](#known-limitations) for an unverified macOS Keychain issue.

### Code Safety Features

`Test-PowerShellCodeRisk` is a **keyword heuristic** and not a sandbox or a security boundary. It matches the text of the code against a list of patterns (file, process, network, package-manager, privilege and system-path terms) and returns `$true` for a match. It can both over-match (any text containing `rm`, `del`, `cp` or `curl`, even inside a longer word such as `Format-Table`) and miss dangerous code.

```powershell
Test-PowerShellCodeRisk "Remove-Item C:\Important -Force"   # True
Test-PowerShellCodeRisk "Get-Date"                          # False
Test-PowerShellCodeRisk "Get-ChildItem | Format-Table"      # True (false positive: "rm" in "Format")

# Returns a result object, it does not print the command's output
$r = Invoke-SafePowerShellCode "Get-Date"
$r.Output; $r.Error; $r.WasRisky; $r.Executed
```

`Invoke-SafePowerShellCode` asks for `y`/`yes` confirmation when the heuristic flags the code (skip with `-AutoApprove`), runs the code as a background job, and stops it after 30 seconds. It returns `ExecutionResult`, `Output`, `Error`, `WasRisky`, `UserApproved` and `Executed`. `ghcs` uses the same heuristic to print a warning before it asks `Run it? (y/N)`; it never runs a suggestion without that confirmation, and when input is not interactive the answer defaults to "no".

### File Operations

```powershell
# Directories only (hidden/dot entries are always skipped)
Show-DirectoryTree -Path . -Depth 2

# Include files, and hide those matching .gitignore files found under the path
Show-DirectoryTree -Path . -IncludeFiles -RespectGitIgnore -AdditionalIgnore "*.log"

# Print every non-ignored file with its relative path, optionally in Markdown fences
Get-ContentRecursiveIgnore -Path . -UseMarkdownFence $true
```

- `-RespectGitIgnore` only has an effect together with `-IncludeFiles`; without `-IncludeFiles` nothing is filtered.
- `.gitignore` handling is a simplified glob matcher written for this profile, not Git itself, so complex patterns (such as `**` or character classes) may not behave as in Git. Use `git ls-files` when exactness matters.
- `Get-ContentRecursiveIgnore` always applies ignore patterns, skips hidden/dot entries, and reads every remaining file as text, including large or binary files. Check the tree it prints first when pointing it at an unfamiliar folder.

### AI-Powered Git Commit Messages

`Invoke-SuggestCommitMessage` (alias `sgcm`) asks Gemini for a commit message based on your staged changes. It needs a Gemini API key (asked for on first use) and network access.

```powershell
# Basic usage - analyzes staged changes and suggests a commit message
sgcm
# or
Invoke-SuggestCommitMessage

# Customize the number of previous commits sent as style context (default: 100)
Invoke-SuggestCommitMessage -CommitCount 50

# Use a specific Gemini model (default: the gemini-flash-latest alias)
Invoke-SuggestCommitMessage -Model "gemini-flash-latest"

# Commit with the suggestion without prompting for confirmation
Invoke-SuggestCommitMessage -Force

# Add specific instructions for the commit message
Invoke-SuggestCommitMessage -AdditionalInstructions "Use conventional commits format with emoji"

# Load instructions from a file
Invoke-SuggestCommitMessage -InstructionsFile "commit-guidelines.txt"

# Show detailed progress information
Invoke-SuggestCommitMessage -Verbose

# Get just the message for use in scripts/automation (no prompts, $null on failure)
$commitMsg = Invoke-SuggestCommitMessage -ReturnOnly

# Forget the stored API key and enter a new one
Invoke-SuggestCommitMessage -ResetApiKey
```

**What it does:**
- Reads the staged diff, the branch name and the last `-CommitCount` commit subjects, and sends all of them to the Gemini API (`generativelanguage.googleapis.com`). The whole staged diff is sent, so avoid it for content you cannot share.
- Tells the model to match the language, format and prefixes of the previous commits; how well it does so depends on the model.
- Lists the staged files before acting.
- Interactive loop: type `commit` (lowercase, exact) to run `git commit -m` with the message, press Enter to copy it to the clipboard, or type anything else as feedback to regenerate the message with the conversation so far.
- `-Force` commits immediately after printing the message and the staged files. `-ReturnOnly` prints nothing and returns the message string.

**Workflow:**
1. Stage your changes: `git add .`
2. Run: `sgcm`
3. Review the generated commit message
4. Choose an action:
   - Type `commit` to commit with the message
   - Press Enter to copy to clipboard
   - Type feedback to refine the message (e.g., "make it shorter")

### Network access

The profile contacts the network only when you run the following, plus one optional startup request. Nothing in this table is called by `-NoProfile` sessions, and none of it runs at startup unless stated.

| Command | Contacts | Sends |
|---------|----------|-------|
| `sysinfo -PublicIP`, or `ShowPublicIP: true` | `ifconfig.me`, then `api.ipify.org` as a fallback | an HTTPS request (your public address is visible to the service). With `ShowPublicIP` this happens during the startup that prints the banner |
| `Get-PublicIP` | `api.ipify.org` | an HTTPS request |
| `Get-Weather` | `wttr.in`; also `ipinfo.io` when no place is given | the place name (or your public address, for the location lookup) |
| `Get-ChtShHelp`, `Get-PowershellChtShHelp` | `cht.sh` | the command name in the URL |
| `gemini-chat`, `sgcm` | `generativelanguage.googleapis.com` | your prompts, or the staged diff and commit subjects; your API key as a header |
| `ghcs`, `ghce` | whatever the GitHub CLI extension contacts | your prompt (legacy, see below) |

## 🛠️ System Requirements

### Core Requirements
- **PowerShell 7** on Windows, Linux or macOS. The profile is written for PowerShell 7 (it relies on `$IsWindows`/`$IsLinux`/`$IsMacOS`, `[Random]::Shared` and the `clean` block, added in 7.3) and has not been tried on Windows PowerShell 5.1. Everything that was verified ran on 7.6.7.
- **Git** for the prompt status, the Git shortcuts and the commit tool

### Optional Dependencies

Nothing below is installed or downloaded by the profile.

- **Oh My Posh**: only for `PromptEngine: OhMyPosh`. Install it with your preferred method; see [ohmyposh.dev](https://ohmyposh.dev).
- **zoxide**: initialized when found and `EnableZoxide` is not `false`.
- **Neovim**: the `vim`, `vi` and `gvim` aliases point at `nvim`. See [Aliases](#aliases).
- **Python**: only for the pip wrappers and the `[py:...]` tag.

**For AI features (`gemini-chat`, `sgcm`):**
- A Google Gemini API key and an Internet connection.
- **Linux, and macOS when the Keychain is not used**: the `openssl` command, used to encrypt the stored key. Install it with your package manager (it is installed by default on many systems).

**For `ghcs` / `ghce` (legacy GitHub Copilot in the CLI):**
- The [GitHub CLI](https://cli.github.com/) and a GitHub Copilot subscription.
- These functions run `gh copilot suggest -t <target> -s <file>` and `gh copilot explain`, which is the interface of the `github/gh-copilot` extension (`gh extension install github/gh-copilot`).
- **Limitation:** according to its repository, that extension was deprecated on 2025-10-25 and archived on 2025-10-30 in favor of GitHub Copilot CLI. Current `gh` releases ship a built-in `gh copilot` command that launches the newer Copilot CLI instead. This audit did not run `ghcs`/`ghce` and did not verify whether the `suggest`/`explain` subcommands still work with your `gh` version or extension, so treat them as legacy wrappers that may fail. Only the profile side was verified: the functions load lazily, ask for confirmation, and never run a suggestion without it.

## 🧭 Platform status

What was actually exercised: Linux (Fedora 44), PowerShell 7.6.7 and Oh My Posh 28.10.0, using the bundled `Tests/` scripts and isolated child processes.

**Not run, so not verified:** the Windows paths (DPAPI key storage, CIM-based uptime and memory, network-drive detection for Git status, `Documents` folder redirection), the macOS paths (Keychain, `sysctl`-based uptime, load and memory), real elevation for the `[ADMIN]` tag, and how the Gruvbox theme icons look in your font. Treat the cross-platform parts as written for those systems but unconfirmed.

### Known limitations

These are observed behaviors of the current code, listed so they do not surprise you:

- **Banner trigger:** once per calendar day, on the first profile load, for any session type, as described under [System banner](#system-banner). It is not limited to SSH or to any shortcut, and it does not skip non-interactive startups.
- **Startup side effects:** loading the profile creates `powershell.config.json` if it is missing (also in non-interactive sessions), and, when `ShowSystemInfo` is `true`, the banner marker directory and file. The data directory is only created when a lazy part such as `Show-ProfileInfo` or the `gh` completer needs it.
- **`WM` banner row:** the Linux window manager is hard-coded to `Niri` rather than detected.
- **Aliases:** `vim`, `vi` and `gvim` are defined unconditionally and point at `nvim`. Because aliases take precedence over executables, they hide a real `vim` and fail if `nvim` is not installed.
- **`Readline.ps1`:** present but not loaded (see [Profile Layout](#profile-layout)).
- **`Set-PromptColorScheme`** does not persist the choice (see [Prompt Customization](#prompt-customization)).
- **`pip install ... --global`** inside an active environment passes `--global` to pip (see the pip section).
- **macOS Keychain retrieval (not run on macOS):** `Get-SecureApiKey` calls `Start-Process ... -RedirectStandardOutput` without a value. That fails parameter binding in PowerShell on any platform (confirmed on Linux by calling `Start-Process` with the same switch), the error is swallowed, and the function falls back to the OpenSSL file, which `Set-SecureApiKey` does not create when the Keychain write succeeds. The likely effect is that a stored key is not found and you are asked for it again.
- **`Get-PublicIP`** has no timeout or error handling.

## 🧪 Function Reference

### Core Profile Functions
- `Get-UserSettings` - Load configuration from JSON (creates the file with defaults if missing)
- `Save-UserSettings` - Write the in-memory settings to the JSON file
- `Set-PromptColorScheme` - Set the `Custom` prompt colors for the current session
- `Prompt` - The `Custom` prompt function
- `Show-SystemInfo` (`sysinfo`) - Print the system banner; `-PublicIP` adds a public IP lookup
- `Show-ProfileInfo` - Profile diagnostics and per-part load times
- `Update-ProfileCompletions` - Regenerate the cached `gh` completion script
- `Get-ProfileDataDirectory`, `Find-ProfileExecutable` - Internal helpers (data directory, `PATH` lookup)

### Utility Functions
- `Set-PWDClipboard` (`cpwd`) - Copy current directory to clipboard
- `Get-PublicIP` - Retrieve public IP address (network request)
- `Get-DiskSpace` - Display drive space information
- `Get-Weather` - Weather for a place (`-Place`, `-Language`, `-MaxAttempts`)
- `Get-ChtShHelp`, `Get-PowershellChtShHelp` - Query cht.sh for command help (the second prefixes `powershell/`)
- `Stop-ProcessConstantly` - Repeatedly stop processes with a given name (`-ProcessName`, `-IntervalMilliseconds` 10-60000, default 250) until you press Ctrl+C

### File System Functions
- `Show-DirectoryTree` (`tree`) - Display directory tree (`-Path`, `-Depth`, `-IncludeFiles`, `-RespectGitIgnore`, `-AdditionalIgnore`)
- `Get-ContentRecursiveIgnore` - Get file contents with ignore patterns (`-Path`, `-AdditionalIgnore`, `-UseMarkdownFence`)
- `mkcd`, `cdc`, `..`, `...`, `....` - Navigation (see [Shortcuts](#shortcuts))

### Mathematical Functions
Exported by `Profile/Math.psm1` (20 functions):
- **Trigonometric**: `Get-Sin`, `Get-Cos`, `Get-Tan`, `Get-Asin`, `Get-Acos`, `Get-Atan`, `Get-Atan2`
- **Power/Root**: `Get-Sqrt`, `Get-Pow`, `Get-Exp`
- **Logarithmic**: `Get-Log`, `Get-Log10`
- **Rounding**: `Get-Round`, `Get-Ceiling`, `Get-Floor`, `Get-Truncate`
- **Utility**: `Get-Abs`, `Get-Max`, `Get-Min`, `Get-Sign`

### AI Integration Functions
- `Invoke-GeminiChat` (`gemini-chat`) - Google Gemini AI chat (`-InitialPrompt`, `-Model`, `-ResetApiKey`)
- `Invoke-SuggestCommitMessage` (`sgcm`) - Commit message suggestions (`-CommitCount`, `-Model`, `-Force`, `-AdditionalInstructions`, `-InstructionsFile`, `-ResetApiKey`, `-ReturnOnly`)
- `Get-DefaultGeminiFlashModel` - Returns the default model name (`gemini-flash-latest`)
- `Format-GeminiText` - Render Gemini's `[FG:Color]`/`[BG:Color]` formatting markers
- `Test-PowerShellCodeRisk` - Keyword heuristic for risky code
- `Invoke-SafePowerShellCode` - Run code in a job after the heuristic and a confirmation
- `Set-SecureApiKey`, `Get-SecureApiKey` (and the internal `Get-ApiKeyFilePath`, `Set-SecureApiKeyUnix`, `Get-SecureApiKeyUnix`) - API key storage

### GitHub Copilot Functions (legacy)
- `ghcs` - Suggest a command (`-Target gh|git|shell`, default `shell`); shows it, flags risky ones and asks before running
- `ghce` - Explain a command

### Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `vim` | `nvim` | Neovim (defined even if `nvim` is not installed) |
| `vi` | `vim` | Resolves to `nvim` through `vim` |
| `gvim` | `vim` | Resolves to `nvim` through `vim` |
| `wrh` | `Write-Host` | Write to host |
| `cpwd` | `Set-PWDClipboard` | Copy working directory |
| `tree` | `Show-DirectoryTree` | Directory tree display (shadows an external `tree` command) |
| `gemini-chat` | `Invoke-GeminiChat` | Gemini chat |
| `sgcm` | `Invoke-SuggestCommitMessage` | Commit message suggestions |
| `pip` | `Invoke-PipWrapper` | pip with the global-install warning |
| `pip3` | `Invoke-Pip3Wrapper` | pip3 with the global-install warning |
| `sysinfo` | `Show-SystemInfo` | System banner on demand |

There is no `gemini` alias; use `gemini-chat` or `Invoke-GeminiChat`.

## 🤝 Contributing

Contributions are welcome, though there is no formal process or response-time commitment:

1. **Fork** this repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Development Setup

1. Clone the repository.
2. Make your changes in `Profile/*.ps1` (or `Themes/`). `Microsoft.PowerShell_profile.ps1` is only the loader; a new startup part must be added to its `$ProfileParts` list, and a new lazy part needs `Register-LazyFunction` entries in `Profile/LazyLoaders.ps1`.
3. Test in a fresh `pwsh` session, ideally with `HOME`/`XDG_*` pointing at a scratch directory so your real settings, banner marker and stored keys are not touched. `Tests/Profile.Lazy.Tests.ps1` does this for you.
4. Run the checks listed under [Prompt engines](#prompt-engines). Only `Profile.Lazy.Tests.ps1` redirects `HOME` and `XDG_*`; the two prompt tests do not.
5. Update this README if behavior or defaults change.

### Guidelines

- Follow PowerShell best practices
- Add documentation for new functions
- Test on multiple platforms when possible
- Update the README for new features

## 🗺️ Roadmap

Done:

- [x] **Modular layout**: loader plus `Profile/*.ps1` parts, with per-part load timings (`Show-ProfileInfo`)
- [x] **Lazy loading** of the Gemini, Copilot, API-key, completion and diagnostics parts
- [x] **Optional math module** (`EnableMathModule`)
- [x] **Alternative prompt engine**: Oh My Posh with a bundled Gruvbox theme and fallback to `Custom`
- [x] **System banner** with `sysinfo`, once per calendar day

Not done:

- [ ] **Installation Script**: automated cross-platform installation (the steps above are manual)
- [ ] **Fully optional feature sets**: only the math module can be switched off; the AI, GitHub, development-tools and security parts are always present
- [ ] **Interactive-only / trigger-limited banner**: guard the banner against non-interactive startups and decide which sessions should show it (see [Known limitations](#known-limitations))
- [ ] **Current GitHub Copilot CLI support**: replace or adapt `ghcs`/`ghce` for the newer Copilot CLI
- [ ] **Enhanced Terminal Integration**: Better terminal-specific features
- [ ] **Cloud Synchronization**: Settings sync across machines
- [ ] **Package Manager Integration**: Direct tool installation
- [ ] **Additional AI Providers**: OpenAI, Claude, etc.
- [ ] **Advanced Security**: Code sandboxing and ML-based risk analysis

## 🆘 Support

This is a personal configuration shared as-is, with no support or response-time commitment. If you find a problem, you can open an [issue](https://github.com/adrian-cancio/PowerShell-Config/issues) and include your OS, PowerShell version (`$PSVersionTable.PSVersion`) and the output of `Show-ProfileInfo`.

## 📝 License

This repository does not currently contain a `LICENSE` file, so no license terms are declared for it.

## 🙏 Acknowledgments

- **PowerShell**: the shell this profile is written for
- **Oh My Posh**: optional prompt engine
- **Google Gemini API**: used by the optional chat and commit helpers
- **GitHub CLI**: used by the legacy Copilot wrappers

---

<div align="center">

**[⭐ Star this repo](https://github.com/adrian-cancio/PowerShell-Config)** • **[🍴 Fork it](https://github.com/adrian-cancio/PowerShell-Config/fork)** • **[📝 Report an issue](https://github.com/adrian-cancio/PowerShell-Config/issues)**

Made with ❤️ by [Adrián Cancio](https://github.com/adrian-cancio)

</div>
