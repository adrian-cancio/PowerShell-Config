<#
.SYNOPSIS
Suggests a commit message using Gemini AI based on staged changes and commit history.

.DESCRIPTION
This function analyzes your git repository's staged changes, branch name, and commit history
to generate an appropriate commit message using Google Gemini AI. It checks if a git repository
exists and if there are staged changes before proceeding.

The generated message matches the formatting, language, and style of previous commits.

In interactive mode, you can refine the message by providing feedback to the AI, which will
regenerate the message while maintaining context. Before committing, the function displays
the list of staged files to ensure you are aware of what will be committed.

.PARAMETER CommitCount
Number of previous commits to analyze for style and context. Defaults to 100.

.PARAMETER Model
The Gemini model to use for generating the commit message. Defaults to the official 'gemini-flash-latest' alias.

.PARAMETER Force
If specified, automatically commits with the suggested message without prompting for confirmation.

.PARAMETER AdditionalInstructions
Additional instructions to guide the commit message generation (text string).

.PARAMETER InstructionsFile
Path to a file containing additional instructions for commit message generation.

.PARAMETER ResetApiKey
Forces the function to ask for a new API key, replacing the stored one.

.PARAMETER Verbose
Shows detailed information about what the function is doing at each step. Use -Verbose to enable.

.PARAMETER ReturnOnly
Returns only the commit message string without any user interaction or output. Useful for
integration with other functions or AI agents.

.EXAMPLE
Invoke-SuggestCommitMessage
# Generates a commit message, allows refinement, and prompts for action

.EXAMPLE
Invoke-SuggestCommitMessage -CommitCount 50 -Model "gemini-flash-latest"
# Uses the last 50 commits and specified model

.EXAMPLE
Invoke-SuggestCommitMessage -Force
# Automatically commits with the suggested message

.EXAMPLE
Invoke-SuggestCommitMessage -AdditionalInstructions "Use conventional commits format"
# Adds specific instructions for message generation

.EXAMPLE
Invoke-SuggestCommitMessage -Verbose
# Shows detailed progress information

.EXAMPLE
$msg = Invoke-SuggestCommitMessage -ReturnOnly
# Returns just the message string for use in scripts

.EXAMPLE
sgcm
# Uses the alias to suggest a commit message interactively
#>
function Invoke-SuggestCommitMessage {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [int]$CommitCount = 100,

        [string]$Model = (Get-DefaultGeminiFlashModel),

        [switch]$Force,

        [string]$AdditionalInstructions = "",

        [string]$InstructionsFile = "",

        [switch]$ResetApiKey,

        [switch]$ReturnOnly
    )

    # --- Check if we're in a git repository ---
    Write-Verbose "Checking if current directory is a git repository..."
    try {
        $gitCheck = git rev-parse --is-inside-work-tree 2>&1
        if ($LASTEXITCODE -ne 0) {
            if (-not $ReturnOnly) {
                Write-Host "Error: Not in a git repository." -ForegroundColor Red
            }
            return
        }
        Write-Verbose "✓ Git repository detected"
    }
    catch {
        if (-not $ReturnOnly) {
            Write-Host "Error: Git is not available or not in a git repository." -ForegroundColor Red
        }
        return
    }

    # --- Check for staged changes ---
    Write-Verbose "Checking for staged changes..."
    $stagedFiles = git diff --cached --name-only
    if ([string]::IsNullOrWhiteSpace($stagedFiles)) {
        if (-not $ReturnOnly) {
            Write-Host "Error: No staged changes found. Use 'git add' to stage files first." -ForegroundColor Yellow
        }
        return
    }

    $stagedFilesArray = $stagedFiles -split "`n" | Where-Object { $_ }
    Write-Verbose "✓ Found $($stagedFilesArray.Count) staged file(s)"

    if ($VerbosePreference -eq 'Continue') {
        Write-Verbose "Staged files:"
        foreach ($file in $stagedFilesArray) {
            Write-Verbose "  - $file"
        }
    }

    if (-not $ReturnOnly) {
        Write-Host "Analyzing staged changes and commit history..." -ForegroundColor Cyan
    }

    # --- Get branch name ---
    Write-Verbose "Getting current branch name..."
    $branchName = git rev-parse --abbrev-ref HEAD 2>&1
    if ($LASTEXITCODE -ne 0) {
        $branchName = "unknown"
    }
    Write-Verbose "✓ Branch: $branchName"

    # --- Get commit history ---
    Write-Verbose "Fetching last $CommitCount commits for context..."
    $commitHistory = git --no-pager log --oneline -n $CommitCount 2>&1
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($commitHistory)) {
        $commitHistory = "No previous commits available (new repository)"
        Write-Verbose "! No previous commits found (new repository)"
    }
    else {
        $commitCount = ($commitHistory -split "`n").Count
        Write-Verbose "✓ Retrieved $commitCount commit(s) for analysis"
    }

    # --- Get staged diff ---
    Write-Verbose "Getting staged diff..."
    $stagedDiff = git diff --cached
    if ([string]::IsNullOrWhiteSpace($stagedDiff)) {
        Write-Host "Error: Unable to get staged diff." -ForegroundColor Red
        return
    }
    Write-Verbose "✓ Staged diff retrieved successfully"

    # --- Load additional instructions from file if provided ---
    Write-Verbose "Processing additional instructions..."
    $additionalInstructionsText = $AdditionalInstructions
    if (-not [string]::IsNullOrWhiteSpace($InstructionsFile)) {
        Write-Verbose "Loading instructions from file: $InstructionsFile"
        if (Test-Path $InstructionsFile) {
            $fileContent = Get-Content -Path $InstructionsFile -Raw
            $additionalInstructionsText = if ([string]::IsNullOrWhiteSpace($additionalInstructionsText)) {
                $fileContent
            } else {
                "$additionalInstructionsText`n`n$fileContent"
            }
            Write-Verbose "✓ Instructions loaded from file"
        }
        else {
            Write-Warning "Instructions file not found: $InstructionsFile"
        }
    }

    # --- Get or Set API Key ---
    Write-Verbose "Retrieving API key..."
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
        # Use PtrToStringBSTR for cross-platform compatibility (.NET Core/Linux)
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($inputApiKey)
        $apiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

        if ([string]::IsNullOrEmpty($apiKey)) {
            Write-Error "API key cannot be empty."
            return
        }

        # Store the API key securely
        Set-SecureApiKey -ApiKey $apiKey -KeyName "GeminiAPI"
        Write-Verbose "✓ API key stored securely"
    }
    else {
        Write-Verbose "✓ API key retrieved successfully"
    }

    # --- Prepare the prompt for Gemini ---
    Write-Verbose "Preparing prompt for Gemini AI..."
    $stagedFileCount = ($stagedFiles -split '\n' | Where-Object { $_ }).Count
    $promptText = @"
You are a git commit message expert. Your task is to analyze the provided information and generate a concise, meaningful commit message.

CONTEXT:
- Branch: $branchName
- Staged files: $stagedFileCount file(s)

PREVIOUS COMMITS (last $CommitCount):
$commitHistory

STAGED CHANGES (diff):
$stagedDiff

INSTRUCTIONS:
1. Analyze the staged changes to understand what was modified
2. Review the previous commits to match their style, format, language, and length
3. Generate a commit message that:
   - Accurately describes the changes
   - Matches the language used in previous commits (English, Spanish, etc.)
   - Follows the same formatting style as previous commits
   - Is concise but descriptive
   - Uses appropriate prefixes if the project uses them (feat:, fix:, docs:, etc.)

$(if (-not [string]::IsNullOrWhiteSpace($additionalInstructionsText)) { "ADDITIONAL INSTRUCTIONS:`n$additionalInstructionsText`n" } else { "" })
Please provide ONLY the commit message, without any explanations or additional text.
"@
    Write-Verbose "✓ Prompt prepared successfully"

    # --- API Setup ---
    Write-Verbose "Setting up Gemini API connection..."
    $uri = "https://generativelanguage.googleapis.com/v1beta/models/$($Model):generateContent"
    Write-Verbose "Using model: $Model"

    $headers = @{
        "Content-Type"   = "application/json"
        "X-goog-api-key" = $apiKey
    }

    # --- API Call ---
    $chatHistory = @()
    $resolvedModelVersion = $null

    # Function to call Gemini API (reusable for refinements)
    function Invoke-GeminiForCommit {
        param(
            [string]$PromptText,
            [array]$History = @()
        )

        $bodyContents = @()

        # Add history if exists
        if ($History.Count -gt 0) {
            $bodyContents += $History
        }

        # Add current user message
        $bodyContents += @{
            role  = "user"
            parts = @(@{ text = $PromptText })
        }

        $requestBody = @{
            contents = $bodyContents
        } | ConvertTo-Json -Depth 10

        Write-Verbose "Sending request to Gemini API..."

        $apiResponse = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $requestBody -ContentType "application/json"
        if ([string]::IsNullOrWhiteSpace($resolvedModelVersion) -and -not [string]::IsNullOrWhiteSpace($apiResponse.modelVersion)) {
            Set-Variable -Name resolvedModelVersion -Value $apiResponse.modelVersion -Scope 1
        }

        Write-Verbose "✓ Response received from Gemini API"

        if ($null -eq $apiResponse.candidates) {
            if ($ReturnOnly) {
                return $null
            }
            Write-Error "The API did not return a valid response. The content may have been blocked."
            return $null
        }

        $message = $apiResponse.candidates[0].content.parts[0].text.Trim()

        # Remove any markdown code block markers if present
        $message = $message -replace '^```.*\n', '' -replace '\n```$', ''
        $message = $message.Trim()

        return $message
    }

    # Initial API call
    try {
        $suggestedMessage = Invoke-GeminiForCommit -PromptText $promptText -History $chatHistory

        if (-not $ReturnOnly) {
            $effectiveModel = if (-not [string]::IsNullOrWhiteSpace($resolvedModelVersion)) {
                $resolvedModelVersion
            }
            else {
                $Model
            }

            $statusMessage = "Generating commit message with model '$effectiveModel'..."
            if ($effectiveModel -ne $Model) {
                $statusMessage += " [alias: '$Model']"
            }

            Write-Host $statusMessage -ForegroundColor Cyan
        }

        if ($null -eq $suggestedMessage) {
            return
        }

        # Add to chat history
        $chatHistory += @{
            role  = "user"
            parts = @(@{ text = $promptText })
        }
        $chatHistory += @{
            role  = "model"
            parts = @(@{ text = $suggestedMessage })
        }

    }
    catch {
        if ($ReturnOnly) {
            return $null
        }
        Write-Error "An error occurred while contacting the Gemini API: $($_.Exception.Message)"
        if ($_.Exception.Response) {
            try {
                # .NET Core / PowerShell 7+ uses HttpResponseMessage
                if ($_.Exception.Response -is [System.Net.Http.HttpResponseMessage]) {
                    $errorBody = $_.Exception.Response.Content.ReadAsStringAsync().Result
                }
                else {
                    # .NET Framework fallback
                    $errorBody = $_.Exception.Response.GetResponseStream() | ForEach-Object { (New-Object System.IO.StreamReader($_)).ReadToEnd() }
                }
                Write-Host "Error body: $errorBody" -ForegroundColor Red
            }
            catch {
                Write-Host "Could not read error details from response." -ForegroundColor DarkYellow
            }
        }
        return
    }

    # --- ReturnOnly mode: just return the message ---
    if ($ReturnOnly.IsPresent) {
        return $suggestedMessage
    }

    # --- Display the suggested message ---
    Write-Host "`n" -NoNewline
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Suggested Commit Message:" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host $suggestedMessage -ForegroundColor White
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    # --- Handle user action ---
    if ($Force.IsPresent) {
        # Show staged files before auto-commit
        Write-Host "Staged files to be committed:" -ForegroundColor Yellow
        foreach ($file in $stagedFilesArray) {
            Write-Host "  • $file" -ForegroundColor Gray
        }
        Write-Host ""

        # Auto-commit without prompting
        Write-Verbose "Force mode enabled - committing automatically..."
        try {
            git commit -m $suggestedMessage
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ Changes committed successfully!" -ForegroundColor Green
            }
            else {
                Write-Error "Failed to commit changes."
            }
        }
        catch {
            Write-Error "Error during commit: $($_.Exception.Message)"
        }
    }
    else {
        # Show staged files once at the beginning
        Write-Host "Staged files to be committed:" -ForegroundColor Yellow
        foreach ($file in $stagedFilesArray) {
            Write-Host "  • $file" -ForegroundColor Gray
        }
        Write-Host ""

        # Interactive loop with refinement capability
        $continueLoop = $true
        while ($continueLoop) {
            # Display current commit message right before prompting
            Write-Host "Current commit message:" -ForegroundColor Cyan
            Write-Host "  $suggestedMessage" -ForegroundColor White
            Write-Host ""

            # Prompt for action
            Write-Host "What would you like to do?" -ForegroundColor Yellow
            Write-Host "  Type 'commit' to commit with this message" -ForegroundColor White
            Write-Host "  Press Enter to copy to clipboard" -ForegroundColor White
            Write-Host "  Type anything else to refine the message with AI" -ForegroundColor White
            Write-Host ""

            $action = Read-Host "Your choice"

            if ($action -ceq 'commit') {
                # Commit with current message
                Write-Verbose "User chose to commit - executing git commit..."
                try {
                    git commit -m $suggestedMessage
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "✓ Changes committed successfully!" -ForegroundColor Green
                        $continueLoop = $false
                    }
                    else {
                        Write-Error "Failed to commit changes."
                        $continueLoop = $false
                    }
                }
                catch {
                    Write-Error "Error during commit: $($_.Exception.Message)"
                    $continueLoop = $false
                }
            }
            elseif ([string]::IsNullOrWhiteSpace($action)) {
                # Copy to clipboard
                Write-Verbose "User chose to copy to clipboard..."
                try {
                    Set-Clipboard -Value $suggestedMessage
                    Write-Host "✓ Commit message copied to clipboard!" -ForegroundColor Green
                    $continueLoop = $false
                }
                catch {
                    Write-Warning "Failed to copy to clipboard. Here's the message to copy manually:"
                    Write-Host $suggestedMessage -ForegroundColor White
                    $continueLoop = $false
                }
            }
            else {
                # Refine the message with AI
                Write-Host "`nRefining commit message with your feedback..." -ForegroundColor Cyan
                Write-Verbose "User provided refinement instructions: $action"

                # Build refinement prompt
                $refinementPrompt = @"
The user wants to refine the commit message. Their feedback is:
"$action"

Please generate an improved commit message based on this feedback while still:
- Accurately describing the staged changes
- Matching the language and style of previous commits
- Being concise but descriptive

Provide ONLY the refined commit message, without any explanations.
"@

                try {
                    # Call API with conversation history
                    $refinedMessage = Invoke-GeminiForCommit -PromptText $refinementPrompt -History $chatHistory

                    if ($null -ne $refinedMessage) {
                        # Update message and history
                        $suggestedMessage = $refinedMessage

                        $chatHistory += @{
                            role  = "user"
                            parts = @(@{ text = $refinementPrompt })
                        }
                        $chatHistory += @{
                            role  = "model"
                            parts = @(@{ text = $refinedMessage })
                        }

                        Write-Host "✓ Message refined successfully!" -ForegroundColor Green
                        Write-Host ""
                    }
                    else {
                        Write-Warning "Failed to refine message. Keeping current message."
                    }
                }
                catch {
                    Write-Warning "Error during refinement: $($_.Exception.Message)"
                    Write-Host "Keeping current message." -ForegroundColor Yellow
                }
            }
        }
    }
}
