<#
TODO: add try / catch and throw error if sources folder doesn't get copied over?? add a throw??
TODO: check windows updates stops with admin PS script from answer file
TODO: update script overflow list for part 1
#>

#Trying new method of doing an auto logon through the autounattend.XML file on new load. If it does not load, you can manually run this script using the "RUNME.bat" batch file in the D:\Scripts folder. 

############ START CUSTOM LOGIN SCRIPT ############


# STOP WINDOWS UPDATE SERVICE (temporarily)
Set-Service -Name wuauserv -StartupType Disabled -Status stopped

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

### SETS AUTO LOGIN AS ".\ITNGAdmin" ON NEXT LOGIN
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WinLogon"
Set-ItemProperty -Path $RegPath -Name "DefaultDomainName" -Value ""
Set-ItemProperty -Path $RegPath -Name "DefaultUsername" -Value ".\ITNGAdmin"
Set-ItemProperty -Path $RegPath -Name "DefaultPassword" -Value "password"
Set-ItemProperty -Path $RegPath -Name "AutoAdminLogon" -Value "1"
Set-ItemProperty -Path $RegPath -Name "ForceAutoLogon" -Value "1"
	# prevents screen from locking on auto login to monitor running script processes:
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows" -Name "Personalization" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreen" -Value "1"
	Log-Message "Set registry keys to force auto login with ITNGAdmin account on next logon."
Start-Sleep -Seconds 1

### RUN NEW_SETUP_PART_2.PS1 ON NEXT LOGON
New-Item -path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion" -name "RunOnce" -Force
$ScriptPath = "C:\Sources\new_setup_part_2.ps1"  # UPDATE TO NEXT SCRIPT NUMBER
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
$ScriptCommand = "powershell.exe -ExecutionPolicy Bypass -File `"$ScriptPath`" -Verb RunAs"
Set-ItemProperty -Path $RegPath -Name "AutoRunScript" -Value $ScriptCommand
	Log-Message "Set registry key to run setup part 2 on next logon." 
Start-Sleep -Seconds 1

#COPY ALL CONTENTS OF D:\SCRIPTS TO C:\SOURCES :
Copy-Item -Path "$sourceFolder\*" -Destination $destinationFolder -Recurse -Force -ErrorAction Stop
	Log-Message "Copied all content from $sourceFolder folder to $destinationFolder" 

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

# RESTART WINDOWS UPDATE 
Set-Service -Name wuauserv -StartupType Automatic -Status running
Log-Message "Restarting Windows Update Service."

# INSTALL WINDOWS UPDATES!!!
	Log-Message "Running: Windows Updates Installation"
$winupdateResult = Get-WindowsUpdate -AcceptAll -Install -IgnoreReboot -ErrorAction Continue 2>&1
	Log-Message "Installed additional Windows updates: $winupdateResult"

### SETS AUTO LOGIN AS ".\ITNGAdmin" ON NEXT LOGIN
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WinLogon"
Set-ItemProperty -Path $RegPath -Name "DefaultDomainName" -Value ""
Set-ItemProperty -Path $RegPath -Name "DefaultUsername" -Value ".\ITNGAdmin"
Set-ItemProperty -Path $RegPath -Name "DefaultPassword" -Value "password"
Set-ItemProperty -Path $RegPath -Name "AutoAdminLogon" -Value "1"
Set-ItemProperty -Path $RegPath -Name "ForceAutoLogon" -Value "1"
	# prevents screen from locking on auto login to monitor running script processes:
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows" -Name "Personalization" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreen" -Value "1"
	Log-Message "Ran second pass to set registry keys to force auto login with ITNGAdmin account on next logon - ignore any errors on screen."

### RUN NEW_SETUP_PART_2.PS1 ON NEXT LOGON
New-Item -path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion" -name "RunOnce" -Force
$ScriptPath = "C:\Sources\new_setup_part_2.ps1"  # UPDATE TO NEXT SCRIPT NUMBER
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
$ScriptCommand = "powershell.exe -ExecutionPolicy Bypass -File `"$ScriptPath`" -Verb RunAs"
Set-ItemProperty -Path $RegPath -Name "AutoRunScript" -Value $ScriptCommand
	Log-Message "Ran second pass to set registry key to run setup part 2 on next logon - ignore any errors on screen." 

# REBOOT PC 
Write-Host "Windows updates are installed and require reboot. Rebooting PC in 5 seconds..." -ForegroundColor Red
Log-Message "End of Part 1 setup script."
Start-Sleep -Seconds 5 #wait 5 seconds to complete logging
Restart-Computer -force