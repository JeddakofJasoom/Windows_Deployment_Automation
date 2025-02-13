<#
TODO: dell command second run
	
TODO: add bloatware removal 
TODO: add default user profile XML 
TODO: add user profile base change reg keys
TODO: change multi setup log to append to 1 long setup log??? 
TODO: - add spacer in it for section??
TODO: on last script: auto load setup.txt
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
Log-Message "New Setup Part 3 Script has started here."


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



####### need to add reg key to remove run new_setup_part_3.ps1 
####### need to add reg key to run new_setup_part_4.ps1 on next logon
####### need to add reg key to auto login as admin on next login




# REBOOT PC 
Write-Host "Windows updates are installed and require reboot. Rebooting PC in 5 seconds..." -ForegroundColor Red
	Log-Message "End of Part 3 setup script."
Start-Sleep -Seconds 5 #wait 5 seconds to complete logging
Restart-Computer -force