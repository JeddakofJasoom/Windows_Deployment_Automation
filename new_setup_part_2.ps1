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


# CREATE LOG FILE AT THIS PATH:
$logFile = "C:\Sources\post_setup_log.txt"	
	# Create log file using the variable defined above.
	# Change TXT filename as needed!
New-Item -ItemType File -Path $logFile -Force | Out-Null

# CREATE CUSTOM FUNCTION TO LOG OUTPUT MESSAGES IN THIS SCRIPT:
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
Log-Message "Script execution started."	

#### CHECK NETWORK STATUS CHANGES ####

# CHECK IF IPV6 IS DISABLED:
	$adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
	$ipv6Disabled = $true
	$ipv6Status = Get-NetAdapterBinding -Name $adapter.Name | Where-Object { $_.ComponentID -eq 'ms_tcpip6' }
foreach ($adapter in $adapters) {
	if ($ipv6Status.Enabled -eq $false) {
        Log-Message "IPv6 is disabled on adapter: $($adapter.Name)."
    } else {
        Log-Message "WARNING: IPv6 is STILL ENABLED on adapter: $($adapter.Name)."
} }

# CONFIRM FIREWALL RULE
$firewallRule = Get-NetFirewallRule -DisplayName "Allow RDP Port 3389" -ErrorAction SilentlyContinue
if ($firewallRule) {
    Log-Message "Firewall rule to allow RDP on port 3389 is active."
} else {
  Log-Message "Firewall rule to allow RDP on port 3389 could not be confirmed."
}

# CHECK IF RDP IS ENABLED										  
$fDenyTSConnections = (Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server').fDenyTSConnections
if ($fDenyTSConnections -eq 0) { 
   Log-Message "Remote Desktop is enabled." 
} else { 
   Log-Message "Remote Desktop is still disabled. Please check settings."
}

# CHECK IF NETWORK TYPE IS PRIVATE FOR ALL ADAPTERS:
$networkAdapters = Get-NetConnectionProfile
foreach ($adapter in $networkAdapters) { 
	# Loop through each network adapter
	# Check if the adapter is Ethernet or Wi-Fi
if ($adapter.InterfaceAlias -like "*Ethernet*" -or $adapter.InterfaceAlias -like "*Wi-Fi*") {
		# Check if the network profile is already set to Private
		if ($adapter.NetworkCategory -eq "Private") {
			Log-Message "Network profile for $($adapter.Name) ($($adapter.InterfaceAlias)) is already set to Private."
		} else {
			Log-Message "Network profile for $($adapter.Name) ($($adapter.InterfaceAlias)) is NOT set to Private. Current setting: $($adapter.NetworkCategory)."
} } }
Log-Message "Network status checks completed. See above log messages for current status."

##### CHECK IF WMIC.EXE IS ENABLED AND INSTALL IF NECESSARY #####

# Check if WMIC.EXE exists in the system PATH
$wmicExists = Get-Command wmic -ErrorAction SilentlyContinue

if ($wmicExists) {
   Log-Message "WMIC.EXE is installed."
} else {
	Add-WindowsCapability -Online -Name WMIC~~~~ 
		Log-Message "WMIC was not installed. Pushed installation command." 
# RESYNC TIME CLOCK (forces time update to new time zone)
Stop-Service w32time
	Start-Sleep -Seconds 1
Start-Service w32time
	Start-Sleep -Seconds 1
w32tm /resync /Force 
	start-Sleep -Seconds 2
Log-Message "Synced system clock to $TimeZone" 

	
# CHECK FOR MISSING UPDATES FOR WINGET SOFTWARE
winget.exe upgrade --all
Log-Message "All Winget-based software are up to date."

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


# INSTALL WINDOWS UPDATES 

$winupdateResult = Get-WindowsUpdate -AcceptAll -Install -IgnoreReboot -ErrorAction SilentlyContinue 2>&1
	Log-Message "Installed additional Windows updates: $winupdateResult"


<#

# RUN WINDOWS UPDATE:
	# Import Windows Update PS module (needs to have PS ver 7 installed)
Import-Module PSWindowsUpdate
	# Start windows update service (if not already running)
Set-Service -Name wuauserv -StartupType Automatic
Start-Service -Name wuauserv
	# try installing windows updates, if any errors, retry updates up to 2 times and log errors:
$maxRetries = 2
$retryCount = 0
$success = $false
while (-not $success -and $retryCount -lt $maxRetries) {
    try {
        $winupdateResult = Get-WindowsUpdate -AcceptAll -Install -IgnoreReboot -ErrorAction Stop 2>&1
        Log-Message "Installed additional Windows updates: $winupdateResult"
        $success = $true
    } catch { $retryCount++
		$errorMsg = $_.Exception.Message
        Log-Message "ERROR: Failed to install Windows Updates (Attempt $retryCount of $maxRetries). Error: $errorMsg"
    if ($retryCount -lt $maxRetries) { 
        Log-Message "Retrying Windows Update again with attempt #$retryCount..."
    } else {
        Log-Message "Windows Update Installation FAILED after $retryCount attempts. Check windows updates status on next login."
} } }

#>



# End logging to setup log file.
Log-Message "POST-setup script execution ended."

# Force reboot after 5-second delay before reboot to allow logging to finalize. 
Start-Sleep -Seconds 5
Restart-Computer -Force
