# 1. Prüfen, ob der Pfad C:\Modul122 vorhanden ist
$path = "C:\Modul122"
if (-Not (Test-Path $path)) {
    # 2. Erstellen des Ordners, wenn er nicht vorhanden ist
    New-Item -ItemType Directory -Path $path
}

# Pfad zur Datei
$filePath = "$path\ReadWrite.txt"

if (Test-Path $filePath) {
    # 3. Prüfen, ob die Datei ReadWrite.txt vorhanden ist
    if (Test-Path $filePath) {
        # 4. Inhalt der Datei auf den Bildschirm ausgeben
        Get-Content $filePath
    }
}

# 6. Aktuelles Datum/Zeit und alle Netzwerkadapter sortiert nach Name in die Datei anhängen
$datetime = Get-Date
$networkAdapters = Get-NetAdapter | Sort-Object Name

$networkInfo = $networkAdapters | ForEach-Object {
    "$($_.Name) - Status: $($_.Status)"
}

Add-Content -Path $filePath -Value $datetime
Add-Content -Path $filePath -Value $networkInfo

# 7. Erste und letzte Zeile in eine neue Datei schreiben
$content = Get-Content $filePath
if ($content.Count -gt 0) {
    $firstLine = $content[0]
    $lastLine = $content[-1]
    $newFilePath = "$path\ReadWrite.part.txt"
    Set-Content -Path $newFilePath -Value $firstLine
    Add-Content -Path $newFilePath -Value $lastLine
}

# 9. Datei in zwei anderen Zeichenformaten speichern
$fileASCII = "$path\ReadWriteASCII.txt"
$fileUnicode = "$path\ReadWriteUnicode.txt"

Get-Content $filePath | Out-File -FilePath $fileASCII -Encoding Ascii
Get-Content $filePath | Out-File -FilePath $fileUnicode -Encoding Unicode
