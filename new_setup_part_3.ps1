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
<#
cd "c:\program files (x86)\Dell\CommandUpdate\"
& ".\dcu-cli.exe" /scan 
$applyResult = & ".\dcu-cli.exe" /ApplyUpdates -reboot=Disable 2>&1
	Log-Message "Dell Command updates installed: $applyResult" 
#> 



# system cleanup
dism /online /cleanup-image /restorehealth
dism /online /cleanup-image /startcomponentcleanup
sfc /scannow


# End logging to setup log file.
Log-Message "POST-setup script execution ended."

# Force reboot after 5-second delay before reboot to allow logging to finalize. 
Start-Sleep -Seconds 5
Restart-Computer -Force
