############ START ITNG CUSTOM LOGIN SCRIPT ############

	
<# Trying out new method using a batch file labeled "RUNME.bat" in the flash drive's Scripts folder for easy start.
If batch script does NOT work, you must run this command in admin powershell separately first. THEN you can run the rest of this script as a single powershell script execution. 
>>> Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
	<#Note: This MUST be entered manually first, or it will not allow this script to be run. You can run this in Powershell ISE as an administrator and run it all at once. #> 

# >>> Make sure you have the scripts folder with all packages and installers listed below in this script for it to run properly. <<< 


############################################################################################################################
		
		
					### 	CREATE LOG FILE SECTION <START>		###
	

		### Create log file to review after script completes.

# Define log file as variable 
	$logFile = "C:\Sources\initial_setup_log.txt"	# Change TXT filename as needed!
# Create "C:\Sources\" directory to store log files &&  additional applications and scripts as needed. 
	New-Item -ItemType Directory -Path "C:\" -Name "Sources" -Force | Out-Null
# Create log file using the variable defined above. 
	New-Item -ItemType File -Path $logFile -Force | Out-Null
	

		### Create custom function to log output messages in this script.


# Create function to log messages to the log file. 

function Log-Message {
	# define paramater to use the "output" string in the function
		param (
			[string]$message 
			# note:  this is defined as the "[string]" in each call of the Log-Message function
		)
	# create time stamp for each log entry.
		$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss" 
	# define variable to create log entry with message output and time stamp.
		$logEntry = "$timestamp - $message" 
	# create message in log file.
		Add-Content -Path $logFile -Value $logEntry
	}

# First log message.
	Log-Message "Script execution started."	
		<# notes: 
		# Function Name is Case Sensitive! 
		# Will log the string as text you manually define in "" with time stamp into the TXT log file. 
		#>


					### 	CREATE LOG FILE SECTION <END>		###
					
					
############################################################################################################################
		
		
					###		MANUAL ENTRY REQUIRED SECTION <START>		###


		### PowerShell Script to Change Computer Name with Manual Input
	
# Prompt the user to enter the new computer name in CLI and store as variable. 
	$newName = Read-Host "Please enter the new computer name"
# Get the current computer name and store as variable. 
	$currentName = $env:COMPUTERNAME
# Print to screen the current and new computer name 
	Write-Host "Current Computer Name: $currentName"
	Write-Host "New Computer Name will be: $newName"
# Command to change the computer name
	Rename-Computer -NewName $newName -Force
# Print to screen the PC name change confirmation and log in log file.
	Write-Host "Computer name changed successfully to '$newName'"
	Log-Message "Computer name changed successfully to '$newName'"


					###		MANUAL ENTRY REQUIRED SECTION <END>		###


############################################################################################################################
			
			
					###		Begin main script function SECTION <START>		###
					
					
# define where the scripts folder is that contains the necessary packages. 					
	$scripts = "D:\Scripts"
# change directory to defined scripts folder. 
	cd $scripts
	
	
		### Setup Powershell 7 to run winget app-installer and windows update


# Setup PSWindowsUpdate

try {
# install nuget if missing from system, depending on Windows version. 
	Install-PackageProvider -name NuGet -Minimumversion 2.8.5.201 -Force
# install module to allow powershell 7 to run windows update. 	
	Install-Module PSWindowsUpdate -Force
# log completion	
	Log-Message "PSwindows update complete"

# Fix WinGet - make sure both of these packages are in the .\scripts folder. You can get most current versions from GitHub. 
	Add-AppPackage -path "D:\Scripts\Microsoft.UI.Xaml.2.8.appx" 
		#note on version 14 for 24h2: keep getting errors thrown that this is already running... need to test on new install if this is already installed from ms store or not. 
# Install WinGet package 
	Add-AppPackage -ForceApplicationShutdown "D:\Scripts\winget.msixbundle"
	Log-Message "Winget is fixed"
		}
		catch {
			Write-Host "ERROR: Failed to install winget Error: $_" -ForegroundColor Red
			Log-Message "ERROR: Failed to install winget Error: $_" -ForegroundColor Red
		}
	
	
############################################################################################################################


					### 	NETWORKING SETTINGS SECTION <START>		###


		### Disable IPv6 on all adapters
		
		
# Get all active (Up) network adapters
	$adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }

# Loop through each adapter to disable IPv6
foreach ($adapter in $adapters) {
    try {
    # Disable IPv6 on network adapter
		Set-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6 -Enabled $false -ErrorAction Stop
	# Log success(es). 
        Write-host "Disabling IPv6 on all network adapters."
		Log-Message "IPv6 has been disabled on the adapter: $($adapter.Name)."
    }
    catch {
	# Log failure(s). 
        Write-Host "ERROR: Failed to disable IPv6 on the adapter: $($adapter.Name). Error: $_" -ForegroundColor Red
		Log-Message "ERROR: Failed to disable IPv6 on the adapter: $($adapter.Name). Error: $_"
    }
}
# Log IPv6 disable completion. 
	Log-Message "IPv6 disable operation completed for all network adapters."


		### Set Network type to PRIVATE for all adapters (default is public). 
		
		
# Get all network adapters with a network connection
	$networkAdapters = Get-NetConnectionProfile

try { 
	# Loop through each network adapter 
	foreach ($adapter in $networkAdapters)
	{ # Check if the adapter is Ethernet or Wi-Fi
		if ($adapter.InterfaceAlias -like "*Ethernet*" -or $adapter.InterfaceAlias -like "*Wi-Fi*") 
		{ # change network profile to private 
        Write-Host "Setting network profile for $($adapter.Name) ($($adapter.InterfaceAlias)) to Private."
        Set-NetConnectionProfile -InterfaceIndex $adapter.InterfaceIndex -NetworkCategory Private
		}
	}
# Log all success(es):
	Log-Message "All Ethernet and Wi-Fi network profiles set to Private."
	
# Catch any errors and log them.	
catch {

	Write-Error "An error occurred while setting network profiles: $($_.Exception.Message)"
    Log-Message "An error occurred while setting network profiles: $($_.Exception.Message)"
}




# Configure Windows Firewalls
Set-NetFirewallProfile -Profile Public, Domain, Private -Enabled True
Log-Message "Enabled ALL Firewalls"

#Add Windows Firewall rule to allow RDP with firewall on. 
try {
    Write-Host "Configuring Windows Firewall to allow RDP (port 3389) on Private and Domain profiles..." -ForegroundColor Cyan

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

	Write-Host "Port 3389 is now open on Private and Domain profiles in the firewall." -ForegroundColor Green
    Log-Message "Port 3389 is now open on Private and Domain profiles in the firewall."
	}
catch {
    Write-Host "Failed to configure the firewall: $_" -ForegroundColor Red
	Log-Message "Failed to configure the firewall: $_" 
	}

		##Enable RDP connections with network level authentication
New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -PropertyType DWORD -Value 0 -Force
New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -PropertyType DWORD -Value 1 -Force

Write-Host "Enabled RDP connections with network level authentication" -ForegroundColor Green
Log-Message "Enabled RDP connections with network level authentication"

# Define variable for checking RDP Status
$fDenyTSConnections = (Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server').fDenyTSConnections

# Check RDP status
if ($fDenyTSConnections -eq 0) {
	Write-Host "Remote Desktop is enabled." -ForegroundColor Green
    Log-Message "Remote Desktop is enabled." 
} else {
    Log-Message "Remote Desktop is still disabled. Please check settings." -ForegroundColor Yellow
}

# Confirm Firewall Rule
$firewallRule = Get-NetFirewallRule -DisplayName "Allow RDP Port 3389" -ErrorAction SilentlyContinue
if ($firewallRule) {
    Write-Host "Firewall rule to allow RDP on port 3389 is active." -ForegroundColor Green
	Log-Message "Firewall rule to allow RDP on port is active."
} else {
	Write-Host "Firewall rule to allow RDP on port could not be confirmed." -ForegroundColor Green
    Log-Message "Firewall rule to allow RDP on port could not be confirmed."
}

Log-Message "RDP Configuration Completed. Check above log messages to confirm status." -ForegroundColor Cyan


					### 	NETWORKING SETTINGS SECTION <END>		###


############################################################################################################################


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


############################################################################################################################


					### Misc section START ###


# Set system startup entries - the boot menu will not be displayed, and the default operating system will boot immediately without delay.
try {
		# Set the boot menu timeout to 5 seconds (gives us time to enter BIOS easily)
    bcdedit.exe /timeout 5
		# Log success
    Write-Host "Boot menu timeout successfully set to 5 seconds." -ForegroundColor Green
	Log-Message "Boot menu timeout successfully set to 5 seconds."
}
catch {
		# Log failure
   Write-Host "ERROR: Failed to set the boot menu timeout. Error: $_" -ForegroundColor Red
   Log-Message "ERROR: Failed to set the boot menu timeout. Error: $_"
}

	
# Install wmic.exe commands
Write-Host "Installing WMIC.EXE..." -ForegroundColor Cyan
try {
	dism /online /enable-feature /featurename:LegacyComponents /all
	
	Write-Host "Installed WMIC.EXE successfully." -ForegroundColor Green
	Log-Message "Installed WMIC.EXE successfully."
}
catch {
	Write-Host "FAILED to install WMIC.EXE." -ForegroundColor Red
	Log-Message "FAILED to install WMIC.EXE."
}
	<# notes on using dism to install wmic.exe:
	: 24H2 deprecates this and is no longer installed by default.
	: We have RMM components and scripts that still use wmic.exe instead of the newer powershell.
	: This requires a system restart to fully install.
	: All wmic.exe commands are replaced with powershell commands in this script. 
	#> 
	
# System failure options

try { # Enable automatic reboot after system failure
	    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "AutoReboot" -Value 1 -ErrorAction Stop
		# Log success 
	Write-Host "AutoReboot after system failure has been successfully enabled." -ForegroundColor Green
	Log-Message "AutoReboot after system failure has been successfully enabled."
}
catch { # Log failure
	Write-Host "ERROR: Failed to enable AutoReboot after system failure. Error: $_" -ForegroundColor Red
	Log-Message "ERROR: Failed to enable AutoReboot after system failure. Error: $_" 
}

try { # Set debugging information type to None
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "CrashDumpEnabled" -Value 0 -ErrorAction Stop
		# Log success 
	Write-Host "Debugging information type has been set to None." -ForegroundColor Green
	Log-Message "Debugging information type has been set to None."
}
catch { # Log failure
	Write-Host "ERROR: Failed to set DebugInfoType to None. Error: $_" -ForegroundColor Red
	Log-Message "ERROR: Failed to set DebugInfoType to None. Error: $_"
}

	# Update AV Definitions

Write-Host "Updating Windows Defender Antivirus Definitions" -ForegroundColor Cyan 	
try {
	Update-MpSignature
	Write-Host "AV signature definitions update completed successfully" -ForegroundColor Green
	Log-Message "AV signature definitions update completed successfully"
}
catch { 
	Write-Host "ERROR: Failed to update AV signature definitions. Error: $_" -ForegroundColor Red
	Log-Message "ERROR: Failed to update AV signature definitions. Error: $_"
}
	
	#Set TimeZone to Eastern Time
try {
	Set-TimeZone -Id "Eastern Standard Time"
	#restart time service and refresh current time to updated time zone.
	Stop-service w32time 
	Start-Service w32time
	w32tm /resync /Force
	
	Write-Host "Time zone has been set to Eastern Standard Time." -ForegroundColor Green
	Log-Message "Time zone has been set to Eastern Standard Time."
}
catch {
		# Log failure
    Write-Host "ERROR: Failed to set time zone to Eastern Standard Time. Error: $_" -ForegroundColor Red
	Log-Message "ERROR: Failed to set time zone to Eastern Standard Time. Error: $_" 
}

<# 		Set TimeZone to Central Time (only used for select clients) 
		- uncomment and comment out EST when needed. 
try {
	Set-TimeZone -Id "Central Standard Time"
	#restart time service and refresh current time to updated time zone.
	Stop-service w32time
	Start-Service w32time
	w32tm /resync /Force

	Write-Host "Time zone has been set to Central Standard Time." -ForegroundColor Green
	Log-Message "Time zone has been set to Central Standard Time."
}
catch {
	# Log failure
	Write-Host "ERROR: Failed to set time zone to Central Standard Time. Error: $_" -ForegroundColor Red
	Log-Message "ERROR: Failed to set time zone to Central Standard Time . Error: $_" 
}

#>

					### misc section END ###


############################################################################################################################


					### Application INSTALLATION section ###

	# Run WinGet to install standard applications 

Write-Host "running winget to install standard software applications." -ForegroundColor Cyan 

#install applications using winget automatically. ADD MORE software as needed per individual machine. 
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
winget.exe install Splashtop.SplashtopStreamer --scope machine --accept-source-agreements
Log-Message "Installed Splashtop Streamer successfully."
winget.exe install VideoLAN.VLC --scope machine --accept-source-agreements
Log-Message "Installed VLC Media Player successfully."
#winget.exe install  --scope machine --accept-source-agreements
#winget.exe install  --scope machine --accept-source-agreements
#winget.exe install  --scope machine --accept-source-agreements
#winget.exe install  --scope machine --accept-source-agreements
#winget.exe install  --scope machine --accept-source-agreements

#update all apps installed by winget.
winget.exe upgrade --all
Log-Message "All software upgrades installed successfully."
	<# note: The --accept-source-agreements is used to auto select "yes" to use the ms store and allow the command to run automatically.
	#> 


			## Install Office 365
			
# Path to the installer - ensure this path is correct and accessible
$Office365InstallPath = "D:\Scripts\OfficeSetup.exe"

Write-Host "Starting Office 365 installation..."
Log-Message "Started Office 365 installation."

# Start installation process
try {
    # Run the installer with arguments
    Start-Process -FilePath $Office365InstallPath -NoNewWindow -Wait	
	
    # Check if installation was successful
    if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq $null) {
        Log-Message "Office 365 installed successfully."
        Write-Host "Office 365 installed successfully." -ForegroundColor Green
    } else {
        Log-Message "Office 365 installation failed with exit code: $LASTEXITCODE"
        Write-Host "Office 365 installation failed with exit code: $LASTEXITCODE" -ForegroundColor Red
    }
} catch {
    # Handle errors during the installation process
    $errorMessage = $_.Exception.Message
    Log-Message "Error during Office 365 installation: $errorMessage"
    Write-Host "Error during Office 365 installation: $errorMessage" -ForegroundColor Red
}








<# install Sonicwall NetExtender:

msiexec.exe /i "D:\Scripts\NetExtender-x64-10.2.341.msi" /qn /norestart server=#.#.#.# domain=LocalDomain EDITABLE=TRUE netlogon=true ALLUSERS=2
	<# notes:
	: /qn = silent install 
	: /norestart = does not restart PC after install
	: server = public IP address
	: domain = LocalDomain always
	: ALLUSERS=2 installs this for all users on the PC; case sensitive command.
	#> 
#> 

					### Application INSTALLATION section END ###


############################################################################################################################


					### System UPDATES section START ###


		##Dell Command section START.

# Define the possible directory paths for Dell Command Update
$DCUdirPath1 = "C:\Program Files (x86)\Dell\CommandUpdate\"
$DCUdirPath2 = "C:\Program Files\Dell\CommandUpdate\"
$global:DCUdirPath = $null  # Initialize the unified directory path variable

# Function to check if either path exists and set $DCUdirPath
function Set-DCUPath {
    if (Test-Path $DCUdirPath1) {
        $global:DCUdirPath = $DCUdirPath1
        Write-Output "Using Dell Command Update Path: $DCUdirPath1" -ForegroundColor Green
    }
    elseif (Test-Path $DCUdirPath2) {
        $global:DCUdirPath = $DCUdirPath2
        Write-Output "Using Dell Command Update Path: $DCUdirPath2" -ForegroundColor Green
    }
    else {
        Write-Output "Dell Command Update is not installed on this system." -ForegroundColor Red
        $global:DCUdirPath = $null
    }
}

# Function to run Dell updates
function Run-DellUpdates {
    if ($null -ne $global:DCUdirPath) {
        $DCUexePath = Join-Path -Path $global:DCUdirPath -ChildPath "dcu-cli.exe"
        if (Test-Path $DCUexePath) {
            try {
                # Run the scan
                Write-Output "Starting Dell Command Update scan..." -ForegroundColor Cyan
                $scanResult = & $DCUexePath /scan 2>&1
                Write-Output $scanResult -ForegroundColor Green

                # Apply updates with reboot DISabled ( PC will restart at the end of this script)
                Write-Output "Applying updates..." -ForegroundColor Cyan
                $applyResult = & $DCUexePath /applyUpdates -reboot=Disable 2>&1
                Write-Output $applyResult -ForegroundColor Cyan

                # Check for errors
                if ($scanResult -match "Error" -or $applyResult -match "Error") {
                    Write-Output "An error occurred during the update process." -ForegroundColor Red
                } else {
                    Write-Output "Dell updates completed successfully." -ForegroundColor Green
                }
            }
            catch {
                Write-Output "An unexpected error occurred with Dell Command Update: $_" -ForegroundColor Red
            }
        }
        else {
            Write-Output "Dell Command Update executable not found in $global:DCUdirPath" -ForegroundColor Red
        }
    }
    else {
        Write-Output "Dell Command Update path is not set." -ForegroundColor Red
    }
}

# Function to check and run Dell updates
function Check-And-Run-DCU {
    Set-DCUPath  # Set the correct path
    Run-DellUpdates  # Run updates if the path is valid
}

# Call the function to check and run Dell updates
Check-And-Run-DCU


	# Run Windows Update

Write-Host "Starting Windows Updates and will automatically reboot the machine when complete." -ForegroundColor Cyan

try {
    # Import Windows Update PS module (needs to have PS ver 7 installed) 
    Import-Module PSWindowsUpdate

    $maxRetries = 2
    $retryCount = 0
    $success = $false

    while (-not $success -and $retryCount -lt $maxRetries) {
        try {
            # Install Windows Updates without AutoReboot
            Get-WindowsUpdate -AcceptAll -Install -ErrorAction Stop -AutoReboot:$false
            Write-Host "Windows Updates installation succeeded. Restarting machine in 5 seconds." -ForegroundColor Green
			Log-Message "Installed Windows updates."
            $success = $true
        } catch {
            $retryCount++
            if ($retryCount -lt $maxRetries) {
                Write-Host "Windows Update Installation failed. Retrying attempt $retryCount..." -ForegroundColor Yellow
            } else {
                Write-Host "Windows Update Installation failed after $retryCount attempts." -ForegroundColor Red
				Log-Message "Windows Update Installation failed after $retryCount attempts."
                throw "Windows Update failed after $retryCount attempts."
            }
        }
    }

    # Log successful installation
    Log-Message "Installed Windows updates."

    # Log reboot message
    Write-Host "Updates installed. Rebooting in 5 seconds..." -ForegroundColor Green

    # 5-second delay before reboot to allow logging to finalize. 
    Start-Sleep -Seconds 5

    # Force reboot after delay
    Restart-Computer -Force
}
catch { 
    # Log any errors during the update process
    Log-Message "ERROR: Failed to install Windows Updates. Error: $($_.Exception.Message)"
    Write-Host "ERROR: Failed to install Windows Updates. Error: $($_.Exception.Message)" -ForegroundColor Red
}

					### 


# End logging
Log-Message "Script execution ended."

############################################################################################################################