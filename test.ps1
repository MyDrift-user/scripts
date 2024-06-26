Get-NetAdapter |
    Select-Object Name, MacAddress, Status,
        @{Name="PrimaryDNS"; Expression={(Get-DnsClientServerAddress -InterfaceAlias $_.Name -AddressFamily IPv4).ServerAddresses[0]}},
        @{Name="SecondaryDNS"; Expression={(Get-DnsClientServerAddress -InterfaceAlias $_.Name -AddressFamily IPv4).ServerAddresses[1]}} |
    Format-Table