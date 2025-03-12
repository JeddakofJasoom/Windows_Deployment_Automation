<#
TODO: add rmm installer as subfolder in c:\sources?
TODO: do a check to be sure the reg keys have been removed to autounlock / auto login - last time it didn't get removed. 

TODO: PRINT OUT OVERFLOW LIST AND CHECK WITH DAVID
TODO: bitlocker enable prompt option...?
#>

Write-Host "Starting 'New setup part 4' in 10 seconds... Please do not interact with the screen as this script is automated to reboot." -ForegroundColor Yellow

Start-Sleep -Seconds 10

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
Log-Message "New Setup Part 4 Script has started here."

### REMOVE CURRENT REG KEY for NEW_SETUP_PART_4.PS1
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
Remove-Item -Path $RegPath 
	Log-Message "Removed all registry keys to run powershell scripts on logon." 

	# Removes auto screen unlock
Remove-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
	Log-Message "Removed registry key to keep screen unlocked"
	#Log-Message "Removed all registry keys to disable auto logon."
Start-Sleep -Seconds 1


# RUN DELL COMMAND UPDATE (2nd pass)
cd "c:\program files (x86)\Dell\CommandUpdate\"
& ".\dcu-cli.exe" /scan 
& ".\dcu-cli.exe" /ApplyUpdates -reboot=Disable
	Log-Message "Dell Command updates installed." 


# SYSTEM CLEANUP
dism /online /cleanup-image /restorehealth
dism /online /cleanup-image /startcomponentcleanup
sfc /scannow
	Log-Message "Ran DISM and SFC for system cleanup."

### REMOVE CURRENT REG KEY for NEW_SETUP_PART_4.PS1
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
Remove-Item -Path $RegPath -ErrorAction SilentlyContinue
	Log-Message "Ran second pass to ensure removal of all registry keys to run powershell scripts on logon - ignore any errors on screen." 
	
# FORCE CHANGE ITNGADMIN PASSWORD FROM DEFAULT:
Write-Host "The current password for the local account ITNGAdmin is set to the default of 'password' and MUST be changed." -ForegroundColor Red
Write-Host "Please enter the password you want to change it to here:" -Foregroundcolor Yellow
$desiredPassword = Read-Host 
$newPassword = ConvertTo-SecureString $desiredPassword -AsPlainText -Force
Set-LocalUser -Name "ITNGAdmin" -Password $newPassword 
Write-Host "Password for ITNGAdmin has been changed to: '$desiredPassword'" -ForegroundColor Green
Log-Message "Changed ITNGAdmin password from its default to: $desiredPassword" 

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

#COPY SETUP LOG TO ITNGADMIN DESKTOP FOR REVIEW. 
$sourceFile = "C:\Sources\New_Setup_LOG.txt" 
$destinationFolder = "C:\Users\ITNGAdmin\Desktop\"
    Log-Message "~~~~~~"
    Log-Message "Copied all content from $sourceFile folder to $destinationFolder" 
	Log-Message "Removed C:\Sources folder from this system as final cleanup task."
    Log-Message "~~~~~~"
    Log-Message "All commands have been run and system is set to standard configuration. Please check the C:\Sources\New_Setup_LOG.txt for complete setup log information."
Start-Sleep -Seconds 2
Copy-Item -Path $sourceFile -Destination $destinationFolder -Force
Remove-Item -Path "C:\Sources" -Recurse -Force
	
# Force open setup log in notepad to check completion: 
Write-Host "Opening New Setup Log File now, please check settings changes!" -ForegroundColor Red
Start-Sleep -Seconds 5
Start-Process notepad.exe "C:\Users\ITNGAdmin\Desktop\New_Setup_LOG.txt"




