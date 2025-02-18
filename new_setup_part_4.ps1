<#

TODO: add remove c:sources folder at end of last pass script!
TODO: add rmm installer as subfolder in c:\sources?
TODO: add rename computer prompt 
TODO: add rename itngadmin password prompt
TODO: 
TODO: 
TODO: 
TODO: 
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
Log-Message "New Setup Part 4 Script has started here."

### *REMOVES* AUTO LOGIN AS ".\ITNGAdmin" ON NEXT LOGIN
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WinLogon"
Remove-ItemProperty -Path $RegPath -Name "DefaultDomainName" -Value ""
Remove-ItemProperty -Path $RegPath -Name "DefaultUsername" -Value ".\ITNGAdmin"
Remove-ItemProperty -Path $RegPath -Name "DefaultPassword" -Value "password"
Remove-ItemProperty -Path $RegPath -Name "AutoAdminLogon" -Value "1"
Remove-ItemProperty -Path $RegPath -Name "ForceAutoLogon" -Value "1"
Log-Message "Removed all registry keys to disable auto logon."

### RUN NEW_SETUP_PART_3.PS1 ON NEXT LOGON
$ScriptPath = "C:\Sources\new_setup_part_3.ps1"  # UPDATE TO NEXT SCRIPT NUMBER
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$ScriptCommand = "powershell.exe -ExecutionPolicy Bypass -File `"$ScriptPath`""
Remove-ItemProperty -Path $RegPath -Name "AutoRunScript" -Value $ScriptCommand
Log-Message "Removed all registry keys to run powershell scripts on logon." 




# RUN DELL COMMAND UPDATE
cd "c:\program files (x86)\Dell\CommandUpdate\"
& ".\dcu-cli.exe" /scan 
$applyResult = & ".\dcu-cli.exe" /ApplyUpdates -reboot=Disable 2>&1
	Log-Message "Dell Command updates installed: $applyResult" 

# SYSTEM CLEANUP
dism /online /cleanup-image /restorehealth
dism /online /cleanup-image /startcomponentcleanup
sfc /scannow


# FORCE CHANGE ITNGADMIN PASSWORD FROM DEFAULT:
Write-Host "The current password for the local account ITNGAdmin is set to the default of 'password' and MUST be changed." -ForegroundColor Red
Write-Host "Please enter the password you want to change it to here:" -Foregroundcolor Yellow
$desiredPassword = Read-Host 
$newPassword = ConvertTo-SecureString $desiredPassword -AsPlainText -Force
Set-LocalUser -Name "ITNGAdmin" -Password $newPassword 
Write-Host "Password for ITNGAdmin has been changed to: '$desiredPassword'" -ForegroundColor Green
Log-Message "Changed ITNGAdmin password from its default." 

# CHANGE COMPUTER NAME WITH MANUAL INPUT:
$currentName = $env:COMPUTERNAME
    Write-Host "The current computername is: '$currentName'." -ForegroundColor Yellow
    Write-Host  "Do you want to change the computer name NOW? Y/N" -ForegroundColor Red
$response = Read-Host 
if ($response -match '^(Y|y|Yes|yes)$') {
	Write-Host "Please enter the new computer name:" -ForegroundColor Yellow
$newName = Read-Host 
	Write-Host "Current Computer Name: $currentName" -ForegroundColor Yellow
	Write-Host "New Computer Name will be: $newName" -ForegroundColor Green
Rename-Computer -NewName $newName -Force
	Log-Message "Computer name changed to '$newName'"
} else {
	Log-Message "Computer name will remain as: '$currentName'"
}




# End logging to setup log file.
Log-Message "End of Part 4 setup script."
Log-Message "All commands have been run and system is set to standard configuration. Please check the C:\Sources\New_Setup_LOG.txt for complete setup log information."


#COPY SETUP LOG TO ITNGADMIN DESKTOP FOR REVIEW. 
$sourceFile = "C:\Sources\New_Setup_LOG.txt" 
$destinationFolder = "C:\Users\ITNGAdmin\Desktop\"
Copy-Item -Path $sourceFile -Destination $destinationFolder -Force
Log-Message "Copied all content from $sourceFolder folder to $destinationFolder" 

Remove-Item -Path "C:\Sources" -Recurse -Force


# Force open setup log in notepad to check completion: 
Start-Process notepad.exe "C:\Users\ITNGAdmin\Desktop\New_Setup_LOG.txt"




