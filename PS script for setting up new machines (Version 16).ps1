############################################################################################################################
				############ START ITNG CUSTOM LOGIN SCRIPT ############
############################################################################################################################
	
<# Trying out new method using a batch file labeled "RUNME.bat" in the flash drive's Scripts folder for easy start.
If batch script does NOT work, you must run this command in admin powershell separately first. THEN you can run the rest of this script as a single powershell script execution. 
>>> Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
	<#Note: This MUST be entered manually first, or it will not allow this script to be run. You can run this in Powershell ISE as an administrator and run it all at once.  >>> Make sure you have the scripts folder with all packages and installers listed below in this script for it to run properly. <<< #>

############################################################################################################################
				### 	CREATE LOG FILE SECTION <START>		###
############################################################################################################################
	

###Create log file to review after script completes.###


# Define log file as variable 
	$logFile = "C:\Sources\initial_setup_log.txt"	# Change TXT filename as needed!
# Create "C:\Sources\" directory to store log files &&  additional applications and scripts as needed. 
	New-Item -ItemType Directory -Path "C:\" -Name "Sources" -Force | Out-Null
# Create log file using the variable defined above. 
	New-Item -ItemType File -Path $logFile -Force | Out-Null
	

###Create custom function to log output messages in this script.###


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

					
############################################################################################################################
					### 	CREATE LOG FILE SECTION <END>		###
############################################################################################################################


############################################################################################################################
					###		MANUAL ENTRY REQUIRED SECTION <START>		###
############################################################################################################################


###PowerShell Script to Change Computer Name with Manual Input.###

	
# Prompt the user to enter the new computer name in CLI and store as variable. 
	$newName = Read-Host "Please enter the new computer name" 
# Get the current computer name and store as variable. 
	$currentName = $env:COMPUTERNAME
# Print to screen the current and new computer name 
	Write-Host "Current Computer Name: $currentName" -ForegroundColor Yellow
	Write-Host "New Computer Name will be: $newName" -ForegroundColor Green
# Command to change the computer name
	Rename-Computer -NewName $newName -Force
# Print to screen the PC name change confirmation and log in log file.
	Write-Host "Computer name changed successfully to '$newName'" -ForegroundColor Green
	Log-Message "Computer name changed successfully to '$newName'"


############################################################################################################################
					###		MANUAL ENTRY REQUIRED SECTION <END>		###
############################################################################################################################


############################################################################################################################
					###		BEGIN MAIN SCRIPT FUNCTION SECTION <START>		###
############################################################################################################################


<#					
# define where the scripts folder is that contains the necessary packages. 					
	$scripts = "D:\Scripts"
# change directory to defined scripts folder. 
	cd $scripts
#>
	


############################################################################################################################
					###		<END>	###
############################################################################################################################


############################################################################################################################
					### 	NETWORKING SETTINGS SECTION <START>		###
############################################################################################################################


#####DISABLE IPV6 ON ALL ADAPTERS.#####

try {		
# Get all active (Up) network adapters
	$adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
	foreach ($adapter in $adapters) 
	{# Loop through each adapter to disable IPv6
	Write-host "Disabling IPv6 on all network adapters." -ForegroundColor Yellow
# Disable IPv6 on network adapter	
	Set-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6 -Enabled $false -ErrorAction Stop
	}
# Log success after processing all adapters
    Write-host "Disabled IPv6 on all network adapters." -ForegroundColor Green
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


#####SET NETWORK TYPE TO PRIVATE FOR ALL ADAPTERS (DEFAULT IS PUBLIC).##### 
		
try {
# Get all network adapters with a network connection
    $networkAdapters = Get-NetConnectionProfile
# Loop through each network adapter
    foreach ($adapter in $networkAdapters) 
	{# Check if the adapter is Ethernet or Wi-Fi
        if ($adapter.InterfaceAlias -like "*Ethernet*" -or $adapter.InterfaceAlias -like "*Wi-Fi*") 
		{# Set network profile to private for the adapter
			Write-Host "Setting network profile for $($adapter.Name) ($($adapter.InterfaceAlias)) to Private." -ForegroundColor Yellow
            Set-NetConnectionProfile -InterfaceIndex $adapter.InterfaceIndex -NetworkCategory Private 
        }}
# Log success after processing all adapters
    Write-Host "All Ethernet and Wi-Fi network profiles set to Private." -ForegroundColor Green
	Log-Message "All Ethernet and Wi-Fi network profiles set to Private."
}
catch {
# Log failure if an error occurs
    Write-Host "An error occurred while setting network profiles: $($_.Exception.Message)" -ForegroundColor Red
	Log-Message "An error occurred while setting network profiles: $($_.Exception.Message)"
}


#### ENABLE ALL WINDOWS FIREWALLS.####
try {

    Set-NetFirewallProfile -Profile Public, Domain, Private -Enabled True
    Write-Host "Enabled ALL Firewalls" -ForegroundColor Green
    Log-Message "Enabled ALL Firewalls"
}
catch {
    # Log any failures
    Write-Host "FAILED to enable all Windows firewalls. Error: $_" -ForegroundColor Red
    Log-Message "FAILED to enable all Windows firewalls. Error: $_"
}


#### ADD WINDOWS FIREWALL RULE TO ALLOW RDP WITH FIREWALL ON.####
try {
																  
    Write-Host "Configuring Windows Firewall to allow RDP (port 3389) on Private and Domain profiles..." -ForegroundColor Yellow
    
    # Enable Remote Desktop rules only for Private and Domain profiles
    Get-NetFirewallRule -DisplayGroup "Remote Desktop" | Where-Object { $_.Profile -match 'Domain|Private' } | Enable-NetFirewallRule
									  
						   

    # Explicitly open port 3389 for TCP, only on Private and Domain profiles
    New-NetFirewallRule -DisplayName "Allow RDP Port 3389" `
        -Direction Inbound `
        -LocalPort 3389 `
        -Protocol TCP `
        -Action Allow `
        -Profile Domain,Private `
        -ErrorAction SilentlyContinue

    # Log port rule addition
    Write-Host "Port 3389 is now open on Private and Domain profiles in the firewall." -ForegroundColor Green
    Log-Message "Port 3389 is now open on Private and Domain profiles in the firewall."
}
				
catch {
    Write-Host "Failed to configure the firewall: $_" -ForegroundColor Red
    Log-Message "Failed to configure the firewall: $_"
}


#### CONFIRM FIREWALL RULE####
$firewallRule = Get-NetFirewallRule -DisplayName "Allow RDP Port 3389" -ErrorAction SilentlyContinue
if ($firewallRule) {
    Write-Host "Firewall rule to allow RDP on port 3389 is active." -ForegroundColor Green
    Log-Message "Firewall rule to allow RDP on port 3389 is active."
} else {
    Write-Host "Firewall rule to allow RDP on port 3389 could not be confirmed." -ForegroundColor Red
    Log-Message "Firewall rule to allow RDP on port 3389 could not be confirmed."
}


#### CONFIGURE REMOTE ACCESS #####

# ENABLE RDP CONNECTIONS
New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -PropertyType DWORD -Value 0 -Force

# REQUIRE NETWORK LEVEL AUTHENTICATION
New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -PropertyType DWORD -Value 1 -Force

# Log changes
Write-Host "Enabled RDP connections with network level authentication required" -ForegroundColor Green
Log-Message "Enabled RDP connections with network level authentication required"

# CHECK IF RDP IS ENABLED										  
$fDenyTSConnections = (Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server').fDenyTSConnections
if ($fDenyTSConnections -eq 0) { 
    Write-Host "Remote Desktop is enabled." -ForegroundColor Green
    Log-Message "Remote Desktop is enabled." 
} else { 
    Write-Host "Remote Desktop is still disabled. Please check settings." -ForegroundColor Red
    Log-Message "Remote Desktop is still disabled. Please check settings."
}

# Log RDP completion
Log-Message "RDP Configuration Completed. Check above log messages to confirm status."


############################################################################################################################
					### 	NETWORKING SETTINGS SECTION <END>	###
############################################################################################################################


############################################################################################################################
					###		POWER SETTINGS SECTION <START>		###
############################################################################################################################


###SET ACTIVE POWER PLAN:####

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

############################################################################################################################
					### POWER SETTINGS SECTION <END> ###
############################################################################################################################


############################################################################################################################
					### MISC SECTION <START> ###
############################################################################################################################


####SET SYSTEM STARTUP ENTRIES.####
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
<# NOTES: the boot loader menu will display for 5 seconds before loading boot manager #>


####INSTALL WMIC.EXE COMMAND.###
try {
	Write-Host "Installing WMIC.EXE..." -ForegroundColor Yellow
	#install wmic capability - see notes below. 
	dism /online /enable-feature /featurename:LegacyComponents /all
	#log success
	Write-Host "Installed WMIC.EXE successfully." -ForegroundColor Green
	Log-Message "Installed WMIC.EXE successfully."
}
catch { #log failure
	Write-Host "FAILED to install WMIC.EXE." -ForegroundColor Red
	Log-Message "FAILED to install WMIC.EXE."
}
<# notes on using dism to install wmic.exe:
	: 24H2 deprecates this and is no longer installed by default.
	: We have RMM components and scripts that still use wmic.exe instead of the newer powershell.
	: This requires a system restart to fully install.
	: All wmic.exe commands are replaced with powershell commands in this script. 
#> 

	
# ENABLE AUTOMATIC REBOOT AFTER SYSTEM FAILURE
try { 
	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "AutoReboot" -Value 1 -ErrorAction Stop
#Log success 
	Write-Host "AutoReboot after system failure has been successfully enabled." -ForegroundColor Green
	Log-Message "AutoReboot after system failure has been successfully enabled."
}
catch { # Log failure
	Write-Host "ERROR: Failed to enable AutoReboot after system failure. Error: $_" -ForegroundColor Red
	Log-Message "ERROR: Failed to enable AutoReboot after system failure. Error: $_" 
}


####SET DEBUGGING INFORMATION TYPE TO NONE####
try { 
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "CrashDumpEnabled" -Value 0 -ErrorAction Stop
# Log success 
	Write-Host "Debugging information type has been set to None." -ForegroundColor Green
	Log-Message "Debugging information type has been set to None."
}
catch { # Log failure
	Write-Host "ERROR: Failed to set DebugInfoType to None. Error: $_" -ForegroundColor Red
	Log-Message "ERROR: Failed to set DebugInfoType to None. Error: $_"
}


####UPDATE AV DEFINITIONS####
try {
	Write-Host "Updating Windows Defender Antivirus Definitions" -ForegroundColor Yellow 
#update windows defender with Powershell
	Update-MpSignature
#log success	
	Write-Host "AV signature definitions update completed successfully" -ForegroundColor Green
	Log-Message "AV signature definitions update completed successfully"
}
catch { 
	Write-Host "ERROR: Failed to update AV signature definitions. Error: $_" -ForegroundColor Red
	Log-Message "ERROR: Failed to update AV signature definitions. Error: $_"
}
	
	
####SET TIMEZONE TO EASTERN TIME####
try {
	Set-TimeZone -Id "Eastern Standard Time"
#restart time service and refresh current time to updated time zone.
	Stop-service w32time 
	Start-Service w32time
	w32tm /resync /Force
#log success
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
#log success
	Write-Host "Time zone has been set to Central Standard Time." -ForegroundColor Green
	Log-Message "Time zone has been set to Central Standard Time."
}
catch {
# Log failure
	Write-Host "ERROR: Failed to set time zone to Central Standard Time. Error: $_" -ForegroundColor Red
	Log-Message "ERROR: Failed to set time zone to Central Standard Time . Error: $_" 
} 
#>


############################################################################################################################
					### MISC SECTION <END> ###
############################################################################################################################


############################################################################################################################
					### APPLICATION INSTALLATION SECTION <START>###
############################################################################################################################
	
	
#####Install 'NuGet' package if missing from system, depending on Windows version.#####
try {
# install package
    Write-Host "Installing latest version of 'NuGet' package from Microsoft" -ForegroundColor Yellow
    Install-PackageProvider -name NuGet -Minimumversion 2.8.5.201 -Force
    
# log success
    Write-Host "SUCCESS: Installed latest version of 'NuGet' package from Microsoft" -ForegroundColor Green
	#Log-Message "Installed latest version of 'NuGet' package from Microsoft"
}
catch {
# log errors (if any)
	Write-Host "ERROR: Failed to install Nuget Error: $_" -ForegroundColor Red
	#Log-Message "ERROR: Failed to install winget Error: $_" 
}


#####INSTALL PS MODULE TO ALLOW POWERSHELL 7 TO RUN WINDOWS UPDATE.#####
try {
# Install PS module to allow Powershell 7 to run Windows Update.
    Write-Host "Installing Powershell Module 'PSWindowsUpdate' to enable Windows Updates through Powershell" -ForegroundColor Yellow
    Install-Module PSWindowsUpdate -Force

# log success
    Write-Host "Installed Powershell Module 'PSWindowsUpdate' to enable Windows Updates through Powershell" -ForegroundColor Green
	Log-Message "Installed Powershell Module 'PSWindowsUpdate' to enable Windows Updates through Powershell"
	}
catch {
# log errors (if any)
    Write-Host "ERROR: Failed to install the Powershell Module 'PSWindowsUpdate' to enable Windows Updates through Powershell Error: $_" -ForegroundColor Red
	Log-Message "ERROR: Failed to install the Powershell Module 'PSWindowsUpdate' to enable Windows Updates through Powershell Error: $_" 
	}
		
	


#####RUN WINGET TO INSTALL STANDARD APPLICATIONS.#####

Write-Host "Running 'WinGet' to install standard software applications." -ForegroundColor Yellow 

# Define the applications to install (name and corresponding winget package)
$apps = @(
	@{Name="Powershell 7"; Package="microsoft.powershell"},
	@{Name="Google Chrome"; Package="Google.Chrome"},
	@{Name="Adobe Acrobat Reader"; Package="adobe.acrobat.reader.64-bit"},
	@{Name="Dell Command Update"; Package="Dell.CommandUpdate"},
	@{Name="Splashtop Streamer"; Package="Splashtop.SplashtopStreamer"},
	@{Name="VLC Media Player"; Package="VideoLAN.VLC"}
  # @{Name="Firefox"; Package="Mozilla.Firefox"}
# Uncomment and add more applications as needed:
	# @{Name=" "; Package=" "},
	# @{Name=" "; Package=" "},
	# @{Name=" "; Package=" "},
	# @{Name=" "; Package=" "},
	# @{Name=" "; Package=" "},
)
<#NOTES: 
	: make sure there is a "," after each "}" until the last "}" to ensure all apps are installed. 
	: you need to use the specific package name as listed in the winget repository
	: winget search "*app name*" will return list of all available versions of the application. 
		: The * * act as wild cards for your query. 
#>

#### INSTALL ALL APPLICATIONS LISTED ABOVE.#### 
foreach ($app in $apps) {
try {
# Install the application silently using winget    
	Write-Host "Installing $($app.Name)..." -ForegroundColor Yellow
    winget.exe install $app.Package --scope machine --silent --accept-source-agreements
# log success
	Write-Host "Installed $($app.Name) successfully." -ForegroundColor Green
	Log-Message "Installed $($app.Name) successfully."
    }
catch {
# Log any failures
    Write-Host "Failed to install $($app.Name). Error: $_" -ForegroundColor Red
    Log-Message "ERROR: Failed to install $($app.Name). Error: $_"
	  }
}


# update all installed software through WinGet
try {
	Write-Host "Updating all apps installed by Winget." -ForegroundColor Yellow
	winget.exe upgrade --all
# log success
	Write-Host "All winget-based software upgrades installed successfully." -ForegroundColor Green
	Log-Message "All winget-based software upgrades installed successfully."

<# NOTES: 
	: for quick single installs use the standard installation command below.
		: Add app package name in the "". 
	: If you do not include the --silent switch, it will give you verbose installation progress by default. 
	: The --accept-source-agreements is used to auto select "yes" to use the ms store and allow the command to run automatically.

#winget.exe install "" --scope machine --accept-source-agreements
#winget.exe install "" --scope machine --accept-source-agreements
#winget.exe install "" --scope machine --accept-source-agreements
#winget.exe install "" --scope machine --accept-source-agreements
#winget.exe install "" --scope machine --accept-source-agreements

#>


#### INSTALL OFFICE 365 ####

#set file path that contains officesetup.exe installer	
	$Office365InstallPath = "D:\Scripts\OfficeSetup.exe"
# Specify the configuration file path
	$configurationFilePath = "D:\Scripts\O365Configuration.xml"
# Set the arguments to include the /configure switch
	$arguments = "/configure $configurationFilePath"
# Set variable to start officesetup.exe with arguments and configuration file.
	$process = Start-Process -FilePath $Office365InstallPath -ArgumentList $arguments -PassThru #note: no "-Wait" needed here as we're using -PassThru
try {
	Write-Host "Starting Office 365 installation in the background. `
	This will take a few minutes and move onto the next step automatically." -ForegroundColor Yellow
	Log-Message "Started Office 365 installation."
# START INSTALL process and wait for the process to complete
    $process.WaitForExit()
# Capture the exit code from the process object
    $exitCode = $process.ExitCode
# Check if installation was successful
    if ($exitCode -eq 0) {
	# log if successful
        Write-Host "Office 365 installed successfully." -ForegroundColor Green
        Log-Message "Office 365 installed successfully."
    } else {
	# log errors 
        Write-Host "Office 365 installation failed with exit code: $exitCode" -ForegroundColor Red
        Log-Message "Office 365 installation failed with exit code: $exitCode"
    }
} catch {
	# log failure to install. 
    $errorMessage = $_.Exception.Message
    Write-Host "Error during Office 365 installation: $errorMessage" -ForegroundColor Red
    Log-Message "Error during Office 365 installation: $errorMessage"
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
############################################################################################################################
					### APPLICATION INSTALLATION SECTION <END> ###
############################################################################################################################


############################################################################################################################
					### SYSTEM UPDATES SECTION <START> ###
############################################################################################################################


##DELL COMMAND SECTION START.

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

## FUNCTION TO RUN DELL UPDATES
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

#### FUNCTION TO CHECK AND RUN DELL UPDATES ####
function Check-And-Run-DCU {
    Set-DCUPath  # Set the correct path
    Run-DellUpdates  # Run updates if the path is valid
}

#### CALL THE FUNCTION TO CHECK AND RUN DELL UPDATES ####
Check-And-Run-DCU


##### RUN WINDOWS UPDATE ####

# Enable PowerShell 7 to install Windows updates. 
 
Import-Module PSWindowsUpdate

# Import Windows Update PS module (needs to have PS ver 7 installed)
try {
    $maxRetries = 2
    $retryCount = 0
    $success = $false

    while (-not $success -and $retryCount -lt $maxRetries) {
	try {
	# Install Windows Updates without AutoReboot
		Write-Host "Starting Windows Updates and will automatically reboot the machine when complete." -ForegroundColor Yellow
		Get-WindowsUpdate -AcceptAll -Install -ErrorAction Stop -AutoReboot:$false
	# If updates are installed successfully, set success flag to true
		$success = $true
		Write-Host "Installed Windows Updates Successfully."
		Log-Message "Installed Windows Updates Successfully."
	}
	catch { $retryCount++
		if ($retryCount -lt $maxRetries) {
		 Write-Host "Windows Update Installation failed. Retrying attempt # $retryCount..." -ForegroundColor Yellow
		}
		else {
			Write-Host "Windows Update Installation failed after $retryCount attempts." -ForegroundColor Red
			Log-Message "Windows Update Installation failed after $retryCount attempts."
			 }	
		  }
    }

# If after retries it fails, handle the failure logging and reboot
    if (-not $success) {
        Write-Host "Windows Update installation failed after $maxRetries attempts. Forcing a reboot in 5 seconds..." -ForegroundColor Red
        Log-Message "Windows Update installation failed after $maxRetries attempts. Forcing a reboot in 5 seconds..."
    } else {
        Write-Host "Updates installed. Rebooting in 5 seconds..." -ForegroundColor Green
    }
}
catch { 
    # Log any errors during the update process
    Write-Host "ERROR: Failed to install Windows Updates. Error: $($_.Exception.Message)" -ForegroundColor Red
    Log-Message "ERROR: Failed to install Windows Updates. Error: $($_.Exception.Message)"
	
}

# End logging to setup log file.
Log-Message "Initial Setup script execution ended."

# 5-second delay before reboot to allow logging to finalize. 
Start-Sleep -Seconds 5

# Force reboot after delay
Restart-Computer -Force


############################################################################################################################