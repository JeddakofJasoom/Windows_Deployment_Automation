### Networking Settings Section START ###


#Disable IPv6 on all adapters
	# Get all active (Up) network adapters
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
	# Loop through each adapter to disable IPv6
foreach ($adapter in $adapters) {
    try {
        Set-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6 -Enabled $false -ErrorAction Stop
        Write-host "Disabling IPv6 on all network adapters."
    }
    catch {
        Write-Host "ERROR: Failed to disable IPv6 on the adapter: $($adapter.Name). Error: $_" -ForegroundColor Red
    }
}


# Set Network type to PRIVATE (default is public). 
	# Get all network adapters with a network connection
$networkAdapters = Get-NetConnectionProfile
foreach ($adapter in $networkAdapters) {
    # Check if the adapter is Ethernet or Wi-Fi
    if ($adapter.InterfaceAlias -like "*Ethernet*" -or $adapter.InterfaceAlias -like "*Wi-Fi*") {
        Write-Host "Setting network profile for $($adapter.Name) ($($adapter.InterfaceAlias)) to Private."
        Set-NetConnectionProfile -InterfaceIndex $adapter.InterfaceIndex -NetworkCategory Private
    }
}


# Configure Windows Firewalls
Set-NetFirewallProfile -Profile Public, Domain, Private -Enabled True


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
	}
catch {
    Write-Host "Failed to configure the firewall: $_" -ForegroundColor Red
	}

##Enable RDP connections with network level authentication
New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -PropertyType DWORD -Value 0 -Force
New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -PropertyType DWORD -Value 1 -Force

Write-Host "Enabled RDP connections with network level authentication" -ForegroundColor Green

# Define variable for checking RDP Status
$fDenyTSConnections = (Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server').fDenyTSConnections

# Check RDP status
if ($fDenyTSConnections -eq 0) {
	Write-Host "Remote Desktop is enabled." -ForegroundColor Green
} else {
    Write-Host "Remote Desktop is still disabled. Please check settings." -ForegroundColor Yellow
}

# Confirm Firewall Rule
$firewallRule = Get-NetFirewallRule -DisplayName "Allow RDP Port 3389" -ErrorAction SilentlyContinue
if ($firewallRule) {
    Write-Host "Firewall rule to allow RDP on port 3389 is active." -ForegroundColor Green
} else {
	Write-Host "Firewall rule to allow RDP on port could not be confirmed." -ForegroundColor Green
}




### Power Settings Section START ###


# Set active power plan:

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


			### Power Settings Section END ###


################################################################################


			### Misc section START ###


# Set system startup entries - the boot menu will not be displayed, and the default operating system will boot immediately without delay.
try {
		# Set the boot menu timeout to 5 seconds (gives us time to enter BIOS easily)
    bcdedit.exe /timeout 5
		# Log success
    Write-Host "Boot menu timeout successfully set to 5 seconds." -ForegroundColor Green
}
catch {
		# Log failure
   Write-Host "ERROR: Failed to set the boot menu timeout. Error: $_" -ForegroundColor Red
}

	
# Install wmic.exe commands
Write-Host "Installing WMIC.EXE..." -ForegroundColor Cyan
try {
	dism /online /enable-feature /featurename:LegacyComponents /all
	
	Write-Host "Installed WMIC.EXE successfully." -ForegroundColor Green
}
catch {
	Write-Host "FAILED to install WMIC.EXE." -ForegroundColor Red
}
	<# notes on using dism to install wmic.exe:
	: 24H2 deprecates this and is no longer installed by default.
	: We have RMM components and scripts that still use wmic.exe instead of the newer powershell.
	: This requires a system restart to fully install.
	: All wmic.exe commands are replaced with powershell commands in this script. 
	#> 
	
# System failure options

try { # Enable automatic reboot after system failure
	    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "AutoReboot" -Value 1 -ErrorAction Stop
		# Log success 
	Write-Host "AutoReboot after system failure has been successfully enabled." -ForegroundColor Green
}
catch { # Log failure
	Write-Host "ERROR: Failed to enable AutoReboot after system failure. Error: $_" -ForegroundColor Red
}

try { # Set debugging information type to None
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "CrashDumpEnabled" -Value 0 -ErrorAction Stop
		# Log success 
	Write-Host "Debugging information type has been set to None." -ForegroundColor Green
}
catch { # Log failure
	Write-Host "ERROR: Failed to set DebugInfoType to None. Error: $_" -ForegroundColor Red
}