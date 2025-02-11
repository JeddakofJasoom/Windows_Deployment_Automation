NETWORKING SETTINGS SECTION <START>		###
############################################################################################################################


#####Disable IPv6 on all adapters.#####
		
# Get all active (Up) network adapters
	$adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
# Loop through each adapter to disable IPv6
foreach ($adapter in $adapters) {
try {
# Disable IPv6 on network adapter
	Set-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6 -Enabled $false -ErrorAction Stop
# Log success(es). 
    Write-host "Disabling IPv6 on all network adapters." -ForegroundColor Yellow
    Write-host "Disabled IPv6 on all network adapters." -ForegroundColor Green
	}
catch {
# Log failure(s). 
    Write-Host "ERROR: Failed to disable IPv6 on the adapter: $($adapter.Name). Error: $_" -ForegroundColor Red
	}	
}


#####Set Network type to PRIVATE for all adapters (default is public).##### 
		
# Get all network adapters with a network connection
	$networkAdapters = Get-NetConnectionProfile
try { 
# Loop through each network adapter 
	foreach ($adapter in $networkAdapters){ 
	# Check if the adapter is Ethernet or Wi-Fi
		if ($adapter.InterfaceAlias -like "*Ethernet*" -or $adapter.InterfaceAlias -like "*Wi-Fi*") { 
		# change network profile to private 
			Write-Host "Setting network profile for $($adapter.Name) ($($adapter.InterfaceAlias)) to Private." -ForegroundColor Yellow
			Set-NetConnectionProfile -InterfaceIndex $adapter.InterfaceIndex -NetworkCategory Private
		}
	# log success(es)
	Write-Host "Set network profile for $($adapter.Name) ($($adapter.InterfaceAlias)) to Private." -ForegroundColor Green
	}
# log failure(s)
catch {
	Write-Error "An error occurred while setting network profiles: $($_.Exception.Message)" -ForegroundColor Red
	}




#####Configure Windows Firewalls.#####

Set-NetFirewallProfile -Profile Public, Domain, Private -Enabled True
Log-Message "Enabled ALL Firewalls"

#Add Windows Firewall rule to allow RDP with firewall on. 
try {
    Write-Host "Configuring Windows Firewall to allow RDP (port 3389) on Private and Domain profiles..." -ForegroundColor Cyan

    # Enable Remote Desktop rules only for Private and Domain profiles
    Get-NetFirewallRule -DisplayGroup "Remote Desktop" | Where-Object {
        $_.Profile -match 'Domain|Private'
    } | Enable-NetFirewallRule

    # Explicitly open port 3389 for TCP, only on Private and Domain profiles
    New-NetFirewallRule -DisplayName "Allow RDP Port 3389" `
        -Direction Inbound `
        -LocalPort 3389 `
        -Protocol TCP `
        -Action Allow `
        -Profile Domain,Private `
        -ErrorAction SilentlyContinue

	Write-Host "Port 3389 is now open on Private and Domain profiles in the firewall." -ForegroundColor Green
    Log-Message "Port 3389 is now open on Private and Domain profiles in the firewall."
	}
catch {
    Write-Host "Failed to configure the firewall: $_" -ForegroundColor Red
	Log-Message "Failed to configure the firewall: $_" 
	}

		##Enable RDP connections with network level authentication
New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -PropertyType DWORD -Value 0 -Force
New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -PropertyType DWORD -Value 1 -Force

Write-Host "Enabled RDP connections with network level authentication" -ForegroundColor Green
Log-Message "Enabled RDP connections with network level authentication"

# Define variable for checking RDP Status
$fDenyTSConnections = (Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server').fDenyTSConnections

# Check RDP status
if ($fDenyTSConnections -eq 0) {
	Write-Host "Remote Desktop is enabled." -ForegroundColor Green
    Log-Message "Remote Desktop is enabled." 
} else {
    Log-Message "Remote Desktop is still disabled. Please check settings." -ForegroundColor Yellow
}

# Confirm Firewall Rule
$firewallRule = Get-NetFirewallRule -DisplayName "Allow RDP Port 3389" -ErrorAction SilentlyContinue
if ($firewallRule) {
    Write-Host "Firewall rule to allow RDP on port 3389 is active." -ForegroundColor Green
	Log-Message "Firewall rule to allow RDP on port is active."
} else {
	Write-Host "Firewall rule to allow RDP on port could not be confirmed." -ForegroundColor Green
    Log-Message "Firewall rule to allow RDP on port could not be confirmed."
}

Log-Message "RDP Configuration Completed. Check above log messages to confirm status." -ForegroundColor Cyan


					### 	NETWORKING SETTINGS SECTION <END>		###
