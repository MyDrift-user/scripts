Add-Type -AssemblyName PresentationFramework

$Xaml = [xml]@"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Windows Admin Utility" Height="400" Width="600">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        
        <StackPanel Orientation="Horizontal" Grid.Row="0" HorizontalAlignment="Center">
            <Button Name="TabButton1" Content="Client Configuration" Margin="5"/>
            <Button Name="TabButton2" Content="AD" Margin="5"/>
            <Button Name="TabButton3" Content="Chat" Margin="5"/>
        </StackPanel>
        
        <Grid Name="Tab1Content" Grid.Row="1">
            <!-- Content for Tab 1 -->
            <TextBlock Text="Content for Tab 1" VerticalAlignment="Center" HorizontalAlignment="Center"/>
        </Grid>
        
        <Grid Name="Tab2Content" Grid.Row="1" Visibility="Collapsed">
            <!-- Content for Tab 2 -->
            <TextBlock Text="Content for Tab 2" VerticalAlignment="Center" HorizontalAlignment="Center"/>
        </Grid>
        
        <Grid Name="Tab3Content" Grid.Row="1" Visibility="Collapsed">
            <!-- Content for Tab 3 -->
            <TextBlock Text="Content for Tab 3" VerticalAlignment="Center" HorizontalAlignment="Center"/>
        </Grid>
    </Grid>
</Window>
"@

# Load XAML
$Window = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $Xaml))

# Add Event Handlers
$Window.FindName("TabButton1").Add_Click({
    $Window.FindName("Tab1Content").Visibility = "Visible"
    $Window.FindName("Tab2Content").Visibility = "Collapsed"
    $Window.FindName("Tab3Content").Visibility = "Collapsed"
})

$Window.FindName("TabButton2").Add_Click({
    $Window.FindName("Tab1Content").Visibility = "Collapsed"
    $Window.FindName("Tab2Content").Visibility = "Visible"
    $Window.FindName("Tab3Content").Visibility = "Collapsed"
})

$Window.FindName("TabButton3").Add_Click({
    $Window.FindName("Tab1Content").Visibility = "Collapsed"
    $Window.FindName("Tab2Content").Visibility = "Collapsed"
    $Window.FindName("Tab3Content").Visibility = "Visible"
})

# Show Window
$Window.ShowDialog() | Out-Null
