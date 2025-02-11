<# to do:
- log function 
- dism 
- sfc
- dell command second run
- windows updates again
- run checks for:
	firewalls
	network profile
	ipv6 disable
	rdp turned on with 3389 allowed rule
	
add bloatware removal
add defualt user profile XML 

#>


###Create log file to review after script completes.###

# Define log file as variable 
	$logFile = "C:\Sources\post_setup_log.txt"	# Change TXT filename as needed!
# Create log file using the variable defined above. 
	New-Item -ItemType File -Path $logFile -Force | Out-Null
	

###Create custom function to log Host messages in this script.###

# Create function to log messages to the log file. 
function Log-Message {
# define paramater to use the "Host" string in the function
	param (
		[string]$message 
		# note:  this is defined as the "[string]" in each call of the Log-Message function
	)
# create time stamp for each log entry.
	$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss" 
# define variable to create log entry with message Host and time stamp.
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




#### CHECK NETWORK STATUS CHANGES ####


#### Check if IPv6 is disabled ####

$adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
$ipv6Disabled = $true
$ipv6Status = Get-NetAdapterBinding -Name $adapter.Name | Where-Object { $_.ComponentID -eq 'ms_tcpip6' }


##!!!!! throwing bug here that says error if it's already disabled. 
foreach ($adapter in $adapters) {
	if ($ipv6Status.Enabled -eq $false) {
        Log-Message "IPv6 successfully disabled on adapter: $($adapter.Name)."
    } else {
        $ipv6Disabled = $false
        Log-Message "ERROR: Failed to disable IPv6 on adapter: $($adapter.Name)."
        }
    }
## !!!fix this and check on main script as well. 
	if ($ipv6Disabled) {
        Write-Host "IPv6 has been successfully disabled on all network adapters." -ForegroundColor Green
        Log-Message "IPv6 has been successfully disabled on all network adapters."
    } else {
        Write-Host "Some network adapters failed to disable IPv6." -ForegroundColor Red
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

# CHECK IF RDP IS ENABLED										  
$fDenyTSConnections = (Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server').fDenyTSConnections
if ($fDenyTSConnections -eq 0) { 
    Write-Host "Remote Desktop is enabled." -ForegroundColor Green
    Log-Message "Remote Desktop is enabled." 
} else { 
    Write-Host "Remote Desktop is still disabled. Please check settings." -ForegroundColor Red
    Log-Message "Remote Desktop is still disabled. Please check settings."
}

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

##### CHECK IF NETWORK TYPE IS PRIVATE FOR ALL ADAPTERS #####

try {
# Get all network adapters with a network connection
    $networkAdapters = Get-NetConnectionProfile
# Loop through each network adapter
    foreach ($adapter in $networkAdapters) {
        # Check if the adapter is Ethernet or Wi-Fi
        if ($adapter.InterfaceAlias -like "*Ethernet*" -or $adapter.InterfaceAlias -like "*Wi-Fi*") {
            # Check if the network profile is already set to Private
            if ($adapter.NetworkCategory -eq "Private") {
                Write-Host "Network profile for $($adapter.Name) ($($adapter.InterfaceAlias)) is already set to Private." -ForegroundColor Green
                Log-Message "Network profile for $($adapter.Name) ($($adapter.InterfaceAlias)) is already set to Private."
            } else {
                Write-Host "Network profile for $($adapter.Name) ($($adapter.InterfaceAlias)) is NOT set to Private. Current setting: $($adapter.NetworkCategory)." -ForegroundColor Red
                Log-Message "Network profile for $($adapter.Name) ($($adapter.InterfaceAlias)) is NOT set to Private. Current setting: $($adapter.NetworkCategory)."
            }
        }
    }
} catch {
    # Log failure if an error occurs
    Write-Host "An error occurred while checking network profiles: $($_.Exception.Message)" -ForegroundColor Red
    Log-Message "An error occurred while checking network profiles: $($_.Exception.Message)"
}

# End of script
Write-Host "Network status checks completed." -ForegroundColor Green
Log-Message "Network status checks completed. See above log messages for current status."


##### CHECK IF WMIC.EXE IS ENABLED AND INSTALL IF NECESSARY #####

# Check if WMIC.EXE exists in the system PATH
$wmicExists = Get-Command wmic -ErrorAction SilentlyContinue

if ($wmicExists) {
    Write-Host "WMIC.EXE is already available." -ForegroundColor Green
    Log-Message "WMIC.EXE is already available."
} else {
		Write-Host "WMIC.EXE not found. Installing..." -ForegroundColor Yellow
  try {
    # Run DISM to enable LegacyComponents (this includes WMIC)
		Add-WindowsCapability -Online -Name WMIC~~~~ #modified to use this in version 20
    # Check if the installation was successful by confirming the presence of wmic.exe again
        $wmicExists = Get-Command wmic -ErrorAction SilentlyContinue
        if ($wmicExists) {
            Write-Host "WMIC.EXE has been successfully installed." -ForegroundColor Green
            Log-Message "WMIC.EXE has been successfully installed."
        } else {
            Write-Host "ERROR: Failed to install WMIC.EXE." -ForegroundColor Red
            Log-Message "ERROR: Failed to install WMIC.EXE."
        }
    }
    catch {
        Write-Host "ERROR: An error occurred while installing WMIC.EXE: $_" -ForegroundColor Red
        Log-Message "ERROR: An error occurred while installing WMIC.EXE: $_"
    }
}


#restart time service and refresh current time to updated time zone.
	Stop-service w32time 
	Start-Service w32time
	w32tm /resync /Force
	Write-Host "restarted w32 time to sync time clock" -ForegroundColor	Green

	
#Check for missing updates for WinGet software
try {
    # Check for available updates with winget
    $updates = winget.exe upgrade --source winget --id '*' --exact --silent --accept-package-agreements --accept-source-agreements

    # If no updates are available, log the message
    if ($updates -eq $null -or $updates -eq '') {
        Write-Host "No new updates are available for Winget-based software." -ForegroundColor Green
        Log-Message "No new updates are available for Winget-based software."
    } else {
        # If updates are available, upgrade all installed software through Winget
        Write-Host "Updating all apps installed by Winget." -ForegroundColor Yellow
        winget.exe upgrade --all

        # Log success after upgrading
        Write-Host "All winget-based software upgrades installed successfully." -ForegroundColor Green
        Log-Message "All winget-based software upgrades installed successfully."
    }
} catch {
    Write-Host "Failed to update winget-based software upgrades." -ForegroundColor Red
    Log-Message "Failed to update winget-based software upgrades."
}


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
					### SYSTEM UPDATES SECTION <START> ###
########################################################################################

		 

##DELL COMMAND SECTION START.

# Define the possible directory paths for Dell Command Update
	$DCUdirPath1 = "C:\Program Files (x86)\Dell\CommandUpdate\"
	$DCUdirPath2 = "C:\Program Files\Dell\CommandUpdate\"
	$global:DCUdirPath = $null  # Initialize the unified directory path variable

# Function to check if either path exists and set $DCUdirPath
function Set-DCUPath {
    if (Test-Path $DCUdirPath1) {
        $global:DCUdirPath = $DCUdirPath1
        Write-Host "Using Dell Command Update Path: $DCUdirPath1" -ForegroundColor Green
    }
    elseif (Test-Path $DCUdirPath2) {
        $global:DCUdirPath = $DCUdirPath2
        Write-Host "Using Dell Command Update Path: $DCUdirPath2" -ForegroundColor Green
    }
    else {
        Write-Host "Dell Command Update is not installed on this system." -ForegroundColor Red
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
                Write-Host "Starting Dell Command Update scan..." -ForegroundColor Cyan
                $scanResult = & $DCUexePath /scan 2>&1
                Write-Host $scanResult -ForegroundColor Green

                # Apply updates with reboot DISabled ( PC will restart at the end of this script)
                Write-Host "Applying updates..." -ForegroundColor Cyan
                $applyResult = & $DCUexePath /applyUpdates -reboot=Disable 2>&1
                Write-Host $applyResult -ForegroundColor Cyan

                # Check for errors
                if ($scanResult -match "Error" -or $applyResult -match "Error") {
                    Write-Host "An error occurred during the update process." -ForegroundColor Red
                } else {
                    Write-Host "Dell updates completed successfully." -ForegroundColor Green
                }
            }
            catch {
                Write-Host "An unexpected error occurred with Dell Command Update: $_" -ForegroundColor Red
            }
        }
        else {
            Write-Host "Dell Command Update executable not found in $global:DCUdirPath" -ForegroundColor Red
        }
    }
    else {
		Write-Host "Dell Command Update path is not set." -ForegroundColor Red
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
		Write-Host "Checking for missing Windows Updates..." -ForegroundColor Yellow
		Get-WindowsUpdate -AcceptAll -Install -ErrorAction Stop -AutoReboot:$false
	# If updates are installed successfully, set success flag to true
		$success = $true
		Write-Host "Installed missing Windows Updates Successfully."
		Log-Message "Installed missing Windows Updates Successfully."
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
        Write-Host "Missing Windows Updates installed." -ForegroundColor Green
    }
}
catch { 
    # Log any errors during the update process
    Write-Host "ERROR: Failed to install Windows Updates. Error: $($_.Exception.Message)" -ForegroundColor Red
    Log-Message "ERROR: Failed to install Windows Updates. Error: $($_.Exception.Message)"
	
}


dism /online /cleanup-image /restorehealth
dism /online /cleanup-image /startcomponentcleanup
sfc /scannow



########################################################################################
					###		MANUAL ENTRY REQUIRED SECTION <START>		###
########################################################################################
#region


			###CHANGE COMPUTER NAME WITH MANUAL INPUT.###

	
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


########################################################################################
					###		MANUAL ENTRY REQUIRED SECTION <END>		###
########################################################################################
#endregion





# End logging to setup log file.
Log-Message "POST-setup script execution ended."

# Force reboot after 5-second delay before reboot to allow logging to finalize. 
shutdown.exe /r /f /t 5