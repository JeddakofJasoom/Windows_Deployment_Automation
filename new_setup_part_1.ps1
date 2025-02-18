<#
TODO: add try / catch and throw error if sources folder doesn't get copied over?? add a throw??
#>

#Trying new method of doing an auto logon through the autounattend.XML file on new load. You can run this script using the "RUNME.bat" batch file in the D:\Scripts folder. 

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

#COPY ALL CONTENTS OF D:\SCRIPTS TO C:\SOURCES :
Copy-Item -Path "$sourceFolder\*" -Destination $destinationFolder -Recurse -Force -ErrorAction Stop
	Log-Message "Copied all content from $sourceFolder folder to $destinationFolder" 
	
# DISABLE IPV6 ON ALL NETWORK ADAPTERS:
$adapters = Get-NetAdapter
foreach ($adapter in $adapters) {
	Set-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6 -Enabled $false -ErrorAction Stop
Log-Message "Disabled IPv6 on network adapter: $($adapter.Name)." }

# SET NETWORK TYPE TO PRIVATE FOR ALL ADAPTERS (DEFAULT IS PUBLIC).   
$networkAdapters = Get-NetConnectionProfile
foreach ($adapter in $networkAdapters) {# Check if the adapter is Ethernet or Wi-Fi
if ($adapter.InterfaceAlias -like "*Ethernet*" -or $adapter.InterfaceAlias -like "*Wi-Fi*") {
Set-NetConnectionProfile -InterfaceIndex $adapter.InterfaceIndex -NetworkCategory Private 
	Log-Message "Set network profile for $($adapter.Name) ($($adapter.InterfaceAlias)) to Private." }}

#ENABLE ALL WINDOWS FIREWALLS.
Set-NetFirewallProfile -Profile Public, Domain, Private -Enabled True
	Log-Message "Enabled ALL Firewalls"
	
# ADD WINDOWS FIREWALL RULE TO ALLOW RDP WITH FIREWALL ON.
	# Explicitly open port 3389 for TCP, only on Private and Domain profiles:
Get-NetFirewallRule -DisplayGroup "Remote Desktop" | Where-Object { $_.Profile -match 'Domain|Private' } | Enable-NetFirewallRule
New-NetFirewallRule -DisplayName "Allow RDP Port 3389" `
	-Direction Inbound `
	-LocalPort 3389 `
	-Protocol TCP `
	-Action Allow `
	-Profile Domain,Private `
	-ErrorAction SilentlyContinue
Log-Message "Created new firewall rule to allow Port 3389 (RDP) on Private and Domain profiles in Windows Firewall."

# ENABLE RDP CONNECTIONS
	New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -PropertyType DWORD -Value 0 -Force
# REQUIRE NETWORK LEVEL AUTHENTICATION
	New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -PropertyType DWORD -Value 1 -Force
Log-Message "Enabled RDP connections with network level authentication required"

# SET THE POWER SCHEME TO HIGH PERFORMANCE (PREDEFINED GUID)
powercfg.exe /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
powercfg -x standby-timeout-ac 0   # Disables sleep when on AC power
powercfg -x standby-timeout-dc 0   # Disables sleep when on battery power
powercfg -x monitor-timeout-ac 20  # Turns off display after 20 minutes on AC power
powercfg -x monitor-timeout-dc 20  # Turns off display after 20 minutes on battery power
powercfg -x hibernate-timeout-ac 0 # Disables hibernate when on AC power
powercfg -x hibernate-timeout-dc 0 # Disables hibernate when on battery power

# SET THE BOOT MENU TIMEOUT TO 5 SECONDS (gives us time to enter bios easily)
bcdedit.exe /timeout 5
	Log-Message "Boot menu timeout successfully set to 5 seconds."
	

# ENABLE AUTOMATIC REBOOT AFTER SYSTEM FAILURE
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "AutoReboot" -Value 1 -ErrorAction Stop
	Log-Message "AutoReboot after system failure has been successfully enabled."

# SET NUMLOCK TO ALWAYS ON
Set-ItemProperty -Path "Registry::HKEY_USERS\.DEFAULT\Control Panel\Keyboard" -Name "InitialKeyboardIndicators" -Value "2" 
	Log-Message "Set Numlock to always on"

# SET DEBUGGING INFORMATION TYPE TO NONE
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "CrashDumpEnabled" -Value 0 -ErrorAction Stop
	Log-Message "Debugging information type has been set to None."

# SET TIMEZONE TO EASTERN TIME
	# **Uncomment next line for central time:
	#$TimeZone = "Central Standard Time" 
$TimeZone = "Eastern Standard Time" 
Set-TimeZone -Id "$TimeZone"
	Log-Message "Time zone has been set to $TimeZone"

# RESYNC TIME CLOCK (forces time update to new time zone)
Stop-Service w32time
	Start-Sleep -Seconds 1
Start-Service w32time
	Start-Sleep -Seconds 1
w32tm /resync /Force 
	start-Sleep -Seconds 2
Log-Message "Synced system clock to $TimeZone" 

# INSTALL 'NUGET' PACKAGE FROM MICROSOFT 
	Log-Message "Installing latest version of 'NuGet' package from Microsoft"
$ConfirmPreference = 'None'	# Suppress any confirmation prompts
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

# INSTALL PS MODULE TO ALLOW POWERSHELL 7 TO RUN WINDOWS UPDATE.#
Install-Module PSWindowsUpdate -Force -Wait
Log-Message "Installed Powershell Module 'PSWindowsUpdate' to enable Windows Updates through Powershell"

# UPDATE WINDOWS DEFENDER WITH POWERSHELL
Update-MpSignature
Log-Message "AV signature definitions updated." 

# RESTART WINDOWS UPDATE 
Set-Service -Name wuauserv -StartupType Automatic -Status running

# INSTALL WINDOWS UPDATES!!!
$winupdateResult = Get-WindowsUpdate -AcceptAll -Install -IgnoreReboot -ErrorAction Continue 2>&1
	Log-Message "Installed additional Windows updates: $winupdateResult"

### SETS AUTO LOGIN AS ".\ITNGAdmin" ON NEXT LOGIN
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WinLogon"
Set-ItemProperty -Path $RegPath -Name "DefaultDomainName" -Value ""
Set-ItemProperty -Path $RegPath -Name "DefaultUsername" -Value ".\ITNGAdmin"
Set-ItemProperty -Path $RegPath -Name "DefaultPassword" -Value "password"
Set-ItemProperty -Path $RegPath -Name "AutoAdminLogon" -Value "1"Set-ItemProperty -Path $RegPath -Name "ForceAutoLogon" -Value "1"

### RUN NEW_SETUP_PART_2.PS1 ON NEXT LOGON
$ScriptPath = "C:\Sources\new_setup_part_2.ps1"  # UPDATE TO NEXT SCRIPT NUMBER
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$ScriptCommand = "powershell.exe -ExecutionPolicy Bypass -File `"$ScriptPath`""
Set-ItemProperty -Path $RegPath -Name "AutoRunScript" -Value $ScriptCommand

# REBOOT PC 
Write-Host "Windows updates are installed and require reboot. Rebooting PC in 5 seconds..." -ForegroundColor Red
Log-Message "End of Part 1 setup script."
Start-Sleep -Seconds 5 #wait 5 seconds to complete logging
Restart-Computer -force