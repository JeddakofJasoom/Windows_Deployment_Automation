

########################################################################################
				############ START ITNG CUSTOM LOGIN SCRIPT ############
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