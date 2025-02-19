<#
TODO: add bloatware removal 
TODO: add default user profile XML 
TODO: add user profile base change reg keys (TEST FIRST!)
TODO: - add spacer in it for section??
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
Log-Message "New Setup Part 3 Script has started here."


###user profile settings change: 

# DISABLE WIDGETS
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft" -Name "Dsh"
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -PropertyType DWORD -Value 0 -Force
# DISABLE TASKVIEW
New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -PropertyType DWORD -Value 0 -Force
# DISABLE THE RANDOM ICON LINKS IN WINDOWS SEARCH
New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows" -Name "Windows Search"
# TASKBAR ALIGN TO LEFT 
New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -PropertyType DWORD -Value 0 -Force
# REMOVE "COPILOT" FOR ALL USERS
Get-AppxPackage -AllUsers "Microsoft.Copilot" | Remove-AppxPackage
# REMOVE "OUTLOOK (NEW)" FOR ALL USERS
Get-AppxPackage -AllUsers "Microsoft.OutlookForWindows" | Remove-AppxPackage
# SET NUMLOCK TO ALWAYS ON
Set-ItemProperty -Path "Registry::HKEY_USERS\.DEFAULT\Control Panel\Keyboard" -Name "InitialKeyboardIndicators" -Value "2" 
# DISABLE 'WEB SEARCH RESULTS' IN WINDOWS SEARCH 
New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows" -name "Explorer" 
New-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -PropertyType DWORD -Value 1 -Force

# RUN DELL COMMAND UPDATE
cd "c:\program files (x86)\Dell\CommandUpdate\"
& ".\dcu-cli.exe" /scan 
$applyResult = & ".\dcu-cli.exe" /ApplyUpdates -reboot=Disable 2>&1
	Log-Message "Dell Command updates installed: $applyResult" 

### SETS AUTO LOGIN AS ".\ITNGAdmin" ON NEXT LOGIN
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WinLogon"
Set-ItemProperty -Path $RegPath -Name "DefaultDomainName" -Value ""
Set-ItemProperty -Path $RegPath -Name "DefaultUsername" -Value ".\ITNGAdmin"
Set-ItemProperty -Path $RegPath -Name "DefaultPassword" -Value "password"
Set-ItemProperty -Path $RegPath -Name "AutoAdminLogon" -Value "1"Set-ItemProperty -Path $RegPath -Name "ForceAutoLogon" -Value "1"

### RUN NEW_SETUP_PART_4.PS1 ON NEXT LOGON
$ScriptPath = "C:\Sources\new_setup_part_4.ps1"  # UPDATE TO NEXT SCRIPT NUMBER
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$ScriptCommand = "powershell.exe -ExecutionPolicy Bypass -File `"$ScriptPath`""
Set-ItemProperty -Path $RegPath -Name "AutoRunScript" -Value $ScriptCommand


# REBOOT PC 
Write-Host "Windows updates are installed and require reboot. Rebooting PC in 5 seconds..." -ForegroundColor Red
Log-Message "End of Part 2 setup script."
Start-Sleep -Seconds 5 #wait 5 seconds to complete logging
Restart-Computer -force