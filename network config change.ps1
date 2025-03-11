

#REMOVES GPO TO DISABLE WIN FIREWALL AND REENABLES THEM:
secedit /configure /cfg %windir%\inf\defltbase.inf /db defltbase.sdb /verbose
netsh advfirewall reset
Set-NetFirewallProfile -Profile Public, Domain, Private -Enabled True

# DISABLE IPV6 ON ALL NETWORK ADAPTERS:
$adapters = Get-NetAdapter
foreach ($adapter in $adapters) {
try {
	Set-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6 -Enabled $false -ErrorAction SilentlyContinue
Write-Host "Disabled IPv6 on network adapter: $($adapter.Name)." 
} catch {
# Log failure(s). 
    Write-Host "ERROR: Failed to disable IPv6 on the adapter: $($adapter.Name). Error: $_" -ForegroundColor Red
	}	
}

# SET NETWORK TYPE TO PRIVATE FOR ALL ADAPTERS (DEFAULT IS PUBLIC).   
$networkAdapters = Get-NetConnectionProfile
foreach ($adapter in $networkAdapters) {# Check if the adapter is Ethernet or Wi-Fi
if ($adapter.InterfaceAlias -like "*Ethernet*" -or $adapter.InterfaceAlias -like "*Wi-Fi*") {
Set-NetConnectionProfile -InterfaceIndex $adapter.InterfaceIndex -NetworkCategory Private 
	Write-Host "Set network profile for $($adapter.Name) ($($adapter.InterfaceAlias)) to Private." }
}

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
Write-Host "Created new firewall rule to allow Port 3389 (RDP) on Private and Domain profiles in Windows Firewall."

# ENABLE RDP CONNECTIONS
New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -PropertyType DWORD -Value 0 -Force
# REQUIRE NETWORK LEVEL AUTHENTICATION
New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -PropertyType DWORD -Value 1 -Force
	Write-Host "Enabled RDP connections with network level authentication required"
