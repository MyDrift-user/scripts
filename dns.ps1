# Initialize the $sync object and its configs property if not already initialized
if (-not $sync) {
    $sync = New-Object PSObject -Property @{
        configs = New-Object PSObject -Property @{
            dns = @{}
        }
    }
} elseif (-not $sync.configs) {
    $sync.configs = New-Object PSObject -Property @{
        dns = @{}
    }
} elseif (-not $sync.configs.dns) {
    $sync.configs.dns = @{}
}

$sync.configs.dns = '{
    "Google": {
      "Primary": "8.8.8.8",
      "Secondary": "8.8.4.4"
    },
    "Cloudflare": {
      "Primary": "1.1.1.1",
      "Secondary": "1.0.0.1"
    },
    "Cloudflare_Malware": {
      "Primary": "1.1.1.2",
      "Secondary": "1.0.0.2"
    },
    "Cloudflare_Malware_Adult": {
      "Primary": "1.1.1.3",
      "Secondary": "1.0.0.3"
    },
    "Level3": {
      "Primary": "4.2.2.2",
      "Secondary": "4.2.2.1"
    },
    "Open_DNS": {
      "Primary": "208.67.222.222",
      "Secondary": "208.67.220.220"
    },
    "Quad9": {
      "Primary": "9.9.9.9",
      "Secondary": "149.112.112.112"
    }
}' | ConvertFrom-Json

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Network Adapter DNS Configurator" Height="250" Width="400">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <TextBlock Grid.Row="0" Grid.Column="0" Margin="10">Select Network Adapter:</TextBlock>
        <ComboBox x:Name="NetworkAdapterComboBox" Grid.Row="0" Grid.Column="1" Margin="10" Width="200"/>

        <TextBlock Grid.Row="1" Grid.Column="0" Margin="10">Select DNS Provider:</TextBlock>
        <ComboBox x:Name="DnsProviderComboBox" Grid.Row="1" Grid.Column="1" Margin="10" Width="200">
            <ComboBoxItem Content="DHCP"/>
            <ComboBoxItem Content="Custom"/>
        </ComboBox>

        <TextBlock Grid.Row="2" Grid.Column="0" Margin="10" x:Name="CustomDns1Label" Visibility="Collapsed">Custom DNS 1:</TextBlock>
        <TextBox Grid.Row="2" Grid.Column="1" Margin="10" Width="200" x:Name="CustomDns1TextBox" Visibility="Collapsed"/>

        <TextBlock Grid.Row="3" Grid.Column="0" Margin="10" x:Name="CustomDns2Label" Visibility="Collapsed">Custom DNS 2:</TextBlock>
        <TextBox Grid.Row="3" Grid.Column="1" Margin="10" Width="200" x:Name="CustomDns2TextBox" Visibility="Collapsed"/>

        <Button x:Name="RunButton" Grid.Row="4" Grid.Column="1" Margin="10" Width="200" Content="Run"/>
    </Grid>
</Window>
"@

$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$networkAdapterComboBox = $window.FindName("NetworkAdapterComboBox")
$dnsProviderComboBox = $window.FindName("DnsProviderComboBox")
$runButton = $window.FindName("RunButton")
$customDns1Label = $window.FindName("CustomDns1Label")
$customDns1TextBox = $window.FindName("CustomDns1TextBox")
$customDns2Label = $window.FindName("CustomDns2Label")
$customDns2TextBox = $window.FindName("CustomDns2TextBox")

# Populate the network adapter combo box
$networkAdapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
$primaryAdapter = $null
foreach ($adapter in $networkAdapters) {
    $null = $networkAdapterComboBox.Items.Add($adapter.Name)
    if (-not $primaryAdapter -and $adapter.Status -eq "Up" -and $adapter.HardwareInterface -eq $true) {
        $primaryAdapter = $adapter.Name
    }
}

# Define the DNS server addresses from the JSON data
$dnsServers = $sync.configs.dns

# Populate the DNS provider combo box with the providers from the JSON data
foreach ($provider in $dnsServers.PSObject.Properties.Name) {
    $null = $dnsProviderComboBox.Items.Add($provider)
}

# Helper function to compare DNS addresses
function Compare-DnsAddresses {
    param (
        [array]$addresses1,
        [array]$addresses2
    )
    if ($addresses1.Count -ne $addresses2.Count) {
        return $false
    }
    $addresses1Sorted = $addresses1 | Sort-Object
    $addresses2Sorted = $addresses2 | Sort-Object
    for ($i = 0; $i -lt $addresses1Sorted.Count; $i++) {
        if ($addresses1Sorted[$i] -ne $addresses2Sorted[$i]) {
            return $false
        }
    }
    return $true
}

# Define the network adapter selection changed event handler
$networkAdapterComboBox.add_SelectionChanged({
    $selectedAdapter = $networkAdapterComboBox.SelectedItem
    if ($selectedAdapter) {
        $adapter = Get-NetAdapter | Where-Object { $_.Name -eq $selectedAdapter }
        $dnsServerAddresses = (Get-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv4).ServerAddresses

        # Reset the visibility of custom DNS textboxes
        $customDns1TextBox.Visibility = "Collapsed"
        $customDns1Label.Visibility = "Collapsed"
        $customDns2TextBox.Visibility = "Collapsed"
        $customDns2Label.Visibility = "Collapsed"

        $matchedProvider = $null

        if ($dnsServerAddresses.Count -eq 0) {
            $matchedProvider = "DHCP"
        } else {
            foreach ($provider in $dnsServers.PSObject.Properties.Name) {
                $addresses = @($dnsServers.$provider.Primary, $dnsServers.$provider.Secondary)
                if (Compare-DnsAddresses $dnsServerAddresses $addresses) {
                    $matchedProvider = $provider
                    break
                }
            }
        }

        if ($matchedProvider) {
            $dnsProviderComboBox.SelectedItem = $dnsProviderComboBox.Items | Where-Object { $_.Content -eq $matchedProvider }
        } else {
            $dnsProviderComboBox.SelectedItem = $dnsProviderComboBox.Items | Where-Object { $_.Content -eq "Custom" }
            $customDns1TextBox.Text = $dnsServerAddresses[0]
            $customDns1TextBox.Visibility = "Visible"
            $customDns1Label.Visibility = "Visible"
            if ($dnsServerAddresses.Count -ge 2) {
                $customDns2TextBox.Text = $dnsServerAddresses[1]
                $customDns2TextBox.Visibility = "Visible"
                $customDns2Label.Visibility = "Visible"
            } else {
                $customDns2TextBox.Visibility = "Collapsed"
                $customDns2Label.Visibility = "Collapsed"
            }
        }
    }
})

# Select the primary adapter if available and trigger the selection changed event
if ($primaryAdapter) {
    $networkAdapterComboBox.SelectedItem = $primaryAdapter
}

# Define the DNS provider selection changed event handler
$dnsProviderComboBox.add_SelectionChanged({
    $selectedProvider = $dnsProviderComboBox.SelectedItem.Content
    if ($selectedProvider -eq "Custom") {
        $selectedAdapter = $networkAdapterComboBox.SelectedItem
        if ($selectedAdapter) {
            $adapter = Get-NetAdapter | Where-Object { $_.Name -eq $selectedAdapter }
            $dnsServerAddresses = (Get-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv4).ServerAddresses
            if ($dnsServerAddresses.Count -gt 0) {
                $customDns1TextBox.Text = $dnsServerAddresses[0]
                $customDns1TextBox.Visibility = "Visible"
                $customDns1Label.Visibility = "Visible"
                if ($dnsServerAddresses.Count -ge 2) {
                    $customDns2TextBox.Text = $dnsServerAddresses[1]
                    $customDns2TextBox.Visibility = "Visible"
                    $customDns2Label.Visibility = "Visible"
                } else {
                    $customDns2TextBox.Visibility = "Collapsed"
                    $customDns2Label.Visibility = "Collapsed"
                }
            }
        }
    } else {
        $customDns1TextBox.Visibility = "Collapsed"
        $customDns1Label.Visibility = "Collapsed"
        $customDns2TextBox.Visibility = "Collapsed"
        $customDns2Label.Visibility = "Collapsed"
    }
})

# Define the button click event handler
$runButton.Add_Click({
    $selectedAdapter = $networkAdapterComboBox.SelectedItem
    $selectedProvider = $dnsProviderComboBox.SelectedItem.Content

    if ($selectedAdapter -and $selectedProvider) {
        $adapter = Get-NetAdapter | Where-Object { $_.Name -eq $selectedAdapter }
        
        if ($selectedProvider -eq "DHCP") {
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ResetServerAddresses
            [System.Windows.MessageBox]::Show("DNS servers reset to DHCP for $selectedAdapter")
        } elseif ($selectedProvider -eq "Custom") {
            $customDns1 = $customDns1TextBox.Text
            $customDns2 = $customDns2TextBox.Text
            $customDnsAddresses = @($customDns1)
            if ($customDns2) {
                $customDnsAddresses += $customDns2
            }
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses $customDnsAddresses
            [System.Windows.MessageBox]::Show("Custom DNS servers set for $selectedAdapter")
        } else {
            $dnsServerAddresses = @($dnsServers.$selectedProvider.Primary, $dnsServers.$selectedProvider.Secondary)
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses $dnsServerAddresses
            [System.Windows.MessageBox]::Show("DNS servers set to $selectedProvider for $selectedAdapter")
        }
    } else {
        [System.Windows.MessageBox]::Show("Please select both a network adapter and a DNS provider.")
    }
})

$window.ShowDialog()
