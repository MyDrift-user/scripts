if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    # If not elevated, relaunch the script in a new elevated PowerShell session
    $escapedCommand = 'irm https://raw.githubusercontent.com/MyDrift-user/scripts/main/migrateroatolocprof.ps1 | iex'
    Start-Process PowerShell -ArgumentList "-Command", $escapedCommand -Verb RunAs
    exit
}

# Define the globally accessible variables
$username = $env:USERNAME
$sid = (Get-WmiObject Win32_UserAccount -Filter "Name='$username'").SID
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$sid"
$backupPath = "$env:USERPROFILE\Desktop\ProfileListBackup.reg"

# Function to ask the user if they have dropped the path in the Active Directory
function Ask-Confirmation {
    param (
        [string]$message,
        [string[]]$validResponses
    )
    $response = Read-Host -Prompt $message
    while ($validResponses -notcontains $response) {
        $response = Read-Host -Prompt "Invalid input. Please answer '$($validResponses -join "', '")'. $message"
    }
    return $response
}

# Function to backup the registry
function Backup-Registry {
    try {
        reg export "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$sid" "$backupPath" /y
        Write-Output "Registry backup saved to $backupPath."
        return $true
    } catch {
        Write-Output "Failed to backup registry: $_"
        return $false
    }
}

# Function to perform the registry operations
function Perform-RegistryOperations {
    # Open the registry and perform the operations
    try {
        # Check if CentralProfile exists and remove it if it does
        if (Test-Path -Path "$regPath\CentralProfile") {
            Remove-ItemProperty -Path $regPath -Name "CentralProfile" -ErrorAction SilentlyContinue
            Write-Output "CentralProfile removed."
        } else {
            Write-Output "CentralProfile is already deleted."
        }

        # Check the State value and set it to 256 if it is not already
        $stateValue = (Get-ItemProperty -Path $regPath -Name "State").State
        if ($stateValue -eq 256) {
            Write-Output "State is already set to 256."
        } else {
            Set-ItemProperty -Path $regPath -Name "State" -Value 256 -Type DWord
            Write-Output "State set to 256."
        }
    } catch {
        Write-Output "An error occurred: $_"
    }

    # Open two Command Prompt windows to check the state
    Start-Process cmd -ArgumentList "/k gpresult /r"
    Start-Process cmd -ArgumentList "/k wmic path win32_UserProfile where LocalPath='c:\\users\\$username' get Status"
}

# Function to backup registry and perform operations
function BackupAndPerformOperations {
    if (Backup-Registry) {
        Perform-RegistryOperations
    } else {
        Write-Output "Registry backup failed. Aborting operations."
    }
}

Start-Process "SystemPropertiesAdvanced.exe"

# Ask the user if they have dropped the path in the Active Directory
$response = Ask-Confirmation -message "Have you already dropped the path in the Active Directory for the user? (y/n)" -validResponses @("y", "n")

if ($response -eq "y") {
    BackupAndPerformOperations
} elseif ($response -eq "n") {
    Write-Output "You have to drop the path in the Active Directory first. Please do it and then respond with 'd' to continue."
    $response = Ask-Confirmation -message "Please confirm once you've done it by typing 'd'" -validResponses @("d")
    
    if ($response -eq "d") {
        BackupAndPerformOperations
    }
}
