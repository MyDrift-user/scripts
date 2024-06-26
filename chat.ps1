# Load necessary assemblies
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore

# Define XAML for the WPF window
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Chat" Height="450" Width="525">
    <Grid>
        <TextBox Name="NameBox" Height="30" VerticalAlignment="Top" Margin="10,10,100,0" IsReadOnly="True"/>
        <ListBox Name="ChatListBox" Margin="10,50,10,50">
            <ListBox.ItemTemplate>
                <DataTemplate>
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="{Binding Alignment}">
                        <TextBlock Text="{Binding Time}" FontWeight="Bold" Margin="5,0"/>
                        <TextBlock Text="{Binding UserName}" FontWeight="Bold" Margin="5,0"/>
                        <TextBlock Text=": " FontWeight="Bold"/>
                        <TextBlock Text="{Binding Text}" Margin="5,0"/>
                    </StackPanel>
                </DataTemplate>
            </ListBox.ItemTemplate>
        </ListBox>
        <TextBox Name="InputBox" Height="30" VerticalAlignment="Bottom" Margin="10,0,80,10"/>
        <Button Name="SendButton" Content="Send" Width="60" Height="30" VerticalAlignment="Bottom" HorizontalAlignment="Right" Margin="0,0,10,10"/>
    </Grid>
</Window>
"@

# Load XAML
[xml]$xamlWindow = $xaml
$reader = (New-Object System.Xml.XmlNodeReader $xamlWindow)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get WPF elements
$NameBox = $window.FindName("NameBox")
$ChatListBox = $window.FindName("ChatListBox")
$InputBox = $window.FindName("InputBox")
$SendButton = $window.FindName("SendButton")

# Set the default username to the AD username of the current user
$adUsername = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$NameBox.Text = $adUsername

# Server share path
$serverSharePath = "C:\share\chatlog.txt"

# Ensure the directory and file exist
$directory = [System.IO.Path]::GetDirectoryName($serverSharePath)
if (-not (Test-Path -Path $directory)) {
    New-Item -Path $directory -ItemType Directory | Out-Null
}
if (-not (Test-Path -Path $serverSharePath)) {
    New-Item -Path $serverSharePath -ItemType File | Out-Null
}

# Define a class to represent chat messages
class ChatMessage {
    [string]$Time
    [string]$UserName
    [string]$Text
    [string]$Alignment

    ChatMessage([string]$time, [string]$username, [string]$text, [string]$alignment) {
        $this.Time = $time
        $this.UserName = $username
        $this.Text = $text
        $this.Alignment = $alignment
    }
}

# Create an observable collection for chat messages
$messages = [System.Collections.ObjectModel.ObservableCollection[ChatMessage]]::new()

# Set the data context for the chat list box
$ChatListBox.ItemsSource = $messages

# Function to send message
function SendMessage {
    $messageText = $InputBox.Text
    $username = $NameBox.Text
    if ($messageText -ne "" -and $username -ne "") {
        $time = Get-Date -Format "HH:mm:ss"
        $entry = "$time - ${username}: ${messageText}`n"
        $logEntry = "OWN::${entry}"
        Add-Content -Path $serverSharePath -Value $logEntry
        $messages.Add([ChatMessage]::new($time, $username, $messageText, "Right"))
        $InputBox.Clear()
    } elseif ($username -eq "") {
        [System.Windows.MessageBox]::Show("Please enter your name before sending a message.")
    }
}

# Function to check for new messages
function CheckForNewMessages {
    $currentContent = Get-Content -Path $serverSharePath
    $messages.Clear()
    foreach ($line in $currentContent) {
        if ($line -match "^OWN::") {
            $message = $line -replace "^OWN::", ""
            $parts = $message -split " - "
            $time = $parts[0]
            $userMessage = $parts[1] -split ": "
            $username = $userMessage[0]
            $text = $userMessage[1]
            $messages.Add([ChatMessage]::new($time, $username, $text, "Right"))
        } else {
            $parts = $line -split " - "
            $time = $parts[0]
            $userMessage = $parts[1] -split ": "
            $username = $userMessage[0]
            $text = $userMessage[1]
            $messages.Add([ChatMessage]::new($time, $username, $text, "Left"))
        }
    }
}

# Button click event
$SendButton.Add_Click({
    SendMessage
})

# Set timer to check for new messages every second
$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(1)
$timer.Add_Tick({ CheckForNewMessages })
$timer.Start()

# Show window
$window.ShowDialog() | Out-Null
