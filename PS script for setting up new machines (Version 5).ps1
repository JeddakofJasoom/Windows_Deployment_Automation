<# 

This section requires installing nuget, which we don't put on new machines yet, so it is commented out. 
If you want to use nuget, the 2 components are in the file share,
	add them to the root of your external hard drive that is connected to the PC. 

#This automatically pushes windows updates install. 

$scripts = D:\scripts

cd $scripts

# Setup PSWindowsUpdate - HAS to be on *new* w11 23H2 machine to work 
Set-ExecutionPolicy unrestricted -Force
Install-PackageProvider -name NuGet -Minimumversion 2.8.5.201 -Force
Install-Module PSWindowsUpdate -Force
Log-Message "PSwindows update complete"

# Fix WinGet
Add-AppPackage -path .\Microsoft.UI.Xaml.2.8.appx
Add-AppPackage -ForceApplicationShutdown .\winget.msixbundle
Log-Message "Winget is fixed"


Install-Module -Name PSWindowsUpdate -Force #-AllowClobber

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
#comment out the next line if you are working on a LAPTOP, or a machine that will not have a physical firewall. 
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


			# Set active power plan:

# Set the power scheme to High Performance (predefined GUID)
powercfg.exe /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

# Disable sleep on AC and DC (battery) power
powercfg -x standby-timeout-ac 0       # Disables sleep when on AC power
powercfg -x standby-timeout-dc 0       # Disables sleep when on battery power

# Set the display to turn off after 20 minutes on both AC and DC power
powercfg -x monitor-timeout-ac 20      # Turns off display after 20 minutes on AC power
powercfg -x monitor-timeout-dc 20      # Turns off display after 20 minutes on battery power

# Disable hibernate on both AC and DC power
powercfg -x hibernate-timeout-ac 0     # Disables hibernate when on AC power
powercfg -x hibernate-timeout-dc 0     # Disables hibernate when on battery power

			#Set power options on laptops: 

# Set Power Button to shut down on both battery and plugged in
powercfg -setacvalueindex SCHEME_CURRENT SUB_BUTTONS PBUTTONACTION 2   # Plugged in: Shut down
powercfg -setdcvalueindex SCHEME_CURRENT SUB_BUTTONS PBUTTONACTION 2   # On battery: Shut down

# Set Sleep Button to do nothing on both battery and plugged in
powercfg -setacvalueindex SCHEME_CURRENT SUB_BUTTONS SBUTTONACTION 0   # Plugged in: Do nothing
powercfg -setdcvalueindex SCHEME_CURRENT SUB_BUTTONS SBUTTONACTION 0   # On battery: Do nothing

# Set Lid Close Action
powercfg -setacvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 0       # Plugged in: Do nothing
powercfg -setdcvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 2       # On battery: Shut down

# Apply the changes by re-activating the current power scheme
powercfg -setactive SCHEME_CURRENT


# Enable Remote Assistance
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance" `
-name "fAllowToGetHelp" `
-PropertyType DWORD -Value 1 -Force
Log-Message "Enabled Remote Assistance"

# Enable RDP connections without network level authentication
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" `
-Name "UserAuthentication" -Value 0 
#note: do not use a property type switch here - it will break the command. 
#note: 0 turns on allowed RDP connections AND turns off NLA requirement. 
	#In general, this is the value we want on managed client machines. 
#note: 2 turns off RDP connections entirely. We only want this on non-managed client machines. 
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


<# Run Windows Update after all settings changes are made. 
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