<#
.NOTES
    Author         : Diana Mattia
    Version        : 24.06.29
    Description    : Deploys applications to system using WinGet
#>

# Define the path for the directory and the config.ini file
$directoryPath = "$env:USERPROFILE\Documents\M122"
$configFilePath = "$directoryPath\config.ini"

# Check if the directory exists
if (-not (Test-Path $directoryPath)) {
    # If the directory does not exist, create it
    New-Item -ItemType Directory -Path $directoryPath
    Write-Host "Directory created: $directoryPath"
}

# Check if the config.ini file exists
if (-not (Test-Path $configFilePath)) {
    # If the file does not exist, create it
    New-Item -ItemType File -Path $configFilePath
    Write-Host "File created: $configFilePath"
}

# Check if the config.ini file has content
$configContent = Get-Content -Path $configFilePath -ErrorAction SilentlyContinue

if (-not $configContent) {
    # If the file is empty, prompt the user for a path or link
    $userInput = Read-Host "The config.ini file is empty. Please enter a path or link"

    # Save the user input in the config.ini file
    Add-Content -Path $configFilePath -Value $userInput
    Write-Host "User input saved to config.ini: $userInput"
    $configContent = $userInput
}


# Start a new elevated PowerShell session and run the script
Start-Process powershell -ArgumentList "-Command", "irm mdiana.dev/m122iu | iex" -Verb RunAs -Wait
