$sources = D:\sources

cd $sources

# Setup PSWindowsUpdate - HAS to be on *new* w11 23H2 machine to work 
Set-ExecutionPolicy unrestricted -Force
Install-PackageProvider -name NuGet -Minimumversion 2.8.5.201 -Force
Install-Module PSWindowsUpdate -Force
Write-Output "PSwindows update complete"

# Fix WinGet
Add-AppPackage -path .\Microsoft.UI.Xaml.2.8.appx
Add-AppPackage -ForceApplicationShutdown .\winget.msixbundle
Write-Output "Winget is fixed"

# Set TimeZone to Eastern Time
Set-TimeZone -Name "Eastern Standard Time"
Write-Output "EST time zone set"

# Disable Windwos Firewalls
# Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled False
Write-output "did NOT disable Firewalls"


# Set active power plan
powercfg.exe /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
powercfg -x standby-timeout-ac 0 #disables sleep on charger/power brick"
powercfg -x standby-timeout-dc 0 #disables sleep on battery power for laptops"
powercfg -x monitor-timeout-ac 20 #sets display to turn off after 20 minutes on charger/power brick"
powercfg -x monitor-timeout-dc 20 #sets display to turn off after 20 minutes on battery power for laptops"
powercfg -x hibernate-timeout-ac 0 #disables hibernate on charger/power brick"
powercfg -x hibernate-timeout-dc 0 #disables hibernate on battery power for laptops"\
Write-Output "set power configuration settings"

# Enable Remote Assistance
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance" `
-name "fAllowToGetHelp" `
-PropertyType DWORD -Value 1 -Force
Write-Output "Enabled Remote Assistance"

# Enable RDP connections without network level authentication
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" `
-Name "UserAuthentication" -Value 0 
#note: do not use a propertype switch here - it will break the command. 
#note: 0 turns on allowed RDP connections AND turns off NLA requirement. 
#note: 2 turns OFF RDP connections entirely. 
Write-Output "Enabled RDP connections without network level authentication"


# Enable Remote Desktop Connection for a *specific server*
# New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\<name of server>" `
# -Name "fDenyTSConnections" -PropertyType DWORD -Value 0 -Force
#
# New-itemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\<name of server>\WinStations\RDP-Tcp" `
# -Name "UserAuthentication" `
# -PropertyType DWORD -Value 1 -Force 

# Set system startup entries - the boot menu will not be displayed, and the default operating system will boot immediately without delay.
bcdedit.exe /Timeout 0
Write-Output "system startup set to boot immediately into Windows"

# System failure options
wmic.exe recoveros set AutoReboot = True #enables the automatic reboot feature after a system failure (BSOD).
wmic.exe recoveros set DebugInfoType = 0 #sets the type of debugging information written to the disk when the system crashes. A value of 0 indicates that no debugging information will be written.

# Update AV Definitions
Update-MpSignature
Write-Output "AV signature definitions update completed successfully"

# Run WinGet for basic applications 
winget.exe install microsoft.powershell
Write-Output "Powershell 7 installed successfully."
winget.exe install Google.Chrome --scope machine
Write-Output "Google Chrome installed successfully."
winget.exe install Mozilla.Firefox
Write-Output "Firefox installed successfully."
winget.exe install adobe.acrobat.reader.64-bit
Write-Output "Adobe Reader installed successfully."
winget.exe upgrade --all
Write-Output "All software upgrades installed successfully."

# Run Windows Update
Get-WindowsUpdate -AcceptAll -Install -AutoReboot
Write-Output "Starting Windows Updates and will Automatically reboot the machine when complete.
