<#
.SYNOPSIS
    A script to display processes, services, or network adapters based on user input.

.DESCRIPTION
    This script displays a menu for the user to choose to display processes, services, 
    or network adapters. The user can choose to repeat the selection or exit the script.

.NOTES
    Author: Mattia Diana
    Date: 2024-06-21
#>

# Main loop
do {
    Clear-Host
    Write-Host "Bitte waehlen Sie eine Option:"
    Write-Host "1) Prozesse anzeigen"
    Write-Host "2) Services anzeigen"
    Write-Host "3) Netzadapter anzeigen"
    Write-Host "4) Abbruch"
    
    $userInputValid = $false
    while (-not $userInputValid) {
        try {
            $userInput = Read-Host "$ENV:USERNAME"
            switch ($userInput) {
                '1' {
                    Get-Process | Format-Table -AutoSize
                    $userInputValid = $true
                }
                '2' {
                    Write-Host "Wollen Sie die laufenden oder die gestoppten Services anzeigen?"
                    Write-Host "1) Laufende Services"
                    Write-Host "2) Gestoppte Services"
                    $serviceInputValid = $false
                    while (-not $serviceInputValid) {
                        $serviceInput = Read-Host "$ENV:USERNAME"
                        switch ($serviceInput) {
                            '1' {
                                Get-Service | Where-Object {$_.Status -eq 'Running'} | Format-Table -AutoSize
                                $serviceInputValid = $true
                            }
                            '2' {
                                Get-Service | Where-Object {$_.Status -eq 'Stopped'} | Format-Table -AutoSize
                                $serviceInputValid = $true
                            }
                            default {
                                Write-Host "Ungueltige Eingabe. Bitte geben Sie 1 oder 2 ein."
                            }
                        }
                    }
                    $userInputValid = $true
                }
                '3' {
                    Get-NetAdapter | Format-Table -AutoSize
                    $userInputValid = $true
                }
                '4' {
                    Write-Host "Abbruch"
                    $userInputValid = $true
                    break
                }
                default {
                    Write-Host "Ungueltige Eingabe. Bitte geben Sie eine Zahl zwischen 1 und 4 ein."
                }
            }
        } catch {
            Write-Host "Fehler bei der Eingabe. Bitte versuchen Sie es erneut."
        }
    }

    if ($userInput -ne '4') {
        $continue = Read-Host "Wollen Sie noch einmal waehlen oder abbrechen? (a > Abbruch / w > Weiter)"
    } else {
        $continue = 'a'
    }

} while ($continue -match '^[wW]$')

Write-Host "Programm beendet"




$SidneyHasBitches

if ($SidneyHasBitches -eq $true) {
    Write-Host "Sidney hat Bitches"
} else {
    Write-Host "Sidney hat keine Bitches"
}