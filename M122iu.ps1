$wingetInstalled = Get-Command winget -ErrorAction SilentlyContinue
$WingetGitApiUrl = 'https://api.github.com/repos/microsoft/winget-cli/releases/latest'

if (-not $wingetInstalled -or (winget --version).Trim() -ne ((Invoke-RestMethod -Uri $WingetGitApiUrl).tag_name).Trim()) {
    $latestRelease = Invoke-RestMethod -Uri $WingetGitApiUrl
    $installer = $latestRelease.assets | Where-Object { $_.name -match 'msixbundle$' } | Select-Object -First 1
    $tempPath = "$env:TEMP\$($installer.name)"
    Invoke-WebRequest -Uri $installer.browser_download_url -OutFile $tempPath
    Add-AppxPackage -Path $tempPath
    Write-Host "winget has been installed/updated successfully."
}

# Define the path for the directory and the config.ini file
$directoryPath = "$env:USERPROFILE\Documents\M122"
$configFilePath = "$directoryPath\config.ini"

# Fetch the content of the config.ini file
$configContent = Get-Content -Path $configFilePath -ErrorAction Stop

# Fetch the list of packages from the provided URL or path
if ($configContent -match '^https?://') {
    Write-Host 'Fetching package list from URL: ' $configContent
    $packageList = (Invoke-WebRequest -Uri $configContent).Content
} else {
    Write-Host 'Fetching package list from file: ' $configContent
    $packageList = Get-Content -Path $configContent -ErrorAction Stop
}

$wingetPackages = $packageList -split "`n"

# Get the list of installed packages and updatable packages
$installed = Get-WinGetPackage -Source winget | Select-Object -ExpandProperty Id
$updatable = Get-WinGetPackage -Source winget | Where-Object IsUpdateAvailable | Select-Object -ExpandProperty Id

# Loop through the packages you want to manage
foreach ($package in $wingetPackages) {
    if ($updatable -contains $package) {
        winget upgrade --id $package
    } elseif (-not ($installed -contains $package)) {
        winget install --id $package
    }
}
