############ START CUSTOM LOGIN SCRIPT ############

	
<# Trying out new method using single line in an admin powershell and save it in txt file to copy paste and run...
>>>FIRST<<< RUN THIS SEPARATELY :
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
	<#Note: This MUST be entered manually first, or it will not allow this script to be run. You can run this in Powershell ISE as an administrator and run it all at once. #> 

# >>> Make sure you have the scripts folder with all packages and installers listed below in this script for it to run properly. <<< 

# PowerShell Script to Change Computer Name with Manual Input
	# Prompt the user to enter the new computer name
$newName = Read-Host "Please enter the new computer name"
	# Get the current computer name
$currentName = $env:COMPUTERNAME
	# Confirm the change
Write-Host "Current Computer Name: $currentName"
Write-Host "New Computer Name will be: $newName"
	# Change the computer name
Rename-Computer -NewName $newName -Force
	# Inform the user to restart the system
Write-Host "Computer name changed successfully to '$newName'"


$scripts = "D:\Scripts"
cd $scripts
	# Define the log file path
$logFile = "C:\Scripts\initial_setup_log.txt"
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

#Disable IPv6 on all adapters
	# Get all active (Up) network adapters
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
	# Loop through each adapter to disable IPv6
foreach ($adapter in $adapters) {
    try {
        Set-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6 -Enabled $false -ErrorAction Stop
        Log-Message "IPv6 has been disabled on the adapter: $($adapter.Name)."
    }
    catch {
        Log-Message "ERROR: Failed to disable IPv6 on the adapter: $($adapter.Name). Error: $_" -ForegroundColor Red
    }
}
# Final log message
Log-Message "IPv6 disable operation completed for all network adapters."

<# old version of disable ipv6

		# Get all network adapters that are up
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
		# Disable IPv6 on each network adapter
foreach ($adapter in $adapters) {
    Set-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6 -Enabled $false
    Log-Message "IPv6 has been disabled on the adapter: $($adapter.Name)."
}
Log-Message "IPv6 has been disabled on all network adapters."
#>

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
Log-Message "All Ethernet and Wi-Fi network profiles set to Private."


# Configure Windows Firewalls
Set-NetFirewallProfile -Profile Public, Domain, Private -Enabled True
Log-Message "Enabled ALL Firewalls"

#Add Windows Firewall rule to allow RDP with firewall on. 
try {
    Log-Message "Configuring Windows Firewall to allow RDP (port 3389) on Private and Domain profiles..." -ForegroundColor Cyan

    # Enable Remote Desktop rules only for Private and Domain profiles
    Get-NetFirewallRule -DisplayGroup "Remote Desktop" | Where-Object {
        $_.Profile -match 'Domain|Private'
    } | Enable-NetFirewallRule

    # Explicitly open port 3389 for TCP, only on Private and Domain profiles
    New-NetFirewallRule -DisplayName "Allow RDP Port 3389" `
        -Direction Inbound `
        -LocalPort 3389 `
        -Protocol TCP `
        -Action Allow `
        -Profile Domain,Private `
        -ErrorAction SilentlyContinue

    Log-Message "Port 3389 is now open on Private and Domain profiles in the firewall." -ForegroundColor Green
	}
catch {
    Log-Message "Failed to configure the firewall: $_" -ForegroundColor Red
	}

#Enable RDP connections with network level authentication
New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -PropertyType DWORD -Value 0 -Force
New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -PropertyType DWORD -Value 1 -Force
Log-Message "Enabled RDP connections with network level authentication"

# Confirm RDP Status
$fDenyTSConnections = (Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server').fDenyTSConnections
if ($fDenyTSConnections -eq 0) {
    Log-Message "Remote Desktop is enabled." -ForegroundColor Green
} else {
    Log-Message "Remote Desktop is still disabled. Please check settings." -ForegroundColor Yellow
}

# Confirm Firewall Rule
$firewallRule = Get-NetFirewallRule -DisplayName "Allow RDP Port 3389" -ErrorAction SilentlyContinue
if ($firewallRule) {
    Log-Message "Firewall rule for port 3389 is active." -ForegroundColor Green
} else {
    Log-Message "Firewall rule for port 3389 could not be confirmed." -ForegroundColor Red
}

Log-Message "RDP Configuration Complete!" -ForegroundColor Green

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


			### Misc section START ###


# Set system startup entries - the boot menu will not be displayed, and the default operating system will boot immediately without delay.
try {
		# Set the boot menu timeout to 0 seconds
    bcdedit.exe /timeout 0
		# Log success
    Write-Host "Boot menu timeout successfully set to 0 seconds."
}
catch {
		# Log failure
    Write-Host "ERROR: Failed to set the boot menu timeout. Error: $_" -ForegroundColor Red
}


<# old version of bcdedit that kept throwing erros bcdedit.exe /Timeout 0
Log-Message "system startup set to boot immediately into Windows"
#> 
	
# Install wmic.exe commands
dism /online /enable-feature /featurename:LegacyComponents /all
	<# notes:
	: 24H2 deprecates this and is no longer installed by default.
	: We have RMM components and scripts that still use wmic.exe instead of the newer powershell.
	: This requires a system restart to fully install.
	: All wmic.exe commands are replaced with powershell commands in this script. 
	#> 
	
# System failure options

try { # Enable automatic reboot after system failure
	    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "AutoReboot" -Value 1 -ErrorAction Stop
		# Log success 
	Log-Message "AutoReboot has been successfully enabled."
}
catch { # Log failure
	Log-Message "ERROR: Failed to enable AutoReboot. Error: $_" -ForegroundColor Red
}

try { # Set debugging information type to None
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "CrashDumpEnabled" -Value 0 -ErrorAction Stop
		# Log success 
	Log-Message "Debugging information type has been set to None."
}
catch { # Log failure
	Log-Message "ERROR: Failed to set DebugInfoType to None. Error: $_" -ForegroundColor Red
}

<# old version 	
	# Enable automatic reboot after system failure
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "AutoReboot" -Value 1
	# Set debugging information type to None
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "CrashDumpEnabled" -Value 0
	#
Log-Message "System settings updated: AutoReboot enabled and DebugInfoType set to None."
#> 

	# Update AV Definitions
try {
	Update-MpSignature
	Log-Message "AV signature definitions update completed successfully"
}
catch { 
	Log-Message "ERROR: Failed to update AV signature definitions. Error: $_" -ForegroundColor Red

	#Set TimeZone to Eastern Time
Set-TimeZone -Name "Eastern Standard Time"
Log-Message "EST time zone set"


	<# Set TimeZone to Central Time - uncomment and comment out EST when needed. 
Set-TimeZone -Name "Central Standard Time"
Log-Message "Central time zone set"
	#>

			### misc section END ###


################################################################################


### Application INSTALLATION section ###

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


	#Install office 365

# Path to the installer - generally uses the USB drive.
$Office365installpath = "D:\Scripts\OfficeSetup.exe"
# Arguments for silent installation
$SilentArguments = "/quiet /norestart"
# Run the installer with arguments
Write-Output "Starting Office 365 installation..."

Start-Process -FilePath $Office365installpath  -ArgumentList $SilentArguments -Wait -NoNewWindow

# Check if installation was successful
if ($LASTEXITCODE -eq 0) {
    Log-Message "Office 365 installed successfully."
} else {
    Log-Message	"Office 365 installation failed with exit code: $LASTEXITCODE"
}


			### Application INSTALLATION section END ###


################################################################################


			### System UPDATES section START ###


##Dell Command section START.

	# Define the directory path and commands
$DCUdirPath = "C:\Program Files (x86)\Dell\CommandUpdate\"  
$reinstallDCU= "winget install -e --id Dell.CommandUpdate --scope machine --accept-source-agreements"
$DCUexePath = "C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe"
	#create function to run dell-updates in cli
function Run-DellUpdates {
		# Run the scan
    & $DCUexePath /scan
		# Apply updates with reboot disabled
    & $DCUexePath /applyUpdates -reboot=Disable
}
	# Call the function: Run-DellUpdates

	# Function to check directory and run .\dcu-cli.exe
function Check-And-Run {
    if (Test-Path $DCUdirPath) {
        Write-Host "Directory '$DCUdirPath' exists. Running Dell Command Update /scan and /applyupdates" -ForegroundColor Green
        Run-DellUpdates
    }
    else {
        Write-Host "Directory '$DCUdirPath' does not exist. Running reinstall using '$reinstallDCU'" -ForegroundColor Yellow
        try {
            Invoke-Expression $reinstallDCU
            Write-Host "Initial command completed successfully." -ForegroundColor Green
        }
        catch {
            Write-Host "ERROR: Failed to run the '$reinstallDCU' command. Error: $_" -ForegroundColor Red
            }
        # Check again if directory exists after running the command
        if (Test-Path $DCUdirPath) {
            Write-Host "Directory '$DCUdirPath' now exists. Running Dell Command Update /scan and /applyupdates" -ForegroundColor Green
            Run-DellUpdates
        }
        else {
            Write-Host "ERROR: Directory '$DCUdirPath' still does not exist after running the command." -ForegroundColor Red
            }
    }
}

# Run the function
Check-And-Run

##Dell Command section END.



<# old DCU	# Run Dell command updates and push installation. 
cd "C:\Program Files (x86)\Dell\CommandUpdate\"
.\dcu-cli.exe /scan
.\dcu-cli.exe /applyUpdates -reboot=Disable
#>

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