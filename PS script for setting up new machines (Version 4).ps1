<# Install-Module -Name PSWindowsUpdate -Force #-AllowClobber

Import-Module PSWindowsUpdate

Install-WindowsUpdate -AcceptAll -AutoReboot

#Get-Module PSWindowsUpdate

#Get-WindowsUpdate

# Install-WindowsUpdate -AcceptAll -AutoReboot

#Get-WindowsUpdate -IgnoreReboot
#>

mkdir C:\scripts

$logFile = "C:\Scripts\setup_log.txt"

# Function to log messages
function Log-Message {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $message"
    Add-Content -Path $logFile -Value $logEntry
}

# Start logging
Log-Message "Script execution started."

try {

# Set TimeZone to Eastern Time
Set-TimeZone -Name "Eastern Standard Time"
Log-Message "EST time zone set"

# Disable Windows Firewalls
Set-NetFirewallProfile -Profile Public -Enabled True
Set-NetFirewallProfile -Profile Domain, Private -Enabled False
Log-Message "Disabled Firewalls"

# Get all network adapters that are up
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }

# Disable IPv6 on each network adapter
foreach ($adapter in $adapters) {
    Set-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6 -Enabled $false
    Log-Message "IPv6 has been disabled on the adapter: $($adapter.Name)."
}
Log-Message "IPv6 has been disabled on all network adapters."


# Set active power plan
powercfg.exe /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
powercfg -x standby-timeout-ac 0 #disables sleep on charger/power brick"
powercfg -x standby-timeout-dc 0 #disables sleep on battery power for laptops"
powercfg -x monitor-timeout-ac 20 #sets display to turn off after 20 minutes on charger/power brick"
powercfg -x monitor-timeout-dc 20 #sets display to turn off after 20 minutes on battery power for laptops"
powercfg -x hibernate-timeout-ac 0 #disables hibernate on charger/power brick"
powercfg -x hibernate-timeout-dc 0 #disables hibernate on battery power for laptops"
Log-Message "set power configuration settings"

# Enable Remote Assistance
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance" `
-name "fAllowToGetHelp" `
-PropertyType DWORD -Value 1 -Force
Log-Message "Enabled Remote Assistance"

# Enable RDP connections without network level authentication
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" `
-Name "UserAuthentication" -Value 0 
#note: do not use a propertype switch here - it will break the command. 
#note: 0 turns on allowed RDP connections AND turns off NLA requirement. 
#note: 2 turns OFF RDP connections entirely. 
Log-Message "Enabled RDP connections without network level authentication"

# Set system startup entries - the boot menu will not be displayed, and the default operating system will boot immediately without delay.
bcdedit.exe /Timeout 0
Log-Message "system startup set to boot immediately into Windows"

# System failure options
wmic.exe recoveros set AutoReboot = True #enables the automatic reboot feature after a system failure (BSOD).
wmic.exe recoveros set DebugInfoType = 0 #sets the type of debugging information written to the disk when the system crashes. A value of 0 indicates that no debugging information will be written.

# Update AV Definitions
Update-MpSignature
Log-Message "AV signature definitions update completed successfully"

#Log-Message "All software upgrades installed successfully."

<# Run Windows Update
Get-WindowsUpdate -AcceptAll -Install # -AutoReboot
Log-Message "Starting Windows Updates and will automatically reboot the machine when complete."
#> 
    # Final message
    Log-Message "All tasks completed successfully."
}
catch {
    Log-Message "An error occurred: $_"
}

# End logging
Log-Message "Script execution ended."
Pause