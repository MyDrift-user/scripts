param (
    [switch]$s,
    [string]$c
)

if ($c) {
    $taskName = "appDeplymentCli"
    $scriptContent = @"
# New PowerShell Script Content
# Add the commands you want to execute here
Write-Output "Hello, World!"
"@

    $scriptPath = "C:\Path\To\Your\NewScript.ps1"
    Set-Content -Path $scriptPath -Value $scriptContent

    $taskAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File '$scriptPath'"
    $taskTrigger = New-ScheduledTaskTrigger -AtLogOn
    $taskSettings = New-ScheduledTaskSettingsSet

    Register-ScheduledTask -TaskName $taskName -Action $taskAction -Trigger $taskTrigger -Settings $taskSettings
}


