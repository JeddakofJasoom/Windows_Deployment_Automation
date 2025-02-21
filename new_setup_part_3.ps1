<#
TODO: !!! check the part 4 script runs as admin properly, had issue last test. 
TODO: bloatware removal - check with David if missing anything or need to truncate at all
TODO: add default user profile XML ...? pull from completed test machine and try in separate script first. 
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
Log-Message "~~~~~"
Log-Message "New Setup Part 3 Script has started here."

### REMOVE CURRENT REG KEY for NEW_SETUP_PART_3.PS1
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
Remove-Item -Path $RegPath  
	Log-Message "Removed registry key to run part 3 script."
Start-Sleep -Seconds 1

### RUN NEW_SETUP_PART_4.PS1 ON NEXT LOGON
New-Item -path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion" -name "RunOnce" -Force
$ScriptPath = "C:\Sources\new_setup_part_4.ps1"  # UPDATE TO NEXT SCRIPT NUMBER
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
$ScriptCommand = "powershell.exe -ExecutionPolicy Bypass -File `"$ScriptPath`" -Verb RunAs"
Set-ItemProperty -Path $RegPath -Name "AutoRunScript" -Value $ScriptCommand


###user profile settings change: 

	# DISABLE WIDGETS
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft" -Name "Dsh"
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -Value 0 -Force
	# DISABLE TASKVIEW
New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -PropertyType DWORD -Value 0 -Force
	# DISABLE THE RANDOM ICON LINKS IN WINDOWS SEARCH
New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows" -Name "Windows Search"
	# TASKBAR ALIGN TO LEFT 
New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -PropertyType DWORD -Value 0 -Force
	# REMOVE "COPILOT" FOR ALL USERS
Get-AppxPackage -AllUsers "Microsoft.Copilot" | Remove-AppxPackage -AllUsers
	# REMOVE "OUTLOOK (NEW)" FOR ALL USERS
Get-AppxPackage -AllUsers "Microsoft.OutlookForWindows" | Remove-AppxPackage -AllUsers
	# SET NUMLOCK TO ALWAYS ON
Set-ItemProperty -Path "Registry::HKEY_USERS\.DEFAULT\Control Panel\Keyboard" -Name "InitialKeyboardIndicators" -Value "2" 
	# DISABLE 'WEB SEARCH RESULTS' IN WINDOWS SEARCH 
New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion" -name "Explorer" 
New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "DisableSearchBoxSuggestions" -PropertyType DWORD -Value 1 -Force
	# SET DEFAULT APPS:
	<#  .html = Chrome
		.pdf = Adobe
		mailto = OUTLOOK
		.eml = OUTLOOK
	#>
dism /online /Import-DefaultAppAssociations:C:\Sources\DefaultAppAssociations.xml

# UPDATE WINDOWS DEFENDER WITH POWERSHELL
Update-MpSignature
Log-Message "AV signature definitions updated." 

# RUN DELL COMMAND UPDATE
cd "c:\program files (x86)\Dell\CommandUpdate\"
& ".\dcu-cli.exe" /scan 
Log-Message "Installing available Dell updates..."
& ".\dcu-cli.exe" /ApplyUpdates -reboot=Disable
	Log-Message "Dell Command updates installed." 
	
# REBOOT PC 
Write-Host "Dell Command Updates are installed and require reboot. Rebooting PC in 5 seconds..." -ForegroundColor Red
Log-Message "End of Part 3 setup script."
Start-Sleep -Seconds 5 #wait 5 seconds to complete logging
Restart-Computer -force