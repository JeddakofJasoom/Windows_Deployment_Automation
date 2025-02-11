########################################################################################
				############ START CUSTOM LOGIN SCRIPT ############
########################################################################################
	
<# Trying out new method using a batch file labeled "RUNME.bat" in the flash drive's Scripts folder for easy start.
If batch script does NOT work, you must run this command in admin powershell separately first. THEN you can run the rest of this script as a single powershell script execution. 
>>> Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
	<#Note: This MUST be entered manually first, or it will not allow this script to be run. You can run this in Powershell ISE as an administrator and run it all at once.  >>> Make sure you have the scripts folder with all packages and installers listed below in this script for it to run properly. <<< #>


# Stop Windows Update service
function Stop-WindowsUpdate {
    Write-Host "Attempting to STOP Windows Update service..." -ForegroundColor Yellow
try {
# Disable Windows Update service
	Set-Service -Name wuauserv -StartupType Disabled -ErrorAction Stop
	Stop-Service -Name wuauserv -Force -ErrorAction Stop	
# Define all related windows update processes:
    $updateProcesses = @("wuauclt", "usoclient", "waasmedic", "trustedinstaller", "TiWorker", "MoUsoCoreWorker")
# Stop related Windows Update processes:
    foreach ($process in $updateProcesses) {
        Get-Process -Name $process -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    }
# Wait until Windows Update service is fully stopped
    $timeout = 30  # Max wait time in seconds
    $elapsed = 0
    while ((Get-Service -Name wuauserv).Status -eq "Running" -and $elapsed -lt $timeout) {
        Start-Sleep -Seconds 1
        $elapsed++	}
			# If the service is still running after 3 seconds, throw an error and STOP the script. 
		if ((Get-Service -Name wuauserv).Status -eq "Running") {
			Write-Host "WARNING: Windows updates failed to stop running after $timeout seconds. You will need to manually stop the service and process and rerun this script! ERROR: $_" -ForegroundColor Red
		throw "Windows Update service failed to stop within the $timeout seconds timeout period."
			}
#If all processes and services stop succesfully: 
	Write-Host "Windows Update service and related processes stopped successfully." -ForegroundColor Green
} catch { #catch and throw any other errors and STOP the script: 
		Write-Host "WARNING: Windows updates failed to stop running. You will need to manually stop the service and process and rerun this script! ERROR: $($_.Exception.Message)" -ForegroundColor Red
		throw  # Rethrow the error to stop script execution
}}

# Call the function to stop Windows Update before proceeding
# ==========================
# Function Execution: Stop-WindowsUpdate
# ==========================
Stop-WindowsUpdate
 






########################################################################################
				### 	CREATE LOG FILE SECTION <START>		###
########################################################################################
#region	

<#NOTES for USB drive: 
	: make sure you have all the necessary installers in the source folder on your USB drive
		: and that your USB drive is listd as D: or change it as necessary. 
		: otherwise this script will fail to start. 
	: you must use "Scripts" as your folder name in your USB drive, and not "sources". 
		: "Sources" is already a folder in the USB installer as a separate folder and will not work here. 
#> 

			###CREATE LOCAL SOURCES FOLDER FOR INSTALLATION AND LOGGING.### 
			
			
#define folders for holding the installers, scripts, and log files. 
$sourceFolder = "D:\Scripts" 
$destinationFolder = "C:\Sources" 			
#CRITICAL NOTE: If copy function fails: FORCE STOP rest of this script automatically.   
try {
# First checks if there is a sources folder on C: and creates new folder if it doesn't exist. 
	if (-not (Test-Path $destinationFolder)) {	
	# Create "C:\Sources\" directory to store log files &&  additional applications and scripts as needed. 
		New-Item -Path $destinationFolder -ItemType Directory
        Write-Host "Created new 'Sources' folder at: $destinationFolder" -ForegroundColor Green 
	} else {	
		Write-Host "$destinationFolder already exists." -ForegroundColor Yellow 
	}

# Second checks if the USB installer source folder exists
	if (Test-Path $sourceFolder) {    
	# Copy the folder's subcontents to new local sources folder:
		Copy-Item -Path "$sourceFolder\*" -Destination $destinationFolder -Recurse -Force -ErrorAction Stop
		Write-Host "Copied all content from $sourceFolder folder to $destinationFolder" -ForegroundColor Yellow
    } else { 
	# throw critical error and force TERMINATE the rest of this script if the folder copy fails:
    Write-Host "CRITICAL ERROR:" -ForegroundColor Red 
    Write-Host "$sourceFolder does not exist or cannot be found.  `
		This source folder MUST exist as '$sourceFolder' on your USB drive `
        in order to copy over necessary files to the new computer. `
		This script will throw multiple errors if the source and destination folders do not exist." -ForegroundColor Red
    throw "Script function has terminated due to CRITICAL ERROR listed above. Please correct CRITICAL ERROR and rerun script." 
	}
} catch {
    # Log the error and force stop the script
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1  # Force stop the entire script with an error code
}
#log success and proceed with script. 
Write-Host "No errors when creating required folder: '$destinationFolder'." -ForegroundColor Green
Write-Host "STARTING MAIN SCRIPT NOW!" -ForegroundColor Cyan

	<# NOTES
		: If the script reaches this point, the copy was successful, and the rest of the script can continue. 
		: This script WILL terminate itself if the above function was not succesful.
		: You MUST ensure both the above folder paths are named and set correctly for this script to work. 
		: Fix any folder issues and rerun script from the beginning. 
	#> 


			###CREATE LOG FILE TO REVIEW AFTER SCRIPT COMPLETES.###


# Define log file as variable 
	$logFile = "C:\Sources\initial_setup_log.txt"	# Change TXT filename as needed!
# Create log file using the variable defined above. 
if (Test-Path $logFile) {
		Write-Host "Log file already exists at $logFile." -ForegroundColor Yellow
} else {
		New-Item -ItemType File -Path $logFile -Force | Out-Null
		Write-Host "New setup log file created at $logFile." -ForegroundColor Green
}
Write-Host "Remember to check your setup log file: '$logFile' after reboot to see what has been done!" -ForegroundColor Cyan


			###CREATE CUSTOM FUNCTION TO LOG OUTPUT MESSAGES IN THIS SCRIPT.###

# Create function to log messages to the log file. 
function Log-Message {
# define paramater to use the "output" string in the function:
	param (	[string]$message )
	# note:  this is defined as the "[string]" in each call of the Log-Message function.
# create time stamp for each log entry:
	$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss" 
# define a variable to create log entry with message output and time stamp:
	$logEntry = "$timestamp - $message" 
# create and append new message(s) in log file:
	Add-Content -Path $logFile -Value $logEntry
}

# First log message.
	Log-Message "Script execution started."	

	<# NOTES on log message 
		: Function Name is Case Sensitive! 
		: Will log the string as text you manually define in "" with time stamp into the TXT log file. 
	#>

					
########################################################################################
					### 	CREATE LOG FILE SECTION <END>		###
########################################################################################
#endregion


########################################################################################
					### 	NETWORKING SETTINGS SECTION <START>		###
########################################################################################
#region


			####DISABLE IPV6 ON ALL ADAPTERS.####

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
# Log IPv6 disable completion. 
	Log-Message "IPv6 disable operation completed for all network adapters."


			###SET NETWORK TYPE TO PRIVATE FOR ALL ADAPTERS (DEFAULT IS PUBLIC).###
		
		
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


			### ENABLE ALL WINDOWS FIREWALLS.###
			
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


			### ADD WINDOWS FIREWALL RULE TO ALLOW RDP WITH FIREWALL ON.###
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
    Write-Host "Created new firewall rule to allow Port 3389 (RDP) on Private and Domain profiles in Windows Firewall." -ForegroundColor Green
    Log-Message "Created new firewall rule to allow Port 3389 (RDP) on Private and Domain profiles in Windows Firewall."
} catch {
    Write-Host "Failed to add firewall rule to allow RDP over port 3389 for private and domain networks. Error: $_" -ForegroundColor Red
    Log-Message "Failed to add firewall rule to allow RDP over port 3389 for private and domain networks. Error: $_"
}

			### CONFIGURE REMOTE ACCESS ####

# ENABLE RDP CONNECTIONS
	New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -PropertyType DWORD -Value 0 -Force
# REQUIRE NETWORK LEVEL AUTHENTICATION
	New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -PropertyType DWORD -Value 1 -Force
# Log changes
	Write-Host "Enabled RDP connections with network level authentication required" -ForegroundColor Green
	Log-Message "Enabled RDP connections with network level authentication required"
# Log RDP completion
	Log-Message "RDP configuration completed. Check above log messages to confirm status and any errors."



########################################################################################
					### 	NETWORKING SETTINGS SECTION <END>	###
########################################################################################
#endregion

########################################################################################
					###		POWER SETTINGS SECTION <START>		###
########################################################################################
#region


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

########################################################################################
					### POWER SETTINGS SECTION <END> ###
########################################################################################
#endregion



########################################################################################
					### MISC SECTION <START> ###
########################################################################################
#region

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


#### INSTALL WMIC.EXE COMMAND. ###

try {
# Displaying initial install message
    Write-Host "Installing WMIC.exe..." -ForegroundColor Yellow 
# Install WMIC.exe (deprecated by Microsoft):
    Add-WindowsCapability -Online -Name WMIC~~~~ -ErrorAction Stop
} catch {
# Log unexpected errors:
    Write-Host "FAILED to install WMIC.EXE. Error: $($_.Exception.Message)" -ForegroundColor Red
    Log-Message "FAILED to install WMIC.EXE. Error: $($_.Exception.Message)"
}
# Log install status of WMIC.exe if no exception occurred:
$WMICpath = "C:\Windows\System32\wbem\wmic.exe"
if (Test-Path $WMICpath) {
		Write-Host "Installed WMIC.exe successfully." -ForegroundColor Green
		Log-Message "Installed WMIC.EXE successfully."
    } else { 
        Write-Host "Failed to install WMIC.exe." -ForegroundColor Red
        Log-Message "Failed to install WMIC.exe. You will need to try reinstall on next reboot."
	}


<# notes on using dism to install wmic.exe:
	: We have RMM components and scripts that still use wmic.exe instead of the newer powershell versions.
	: WMIC has been deprecated and is no longer installed if the OS is later than windows 10 version 1809 (21H1).
	: Dism will NOT install wmic.exe using LegacyComponents. 
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


	###SET DEBUGGING INFORMATION TYPE TO NONE####
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
#set time zone
	$ESTzone = "Eastern Standard Time" 
	Set-TimeZone -Id "$ESTzone"
#log success
	Write-Host "Time zone has been set to $ESTzone" -ForegroundColor Green
	Log-Message "Time zone has been set to $ESTzone"
#update variable for time resync	
	$NewTimeZone = $ESTzone
} catch {
# Log failure
    Write-Host "ERROR: Failed to set time zone to $ESTzone. Error: $_" -ForegroundColor Red
	Log-Message "ERROR: Failed to set time zone to $ESTzone. Error: $_" 
}

<# 		#Set TimeZone to Central Time (only used for select clients) 
		#- uncomment this and comment out EST section as needed. 
try {
#set time zone
	$CSTzone = "Central Standard Time" 
	Set-TimeZone -Id "$CSTzone"
#log success
	Write-Host "Time zone has been set to $"$CSTzone" -ForegroundColor Green
	Log-Message "Time zone has been set to $"$CSTzone"
#update variable for time resync	
	$NewTimeZone = $CSTzone
} catch {
# Log failure
    Write-Host "ERROR: Failed to set time zone to $"$CSTzone. Error: $_" -ForegroundColor Red
	Log-Message "ERROR: Failed to set time zone to $"$CSTzone. Error: $_" 
}
#>


####RESYNC TIME CLOCK####


try {
    Write-Host "Resyncing time service to $NewTimeZone." -ForegroundColor Yellow
# Stop the w32time service and wait for it to stop
	Stop-Service w32time
# Wait until the service has stopped
	while ((Get-Service w32time).Status -ne 'Stopped') {
		Start-Sleep -Seconds 1
	} Write-Host "w32time service stopped." -ForegroundColor Yellow
# Start the w32time service
	Start-Service w32time
# Wait until the service has started
	while ((Get-Service w32time).Status -ne 'Running') {
		Start-Sleep -Seconds 1
	} Write-Host "w32time service started." -ForegroundColor Yellow
# Resync the time with w32tm
	w32tm /resync /Force 
	start-Sleep -Seconds 2
# Verify synchronization status
	$syncStatus = w32tm /query /status
# Check if resync was successful
	if ($syncStatus -match "Last Successful Sync Time") {
		Write-Host "Successfully resynchronized the time service to the correct time in the $NewTimeZone." -ForegroundColor Green
		Log-Message "Successfully resynchronized the time service to the correct time in the $NewTimeZone."
	} else {
		Write-Host "FAILED to resynchronize the time service to the correct time  in the $NewTimeZone." -ForegroundColor Red
		Log-Message "FAILED to resynchronize the time service to the correct time  in the $NewTimeZone. Check clock configuration."
	}
} catch {
	Write-Host "FAILED to resynchronize the time service to the correct time in the $NewTimeZone." -ForegroundColor Red
	Log-Message "FAILED to resynchronize the time service to the correct time in the $NewTimeZone. Check clock configuration."
}



########################################################################################
					### MISC SECTION <END> ###
########################################################################################
#endregion

########################################################################################
					### APPLICATION INSTALLATION SECTION <START>###
########################################################################################
#region	
	
#####Install 'NuGet' package if missing from system, depending on Windows version.#####

try {
# Suppress any confirmation prompts
	$ConfirmPreference = 'None'
# install package
    Write-Host "Installing latest version of 'NuGet' package from Microsoft" -ForegroundColor Yellow
	Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
# log success
    Write-Host "SUCCESS: Installed latest version of 'NuGet' package from Microsoft" -ForegroundColor Green
	Log-Message "Installed latest version of 'NuGet' package from Microsoft"
}
catch {
# log errors (if any)
	Write-Host "ERROR: Failed to install NuGet. Error: $($_.Exception.Message)" -ForegroundColor Red
    Log-Message "ERROR: Failed to install NuGet. Error: $($_.Exception.Message)"
}


			###RUN WINGET TO INSTALL STANDARD APPLICATIONS.###

Write-Host "Running 'WinGet' to install standard software applications." -ForegroundColor Yellow 

# Define the applications to install (name and corresponding winget package)
$apps = @(
	@{Name="Powershell 7"; Package="microsoft.powershell"},
	@{Name="Google Chrome"; Package="Google.Chrome"},
	@{Name="Adobe Acrobat Reader"; Package="adobe.acrobat.reader.64-bit"},
	@{Name="Dell Command Update"; Package="Dell.CommandUpdate"}
#	@{Name="Splashtop Streamer"; Package="Splashtop.SplashtopStreamer"},
#    @{Name="VLC Media Player"; Package="VideoLAN.VLC"}
#    @{Name="Firefox"; Package="Mozilla.Firefox"}
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


## INSTALL ALL APPLICATIONS LISTED ABOVE.## 
foreach ($app in $apps) { #attempt to install all applications listed in above function
try {
# Install the application silently using winget:
	Write-Host "Installing $($app.Name)..." -ForegroundColor Yellow
    winget.exe install $app.Package --scope machine --silent --accept-source-agreements
		# Note: will still show installation progress bar in CLI.
# log success
	Write-Host "Installed $($app.Name) successfully." -ForegroundColor Green
	Log-Message "Installed $($app.Name) successfully."
} catch {
# Log any failures
    Write-Host "Failed to install $($app.Name). Error: $_" -ForegroundColor Red
    Log-Message "ERROR: Failed to install $($app.Name). Error: $_"
	  }
}

## update all installed software through WinGet
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

#####INSTALL PS MODULE TO ALLOW POWERSHELL 7 TO RUN WINDOWS UPDATE.#####
try {
# Install PS module to allow Powershell 7 to run Windows Update.
    Write-Host "Installing Powershell Module 'PSWindowsUpdate' to enable Windows Updates through Powershell" -ForegroundColor Yellow
    Install-Module PSWindowsUpdate -Force -Wait
# log success
    Write-Host "Installed Powershell Module 'PSWindowsUpdate' to enable Windows Updates through Powershell" -ForegroundColor Green
	Log-Message "Installed Powershell Module 'PSWindowsUpdate' to enable Windows Updates through Powershell"
	}
catch {
# log errors (if any)
    Write-Host "ERROR: Failed to install the Powershell Module 'PSWindowsUpdate' to enable Windows Updates through Powershell Error: $_" -ForegroundColor Red
	Log-Message "ERROR: Failed to install the Powershell Module 'PSWindowsUpdate' to enable Windows Updates through Powershell Error: $_"
}
		

## INSTALL OFFICE 365 ##

#define sources directory as a variable - change as needed. 
	$sources = "C:\Sources"
#set file path that contains officesetup.exe installer
	$Office365InstallPath = "$sources\OfficeSetup.exe"
# Specify the configuration file path - necessary for silent install
	$configurationFilePath = "$sources\O365Configuration.xml"
# Set the arguments to include the /configure switch
	$arguments = "/configure $configurationFilePath"
# Set variable to start officesetup.exe with arguments and configuration file.
	$process = Start-Process -FilePath $Office365InstallPath -ArgumentList $arguments -PassThru 
		#note: no "-Wait" needed here as we're using -PassThru
try {
	Write-Host "Starting Office 365 installation in the background. `
	This will take a few minutes to install and will automatically move onto the next step." -ForegroundColor Cyan
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

########################################################################################
					### APPLICATION INSTALLATION SECTION <END> ###
########################################################################################
#endregion

########################################################################################
					### SYSTEM UPDATES SECTION <START> ###
########################################################################################
#region


<# working on fixing this...
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
#>


#endregion : dell command updates


				##### RUN WINDOWS UPDATE ####
#region

# ENABLE POWERSHELL 7 TO INSTALL WINDOWS UPDATES. 
try {
    # Check if the PSWindowsUpdate module is installed
if (Get-Module -ListAvailable -Name PSWindowsUpdate) {
    Write-Host "PSWindowsUpdate module is already installed." -ForegroundColor Green
    Log-Message "PSWindowsUpdate module is already installed." 
} else {
    Write-Host "PSWindowsUpdate module not found. Attempting to import..." -ForegroundColor Yellow
# Import the module
    Import-Module PSWindowsUpdate -ErrorAction Stop
# log success 
    Write-Host "PSWindowsUpdate module imported successfully." -ForegroundColor Green
    Log-Message "PSWindowsUpdate module imported successfully."
    }
} catch { 
# log error if PS module is not installed.
    $errorMessage = 
@"
!!!!! CRITICAL ERROR: !!!!! 

Failed to import 'PSWindowsUpdate' module.  
It may not be installed. 
Please install it using 'Install-Module -Name PSWindowsUpdate'. 
This script relies on it being installed. 
Windows Updates may not install automatically. 
Please check Windows Updates now.
"@
    Write-Host $errorMessage -ForegroundColor Red
    Log-Message $errorMessage
}


# RESTART WINDOWS UPDATE 
function Start-WindowsUpdateService {
    Write-Host "Attempting to START Windows Update service..." -ForegroundColor Yellow
try {
    # Re-enable and start the Windows Update service
		Set-Service -Name wuauserv -StartupType Automatic
		Start-Service -Name wuauserv
    # Define variables for wait time.
		$timeout = 10  # Max wait time in seconds
		$elapsed = 0
	# Wait until the Windows Update service is fully started
	while ((Get-Service -Name wuauserv).Status -eq "Stopped" -and $elapsed -lt $timeout) 
	{   Start-Sleep -Seconds 1
        $elapsed++ 
	}	
	# If the service is still stopped after timeout, throw an error
        if ((Get-Service -Name wuauserv).Status -eq "Stopped") {
            Write-Host "ERROR: Windows Update service failed to start within the timeout period." -ForegroundColor Red
            throw "Windows Update service failed to start. Please start it manually and install updates."
			}
    # log success
    Write-Host "Windows Update service and related processes started successfully." -ForegroundColor Green
} catch {
        Write-Host "ERROR: Failed to start Windows Update service. ERROR: $($_.Exception.Message)" -ForegroundColor Red
		Log-Message "ERROR: Failed to start Windows Update service. Please check error and rerun windows updates. ERROR: $($_.Exception.Message)" 
        }
}
# ==========================
# Function Execution: Start-WindowsUpdateService
# ==========================
Start-WindowsUpdateService

	
# INSTALL WINDOWS UPDATES
function Install-WindowsUpdates {
try {
	$maxRetries = 2
	$retryCount = 0
	$success = $false
while (-not $success -and $retryCount -lt $maxRetries) 
{
	try { 
		# Install Windows Updates without AutoReboot
		Write-Host "Starting Windows Updates without auto-reboot." -ForegroundColor Yellow

		# PowerShell command to install updates
		Get-WindowsUpdate -AcceptAll -Install -ErrorAction Stop -AutoReboot:$false

		# If updates are installed successfully, set success flag to true
		$success = $true
		Write-Host "Installed Windows Updates successfully." -ForegroundColor Green
		Log-Message "Installed Windows Updates successfully."
	} 
	catch { 
		$retryCount++
		if ($retryCount -lt $maxRetries) {
			Write-Host "Windows Update installation failed. Retrying attempt #$retryCount..." -ForegroundColor Yellow
			Log-Message "Windows Update installation failed. Retrying attempt #$retryCount..."
			}	 
		}
} } catch { 
	# Log any unexpected errors during the update process
	Write-Host "ERROR: Failed to install Windows Updates. Please rerun windows updates manually. Error: $($_.Exception.Message)" -ForegroundColor Red
	Log-Message "ERROR: Failed to install Windows Updates. Please rerun windows updates manually. Error: $($_.Exception.Message)"
	}
} # end function definition

# ==========================
# Function Execution: Install-WindowsUpdates
# ==========================
Install-WindowsUpdates


#endregion 


# End logging to setup log file.
Log-Message "Initial Setup script execution ended."


# Define the path to the PowerShell script you want to run
$scriptPath = "C:\Sources\new_setup_part_2.ps1"

# Create the scheduled task action to run PowerShell as administrator and execute the script
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File $scriptPath"

# Set the trigger to run at startup (on the next reboot)
$trigger = New-ScheduledTaskTrigger -AtStartup

# Define the task settings, e.g., run as highest privileges
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -AllowHardTerminate

# Specify the task to run as SYSTEM (Administrator) and on the next reboot
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount

# Register the scheduled task with the Task Scheduler
Register-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -Principal $principal -TaskName "RunPowerShellScriptAtReboot" -Description "Runs PowerShell script at the next reboot as administrator."


# Force reboot after 5-second delay before reboot to allow logging to finalize. 
shutdown.exe /r /f /t 5

########################################################################################
#endregion

						<# end of script #>