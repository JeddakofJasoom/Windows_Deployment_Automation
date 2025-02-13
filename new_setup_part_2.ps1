<#
TODO: windows updates again
TODO: dell command 

TODO: change multi setup log to append to 1 long setup log??? 
TODO: remove previous reg key to run the previous script
TODO: add reg key to run new_setup_part_3.ps1 on next login
TODO: add reg key to auto login as admin account 

#>



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
Log-Message "New Setup Part 2 Script has started here."


		#### CHECK NETWORK STATUS CHANGES ####

# CHECK IF IPV6 IS DISABLED:
	$adapters = Get-NetAdapter
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
if ($adapter.InterfaceAlias -like "*Ethernet*" -or $adapter.InterfaceAlias -like "*Wi-Fi*") {
		# Check if the network profile is already set to Private
	if ($adapter.NetworkCategory -eq "Private") {
		Log-Message "Network profile for $($adapter.Name) ($($adapter.InterfaceAlias)) is already set to Private."
	} else {
		Log-Message "Network profile for $($adapter.Name) ($($adapter.InterfaceAlias)) is NOT set to Private. Current setting: $($adapter.NetworkCategory)."
} } }
Log-Message "Network status checks completed. See above log messages for current status."


# Check if WMIC.EXE exists in the system PATH
$wmicExists = Get-Command wmic -ErrorAction SilentlyContinue
if ($wmicExists) {
   Log-Message "WMIC.EXE is installed."
} else {
	Add-WindowsCapability -Online -Name WMIC~~~~ 
	Log-Message "WMIC was not installed. Pushed installation command." 
}

# CHECK FOR MISSING UPDATES FOR WINGET SOFTWARE
winget.exe upgrade --all
Log-Message "All Winget-based software are up to date."


#SET ACTIVE POWER PLAN:
powercfg.exe /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c


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


####### need to add reg key to run new_setup_part_2.ps1 on next logon
####### need to add reg key to auto login as admin on next login


# REBOOT PC 
Write-Host "Windows updates are installed and require reboot. Rebooting PC in 5 seconds..." -ForegroundColor Red
Log-Message "End of Part 2 setup script."
Start-Sleep -Seconds 5 #wait 5 seconds to complete logging
Restart-Computer -force