# Anzahl der Tage, nach denen Profile als alt betrachtet werden
$Tage = 30
 
# Aktuelles Datum
$AktuellesDatum = Get-Date
 
# Funktion zum Bereinigen alter Benutzerprofile
function CleanBenutzerprofile {
    # Benutzerprofile Pfad
    $BenutzerProfilePfad = "C:\Users"
 
    # Alle Verzeichnisse im Benutzerprofile-Pfad
    $Profiles = Get-ChildItem -Path $BenutzerProfilePfad | Where-Object { $_.PSIsContainer }
 
    foreach ($Profil in $Profiles) {
        # Ausschluss von Systemprofilen
        if ($Profil.Name -in "Administrator", "Default", "Default User", $ENV:USERNAME) {
            continue
        }
 
        # Letzter Zugriff auf das Profil
        $LastLogon = (Get-WmiObject -Class Win32_UserProfile | Where-Object { $_.LocalPath -eq $Profil.FullName }).LastLogon
 
        # Differenz in Tagen zwischen dem aktuellen Datum und dem letzten Zugriff
        $Differenz = ($AktuellesDatum - $LastLogon).Days
 
        if ($Differenz -ge $Tage) {
            $Message = "Möchten Sie das Benutzerprofil $($Profil.FullName) löschen? Letzter Zugriff vor $Differenz Tagen"
            $Title = "Profil löschen"
            $Choice = New-Object -TypeName System.Management.Automation.Host.ChoiceDescription -ArgumentList "&Ja", "&Nein"
            $Options = [System.Management.Automation.Host.ChoiceDescription[]]($Choice)
            $Decision = $Host.UI.PromptForChoice($Title, $Message, $Options, 1)
 
            if ($Decision -eq 0) {
                Write-Output "Lösche Benutzerprofil: $($Profil.FullName)"
                # Lösche das Profil
                try {
                    Remove-Item -Path $Profil.FullName -Recurse -Force -ErrorAction Stop
                    Write-Output "Benutzerprofil erfolgreich gelöscht: $($Profil.FullName)"
                } catch {
                    Write-Output "Fehler beim Löschen des Profils: $($Profil.FullName) - $_"
                }
            } else {
                Write-Output "Benutzerprofil wird nicht gelöscht: $($Profil.FullName)"
            }
        }
    }
}
 
# Ausführung der Bereinigungsfunktion
CleanBenutzerprofile