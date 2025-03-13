# new setup part 1


Write-Host "Starting 'New setup part 1' in 10 seconds... Please do not interact with the screen as this script is automated to reboot." -ForegroundColor Yellow
	Start-Sleep -Seconds 10

# PREVENTS SCREEN FROM LOCKING ON AUTO LOGIN TO MONITOR RUNNING SCRIPT PROCESSES:
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows" -Name "Personalization" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreen" -Value "1" -ErrorAction SilentlyContinue
Write-Host "Set registry keys to disable screen lock while running updates to monitor progress." -Foregroundcolor Green
	Start-Sleep -Seconds 2



# CREATE LOCAL SOURCES FOLDER FOR INSTALLATION AND LOGGING:
	# Define folders for holding the installers, scripts, and log files. 
$sourceFolder = "D:\Scripts" 
$destinationFolder = "C:\Sources"

# CREATE "C:\SOURCES\" DIRECTORY 
	# Note: used to store setup log files, application installers, and scripts as needed. 
if (-not (Test-Path $destinationFolder)) {	
New-Item -Path $destinationFolder -ItemType Directory
	Write-Host "Created new 'Sources' folder at: $destinationFolder" -ForegroundColor Yellow }

# CREATE LOG FILE AT THIS PATH:
$logFile = "C:\Sources\New_Setup_LOG.txt"
New-Item -ItemType File -Path $logFile -Force | Out-Null
	Write-Host "New setup log file created at $logFile. Remember to check your setup log file: '$logFile' after reboot to see what has been done!" -ForegroundColor Green

# CREATE CUSTOM FUNCTION TO LOG OUTPUT MESSAGES IN THIS SCRIPT.
function Log-Message { 
param ( [string]$message, [string]$displayMessage )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $message"
if ($displayMessage) {
    Write-Host "$displayMessage`n$logEntry" -ForegroundColor Yellow
} else {
   Write-Host "$logEntry" -ForegroundColor Yellow
}  Add-Content -Path $logFile -Value $logEntry }
	# Start Logging:
	Log-Message "New Setup Part 1 Script has started."	

# COPY ALL CONTENTS OF D:\SCRIPTS TO C:\SOURCES :
try {
Copy-Item -Path "$sourceFolder\*" -Destination $destinationFolder -Recurse -Force -ErrorAction Stop
	Log-Message "Copied all content from $sourceFolder folder to $destinationFolder"
} catch {
	Log-Message "WARNING: Failed to copy installation scripts from $sourceFolder to $destinationFolder! The scripts will NOT continue to run without this folder being present! YOU MUST REVIEW!" 
}


# REMOVE CURRENT REG KEY for NEW_SETUP_PART_0.PS1
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
Remove-Item -Path $RegPath  
	Log-Message "Removed registry key to run part 0 script."
Start-Sleep -Seconds 2


# RUN NEW_SETUP_PART_2.PS1 ON NEXT LOGON
New-Item -path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion" -name "RunOnce" -Force
$ScriptPath = "C:\Sources\new_setup_part_2.ps1"  # UPDATE TO NEXT SCRIPT NUMBER
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
$ScriptCommand = "powershell.exe -ExecutionPolicy Bypass -File `"$ScriptPath`" -Verb RunAs"
Set-ItemProperty -Path $RegPath -Name "AutoRunScript" -Value $ScriptCommand
	Log-Message "Set registry key to run setup part 2 on next logon." 
Start-Sleep -Seconds 2

# SET THE POWER SCHEME TO HIGH PERFORMANCE (PREDEFINED GUID)
powercfg.exe /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
powercfg -x standby-timeout-ac 0   # Disables sleep when on AC power
powercfg -x standby-timeout-dc 0   # Disables sleep when on battery power
powercfg -x monitor-timeout-ac 20  # Turns off display after 20 minutes on AC power
powercfg -x monitor-timeout-dc 20  # Turns off display after 20 minutes on battery power
powercfg -x hibernate-timeout-ac 0 # Disables hibernate when on AC power
powercfg -x hibernate-timeout-dc 0 # Disables hibernate when on battery power

# INSTALL 'NUGET' PACKAGE FROM MICROSOFT 
	#Note: NuGet is Microsoft's package manager for .NET, primarily used to manage dependencies in .NET applications
Log-Message "Installing latest version of 'NuGet' package from Microsoft"
$ConfirmPreference = 'None'	# Suppress any confirmation prompts
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

# INSTALL PS MODULE TO ALLOW POWERSHELL 7 TO RUN WINDOWS UPDATE.#
Install-Module PSWindowsUpdate -Force
Log-Message "Installed Powershell Module 'PSWindowsUpdate' to enable Windows Updates through Powershell"

# INSTALL WINDOWS UPDATES 
Log-Message "Beginning Windows updates installation. System will monitor progress and reboot when required. Please see progress bar at the top of the screen."  
$winupdateResult = Get-WindowsUpdate -AcceptAll -Install -IgnoreReboot -ErrorAction Continue 2>&1 | Out-String
	Log-Message "Installed additional Windows updates: `n$winupdateResult"
Start-Sleep -Seconds 60 

function Force-RestartAfterUpdates {
    Write-Host "Monitoring Windows Update installation..." -ForegroundColor Cyan
$UpdatesPending = $true
    while ($UpdatesPending) {
        # Check if a reboot is required after updates
       # Check for updates
    if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") {
        $UpdatesPending = $false  # Stop the loop
		# PRINT TO SCREEN 10 SECOND COUNTDOWN AND FORCE REBOOT PC. 
		Write-Host "Windows Updates are installed and require reboot. Rebooting PC in 10 seconds..." -ForegroundColor Red
		Start-Sleep -Seconds 10 
        Restart-Computer -Force
        break
    }
    else {
            Write-Host "Updates are still installing... Checking again in 30 seconds." -ForegroundColor Yellow
            Start-Sleep -Seconds 30
        }
    }
}
#run function: 
Force-RestartAfterUpdates