function Get-DefaultGeminiFlashModel {
    [CmdletBinding()]
    param()

    return "gemini-flash-latest"
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
The Gemini model to use. Defaults to the official 'gemini-flash-latest' alias.

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

        [string]$Model = (Get-DefaultGeminiFlashModel),

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
    }

    $uri = "https://generativelanguage.googleapis.com/v1beta/models/$($Model):generateContent"

    $headers = @{
        "Content-Type"   = "application/json"
        "X-goog-api-key" = $apiKey
    }

    $chatHistory = @()
    $sessionHeaderShown = $false

    # --- SYSTEM INSTRUCTION ---
    # This key instruction tells the model how to behave and explains PowerShell formatting.
    $systemInstructionText = @"
You are a helpful assistant for a user in a PowerShell command-line terminal. You provide concise, scannable responses optimized for terminal reading.

CRITICAL: THINK ABOUT TERMINAL CONTEXT BEFORE RESPONDING
Before writing your response, remember:
- You are writing for a TERMINAL WINDOW, not a web browser or document
- Terminal users prefer CONCISE, SCANNABLE responses
- Long paragraphs are hard to read in a terminal
- Use SHORT LINES (60-80 characters when possible)
- Break complex information into BULLET POINTS or SHORT PARAGRAPHS
- Use FORMATTING to make text easy to scan quickly
- Terminal users often want QUICK ANSWERS, not essays
- Users may be in the middle of work - respect their time

RESPONSE FORMATTING GUIDELINES:
1. Keep responses CONCISE but helpful
2. Use bullet points (•) or dashes (-) for lists
3. Break long text into SHORT paragraphs (2-3 lines max)
4. Use formatting colors to make information SCANNABLE
5. Put the most important information FIRST
6. Use blank lines to separate different topics
7. Prefer vertical lists over horizontal comma-separated lists
8. Use HEADINGS with colors for different sections

AVAILABLE FORMATTING COMMANDS:
1. Text Colors (Foreground): [FG:ColorName]text[/FG]
    - Colors: Black, DarkBlue, DarkGreen, DarkCyan, DarkRed, DarkMagenta, DarkYellow, Gray, DarkGray, Blue, Green, Cyan, Red, Magenta, Yellow, White
    - Example: [FG:Red]This text is red[/FG]

2. Background Colors: [BG:ColorName]text[/BG]
    - Same color names as foreground
    - Example: [BG:Yellow]This has yellow background[/BG]

3. You can combine formats: [FG:White][BG:DarkBlue]White text on dark blue background[/BG][/FG]

TERMINAL-OPTIMIZED FORMATTING STRATEGY:
- [FG:Green] for SUCCESS, confirmations, positive results
- [FG:Yellow] for WARNINGS, important notes, cautions
- [FG:Red] for ERRORS, critical info, urgent warnings
- [FG:Cyan] for COMMANDS, code snippets, technical terms
- [FG:Magenta] for PARAMETERS, variables, PowerShell-specific terms
- [FG:Blue] for FILE PATHS, URLs, references
- [FG:White] for HEADINGS or emphasis
- Use [BG:DarkRed][FG:White] sparingly for CRITICAL alerts

TERMINAL-FRIENDLY RESPONSE EXAMPLES:

GOOD (Terminal-optimized):
[FG:White]Process Information:[/FG]
• [FG:Cyan]Name:[/FG] notepad.exe
• [FG:Cyan]PID:[/FG] 1234
• [FG:Cyan]CPU:[/FG] 0.5%

[FG:Yellow]Tip:[/FG] Use [FG:Cyan]Get-Process -Name notepad[/FG] to filter

BAD (Too verbose for terminal):
"The Get-Process cmdlet is a very powerful tool that allows you to retrieve information about running processes on your system. When you use this cmdlet, it will return a comprehensive list of all currently running processes, including detailed information such as process names, process IDs, CPU usage statistics, memory consumption, and various other performance metrics..."

SPECIFIC TERMINAL GUIDELINES:
- Avoid walls of text - break into digestible chunks
- Use indentation with spaces for sub-items
- Put commands in [FG:Cyan] color for easy identification
- Use consistent spacing and alignment
- When listing steps, number them clearly
- For error messages, use [FG:Red] and be specific about solutions
- When suggesting multiple options, use bullet points

LANGUAGE ADAPTATION:
- Always respond in the SAME LANGUAGE as the user
- If user writes in Spanish, respond in Spanish
- If user writes in English, respond in English
- Maintain language consistency throughout the conversation

RESPONSE LENGTH GUIDELINES:
- For simple questions: 1-3 lines maximum
- For explanations: Use bullet points, max 5-7 points
- For complex topics: Break into sections with clear headings
- For lists: Prefer vertical format over horizontal
- Always prioritize CLARITY over completeness in terminal context

PRACTICAL TERMINAL TIPS:
- Structure responses like a well-formatted man page
- Use white space effectively - don't cram information
- Make the first line answer the question directly
- Put detailed explanations after the main answer
- Use consistent formatting patterns throughout conversation
- Consider that users might need to copy/paste commands

Remember: Terminal users value SPEED and CLARITY over detailed explanations. Make every line count and every color meaningful!
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

            if (-not $sessionHeaderShown) {
                $effectiveModel = if (-not [string]::IsNullOrWhiteSpace($response.modelVersion)) {
                    $response.modelVersion
                }
                else {
                    $Model
                }

                $startMessage = "Starting chat with model '$effectiveModel' (PowerShell Formatting enabled). Type 'exit' or 'quit' to end."
                if ($effectiveModel -ne $Model) {
                    $startMessage += " [alias: '$Model']"
                }

                Write-Host $startMessage -ForegroundColor Cyan
                Write-Host ""
                $sessionHeaderShown = $true
            }

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
