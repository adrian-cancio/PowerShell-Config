if ($env:USER.length -eq 0){
	$env:USER = $env:USERNAME
}
Enum OS {
	Windows
	Linux
	MacOS
}
$Kernel = if($IsWindows){[OS]::Windows} elseif($IsLinux){[OS]::Linux} elseif($IsMacOS){[OS]::MacOS}
[String]$SPWD
$DirArray = @()

$CODE = Join-Path -Path $HOME -ChildPath "Code"
# If code folder not exists, ask user to create it
$AskCreateCodeFolder = $true
if (!(Test-Path -Path $CODE) -and $AskCreateCodeFolder){
	$CreateCodeFolder = Read-Host "`'$CODE`' folder not exists, create it? (Y/N)"
	if ($CreateCodeFolder -eq "Y"){
		New-Item -Path $CODE -ItemType Directory
	}
}


enum PromptColorSchemes {
	# Normal Schemes
	Default
	Blue
	Green
	Cyan
	Red
	Magenta
	Yellow
	Gray
	# Special Schemes
	Random
	Asturias
	Spain
	Hackerman
}


function Set-PromptColorScheme {
	[CmdletBinding()]
	param (
		[PromptColorSchemes]$ColorScheme = $PromptColorScheme
	)
	# Primary Colors: Blue, Green Cyan, Red, Magenta, Yellow, White, Gray
	$Colors = @{
		"Blue" = @([ConsoleColor]::Blue, [ConsoleColor]::DarkBlue)
		"Green" = @([ConsoleColor]::Green, [ConsoleColor]::DarkGreen)
		"Cyan" = @([ConsoleColor]::Cyan, [ConsoleColor]::DarkCyan)
		"Red" = @([ConsoleColor]::Red, [ConsoleColor]::DarkRed)
		"Magenta" = @([ConsoleColor]::Magenta, [ConsoleColor]::DarkMagenta)
		"Yellow" = @([ConsoleColor]::Yellow, [ConsoleColor]::DarkYellow)
		"White" = @([ConsoleColor]::White, [ConsoleColor]::DarkGray)
		"Gray" = @([ConsoleColor]::Gray, [ConsoleColor]::DarkGray)
	}

	$ColorSchemes = @{
		[PromptColorSchemes]::Default = $Colors["White"]
		[PromptColorSchemes]::Blue = $Colors["Blue"]
		[PromptColorSchemes]::Green = $Colors["Green"]
		[PromptColorSchemes]::Cyan = $Colors["Cyan"]
		[PromptColorSchemes]::Red = $Colors["Red"]
		[PromptColorSchemes]::Magenta = $Colors["Magenta"]
		[PromptColorSchemes]::Yellow = $Colors["Yellow"]
		[PromptColorSchemes]::Gray = $Colors["Gray"]
		[PromptColorSchemes]::Random = @($Colors[$($Colors.Keys | Get-Random)][0], $Colors[$($Colors.Keys | Get-Random)][1])
		[PromptColorSchemes]::Asturias = @($Colors["Blue"][0], $Colors["Yellow"][1])
		[PromptColorSchemes]::Spain = @($Colors["Red"][0], $Colors["Yellow"][1])
		[PromptColorSchemes]::Hackerman = @($Colors["Green"][0], $Colors["Gray"][1])
		
	}
	Write-Debug "ColorScheme: $ColorScheme"
	# Write-Host $ColorScheme
	$Global:PromptColorScheme = $ColorScheme
	$Global:PromptColors = $ColorSchemes[$ColorScheme]
}

[ConsoleColor[]]$PromptColors = @()

$PromptColorScheme = [PromptColorSchemes]::Random
$DefaultPrompt = $false

# Custom Prompt if enabled
function Prompt(){

	if ($DefaultPrompt){
		Write-Host "PS $PWD>" -nonewline
		return " "
	}

	Set-PromptColorScheme -ColorScheme $PromptColorScheme

	Write-Host "||" -nonewline -ForegroundColor $PromptColors[1]
	Write-Host $env:USER -nonewline -ForegroundColor $PromptColors[0]
	Write-Host "@" -nonewline -ForegroundColor $PromptColors[1]
	Write-Host $Kernel -nonewline -ForegroundColor $PromptColors[0]
	Write-Host "|-|" -nonewline -ForegroundColor $PromptColors[1]
	
	$SPWD = if ($PWD.Path.StartsWith($HOME)){
		"~$([IO.Path]::DirectorySeparatorChar)$($PWD.Path.Substring($HOME.Length))"
	}else{$PWD.Path}
	$DirArray = $SPWD.Split([IO.Path]::DirectorySeparatorChar)

	$IsFirstFolder = $true
	foreach ($FolderName in $DirArray){
		if ($FolderName.length -eq 0){
			continue
		}
		if(!$IsFirstFolder -or ($FolderName -ne "~" -and !$IsWindows)){
			Write-Host $([IO.Path]::DirectorySeparatorChar) -nonewline -ForegroundColor $PromptColors[1]
		}
		Write-Host $FolderName -nonewline -ForegroundColor $PromptColors[0]
		$IsFirstFolder = $false
	}
	
	Write-Host "||`n" -nonewline -ForegroundColor $PromptColors[1]
	Write-Host "|>" -nonewline -ForegroundColor $PromptColors[1]
	return " "
}
function Set-PWDClipboard {Set-Clipboard $PWD}

# Alias
Set-Alias -Name vim -Value nvim
Set-Alias -Name vi -Value vim
Set-Alias -Name wrh -Value Write-Host
Set-Alias -Name cpwd -Value Set-PWDClipboard
