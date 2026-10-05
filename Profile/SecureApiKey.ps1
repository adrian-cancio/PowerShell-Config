function Get-ApiKeyFilePath {
    param(
        [Parameter(Mandatory)]
        [string]$KeyName
    )

    $secretsDirectory = Join-Path $HOME ".powershell-secrets"
    if (-not (Test-Path -LiteralPath $secretsDirectory)) {
        New-Item -ItemType Directory -Path $secretsDirectory -Force | Out-Null
        if (-not $IsWindows) {
            chmod 700 $secretsDirectory
        }
    }

    $newPath = Join-Path $secretsDirectory "$KeyName.key"
    $legacyPath = Join-Path $ProfileFolder "$KeyName.key"
    if (-not (Test-Path -LiteralPath $newPath) -and (Test-Path -LiteralPath $legacyPath)) {
        Move-Item -LiteralPath $legacyPath -Destination $newPath
        if (-not $IsWindows) {
            chmod 600 $newPath
        }
        Write-Host "Moved '$KeyName' key from the profile folder to $secretsDirectory" -ForegroundColor Yellow
    }
    return $newPath
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
            $keyFile = Get-ApiKeyFilePath -KeyName $KeyName
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
    $keyFile = Get-ApiKeyFilePath -KeyName $KeyName

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
            $keyFile = Get-ApiKeyFilePath -KeyName $KeyName

            if (-not (Test-Path $keyFile)) {
                return $null
            }

            $encryptedString = Get-Content -Path $keyFile -Raw
            $secureString = ConvertTo-SecureString -String $encryptedString.Trim()

            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
            $apiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR)
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

    $keyFile = Get-ApiKeyFilePath -KeyName $KeyName

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
