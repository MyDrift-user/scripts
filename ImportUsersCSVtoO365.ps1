if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Install-Module -Name Microsoft.Graph -Scope CurrentUser
}

Connect-MgGraph -Scopes "User.ReadWrite.All"

$csvPath = "C:\usercreation.csv"

$userData = Import-Csv -Path $csvPath -Delimiter ',' -Encoding Default

foreach ($user in $userData) {
    New-MgUser -AccountEnabled:$true `
               -DisplayName $user.'Display name' `
               -MailNickname ($user.Username.Split('@')[0]) `
               -UserPrincipalName $user.Username `
               -UserType 'Member' `
               -PasswordProfile @{forceChangePasswordNextSignIn = $false; password = "Passwort123"} `
               -GivenName $user.'First name' `
               -Surname $user.'Last name' `
               -JobTitle $user.'Job title' `
               -Department $user.Department `
               -OfficeLocation $user.'Office number' `
               -BusinessPhones @($user.'Office phone') `
               -MobilePhone $user.'Mobile phone' `
               -FaxNumber $user.Fax `
               -OtherMails @($user.'Alternate email address') `
               -StreetAddress $user.Address `
               -City $user.City `
               -State $user.'State or province' `
               -PostalCode $user.'ZIP or postal code' `
               -Country $user.'Country or region'
}

Disconnect-MsGraph