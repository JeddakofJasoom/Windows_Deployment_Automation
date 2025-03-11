<# 
TODO: update script overflow list for part 1
#>

Start-Sleep -Seconds 10

# CREATE CUSTOM FUNCTION TO LOG OUTPUT MESSAGES IN THIS SCRIPT:

$logFile = "C:\Sources\New_Setup_LOG.txt"
function Log-Message { 
param ( [string]$message, [string]$displayMessage )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $message"
if ($displayMessage) {
    Write-Host "$displayMessage`n$logEntry" -ForegroundColor Yellow
} else {
   Write-Host "$logEntry" -ForegroundColor Yellow
}  Add-Content -Path $logFile -Value $logEntry }
	# START LOGGING:
Log-Message "~~~~~"
Log-Message "New Setup Part 2 Script has started here."

### REMOVE NEW_SETUP_PART_2.PS1 reg key 
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
Remove-Item -Path $RegPath 
	Log-Message "Removed registry key to run part 2 script."
Start-Sleep -Seconds 1
	
### RUN NEW_SETUP_PART_3.PS1 ON NEXT LOGON
New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion" -name "RunOnce"
$ScriptPath = "C:\Sources\new_setup_part_3.ps1"  # UPDATE TO NEXT SCRIPT NUMBER
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
$ScriptCommand = "powershell.exe -ExecutionPolicy Bypass -File `"$ScriptPath`" -Verb RunAs"
Set-ItemProperty -Path $RegPath -Name "AutoRunScript" -Value $ScriptCommand

#SET ACTIVE POWER PLAN:
powercfg.exe /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

# DISABLE IPV6 ON ALL NETWORK ADAPTERS:
$adapters = Get-NetAdapter
foreach ($adapter in $adapters) {
	Set-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6 -Enabled $false -ErrorAction SilentlyContinue
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

# SET THE BOOT MENU TIMEOUT TO 5 SECONDS (gives us time to enter bios easily)
bcdedit.exe /timeout 5
	Log-Message "Boot menu timeout successfully set to 5 seconds."

# ENABLE AUTOMATIC REBOOT AFTER SYSTEM FAILURE
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "AutoReboot" -Value 1 -ErrorAction Stop
	Log-Message "AutoReboot after system failure has been successfully enabled."

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


# INSTALL WMIC.EXE (deprecated in 24H2) 
Log-Message "Installing WMIC.exe - this will take several minutes." 
Add-WindowsCapability -Online -Name WMIC~~~~ 

# INSTALL *STANDARD* APPLICATIONS USING 'WinGet'
	Log-Message "Running 'WinGet' to install standard software applications."
# INSTALL POWERSHELL 7 
winget.exe install Microsoft.Powershell --scope machine --silent --accept-source-agreements
winget.exe install Google.Chrome --scope machine --silent --accept-source-agreements
winget.exe install Dell.CommandUpdate --scope machine --silent --accept-source-agreements
winget.exe install Adobe.Acrobat.Reader.64-bit --scope machine --silent --accept-source-agreements


# CHECK FOR MISSING UPDATES FOR WINGET SOFTWARE
	Log-Message "Checking for available software updates through WinGet. See output below:"
winget.exe upgrade --all
	Log-Message "All Winget-based software are up to date."

# INSTALL OFFICE 365
	# Note: needs the additional parameters to prevent GUI popup. 
	$sources = "C:\Sources"
	$Office365InstallPath = "$sources\OfficeSetup.exe"
	$configurationFilePath = "$sources\O365Configuration.xml"
	$arguments = "/configure $configurationFilePath"
Start-Process -FilePath $Office365InstallPath -ArgumentList $arguments -Wait

# INSTALL WINDOWS UPDATES 
$winupdateResult = Get-WindowsUpdate -AcceptAll -Install -IgnoreReboot -ErrorAction Continue 2>&1 | Out-String
	Log-Message "Installed additional Windows updates: `n$winupdateResult"

# REBOOT PC 
Write-Host "Windows Updates 2nd pass installed along with standard system settings changed. Rebooting PC in 5 seconds..." -ForegroundColor Red
Log-Message "End of Part 2 setup script."
Start-Sleep -Seconds 5 #wait 5 seconds to complete logging
Restart-Computer -force