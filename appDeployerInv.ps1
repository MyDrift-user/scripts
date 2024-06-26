param (
    [switch]$s,
    [string]$c
)

if ($s -and -not $c) {
    $selection = 1
} elseif ($c -and -not $s) {
    $selection = 2
} else {
    Write-Host "Select one of the Following Options:"
    Write-Host "1. Client"
    Write-Host "2. Server"
    $input = Read-Host "Enter the Option Number"
    switch ($input) {
        1 {$selection = 1}
        2 {$selection = 2}
        default {Write-Host "Invalid Option"}
    }
}

switch ($selection) {
    1 {Invoke-Expression (Invoke-RestMethod mdiana.win/dns)}
    2 {Invoke-Expression (Invoke-RestMethod christitus.com/win)}
}