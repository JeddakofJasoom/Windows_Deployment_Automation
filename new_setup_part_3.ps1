# CREATE LOG FILE AT THIS PATH:
$logFile = "C:\Sources\post_setup_log.txt"	
	# Create log file using the variable defined above.
	# Change TXT filename as needed!
New-Item -ItemType File -Path $logFile -Force | Out-Null

# CREATE CUSTOM FUNCTION TO LOG OUTPUT MESSAGES IN THIS SCRIPT:
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
Log-Message "Script execution started."

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
