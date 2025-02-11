############ START CUSTOM LOGIN SCRIPT ############

	
# >>>FIRST<<< RUN THIS SEPARATELY :
Set-ExecutionPolicy unrestricted -Force
	<#Note: This MUST be entered manually first, or it will not allow this script to be run. You can run this in Powershell ISE as an administrator and run it all at once. #> 

# >>> Make sure you have the scripts folder with all packages and installers listed below in this script for it to run properly. <<< 

$scripts = "D:\Scripts"
cd $scripts
	# Define the log file path
$logFile = "D:\Scripts\setup_log.txt"
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


	# Begin main script function 
try {
		### Setup Powershell 7 to run winget app-installer and windows update ###
	
	# Setup PSWindowsUpdate - HAS to be on *new* w11 23H2 machine to work 
Install-PackageProvider -name NuGet -Minimumversion 2.8.5.201 -Force
Install-Module PSWindowsUpdate -Force
Log-Message "PSwindows update complete"

	# Fix WinGet - make sure both of these packages are in the .\scripts folder. You can get most current versions from GitHub. 
Add-AppPackage -path "D:\Scripts\Microsoft.UI.Xaml.2.8.appx"
Add-AppPackage -ForceApplicationShutdown "D:\Scripts\winget.msixbundle"
Log-Message "Winget is fixed"
	
	
################################################################################


### Networking Settings Section START ###

	# Disable Windows Firewalls
Set-NetFirewallProfile -Profile Public -Enabled True
		#comment out the next line if you are working on a LAPTOP, or a machine that will not have a physical firewall. 
Set-NetFirewallProfile -Profile Domain, Private -Enabled False
Log-Message "Disabled Firewalls"

	#Disable IPv6 on all adapters
		# Get all network adapters that are up
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
		# Disable IPv6 on each network adapter
foreach ($adapter in $adapters) {
    Set-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6 -Enabled $false
    Log-Message "IPv6 has been disabled on the adapter: $($adapter.Name)."
}
Log-Message "IPv6 has been disabled on all network adapters."

	# Set Network type to PRIVATE (default is public). 
		# Get all network adapters with a network connection
$networkAdapters = Get-NetConnectionProfile
foreach ($adapter in $networkAdapters) {
    # Check if the adapter is Ethernet or Wi-Fi
    if ($adapter.InterfaceAlias -like "*Ethernet*" -or $adapter.InterfaceAlias -like "*Wi-Fi*") {
        Write-Output "Setting network profile for $($adapter.Name) ($($adapter.InterfaceAlias)) to Private."
        Set-NetConnectionProfile -InterfaceIndex $adapter.InterfaceIndex -NetworkCategory Private
    }
}
Write-Output "All Ethernet and Wi-Fi network profiles set to Private."

	#Enable RDP connections without network level authentication
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" `
-Name "UserAuthentication" -Value 0 
		<# notes: 
		: do not use a property type switch here - it will break the command. 
		: 0 turns ON allowed RDP connections AND turns off NLA requirement. 
		: In general, this is the value we want on managed client machines. 
		: 2 turns off RDP connections entirely. We only want this on non-managed client machines. 
		#> 
Log-Message "Enabled RDP connections without network level authentication"

### Networking Settings Section END ###


################################################################################


### Power Settings Section START ###

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


### Power Settings Section END ###


################################################################################


### Misc section ###


	# Set system startup entries - the boot menu will not be displayed, and the default operating system will boot immediately without delay.
bcdedit.exe /Timeout 0
Log-Message "system startup set to boot immediately into Windows"

	# Install wmic.exe commands
dism /online /enable-feature /featurename:LegacyComponents /all
	<# notes:
	: 24H2 deprecates this and is no longer installed by default.
	: We have RMM components and scripts that still use wmic.exe instead of the newer powershell.
	: This requires a system restart to fully install.
	: All wmic.exe commands are replaced with powershell commands in this script. 
	#> 
	
	# System failure options
	
		# Enable automatic reboot after system failure
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "AutoReboot" -Value 1
		# Set debugging information type to None
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "CrashDumpEnabled" -Value 0

Log-Message "System settings updated: AutoReboot enabled and DebugInfoType set to None."


	# Update AV Definitions
Update-MpSignature
Log-Message "AV signature definitions update completed successfully"


	#Set TimeZone to Eastern Time
Set-TimeZone -Name "Eastern Standard Time"
Log-Message "EST time zone set"


	<# Set TimeZone to Central Time (only used for select clients) - uncomment and comment out EST when needed. 
Set-TimeZone -Name "Central Standard Time"
Log-Message "Central time zone set"
	#>


	# Run WinGet to install standard applications 
		 
winget.exe install microsoft.powershell --scope machine --accept-source-agreements
Log-Message "Powershell 7 installed successfully."
winget.exe install Google.Chrome --scope machine --accept-source-agreements
Log-Message "Google Chrome installed successfully."
#winget.exe install Mozilla.Firefox --scope machine --accept-source-agreements
#Log-Message "Firefox installed successfully."
winget.exe install adobe.acrobat.reader.64-bit --scope machine --accept-source-agreements
Log-Message "Adobe Reader installed successfully."
winget install -e --id Dell.CommandUpdate --scope machine --accept-source-agreements
Log-Message "Dell Command installed successfully."
winget.exe upgrade --all
Log-Message "All software upgrades installed successfully."
	<# note: The --accept-source-agreements is used to auto select "yes" to use the ms store and allow the command to run automatically.
	#> 


	# Run Dell command updates and push installation. 
cd "C:\Program Files (x86)\Dell\CommandUpdate\"
.\dcu-cli.exe /scan
.\dcu-cli.exe /applyUpdates -reboot=Disable


	# Run Windows Update
Write-Host "Starting Windows Updates and will automatically reboot the machine when complete."
Get-WindowsUpdate -AcceptAll -Install -AutoReboot


	# Final message
Log-Message "All tasks completed successfully."
}
catch {
    Log-Message "An error occurred: $_"
}

# End logging
Log-Message "Script execution ended."
Pause