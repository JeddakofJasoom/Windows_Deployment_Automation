#region

			##DELL COMMAND SECTION START.

# Define the directory path for Dell Command Update:
	$DCUdirPath = "C:\Program Files\Dell\CommandUpdate\"
	$InstallDCU = "winget.exe install -e --id Dell.CommandUpdate --scope machine --accept-source-agreements"
	$DCUexePath = Join-Path -Path $DCUdirPath -ChildPath "dcu-cli.exe"


## FUNCTION TO RUN DELL UPDATES
function Run-DellUpdates {

try {
	if (-not (Test-Path $DCUdirPath)) { #check if DCU is installed; install through winget if missing.
		Write-Host "Dell Command is not installed on this system. Installing now through WinGet..." -ForegroundColor Red
		#install DCU through winget:
		$InstallDCU
	} else {
		Write-Host "Dell Command is installed on this system at $DCUdirPath. Proceeding with scan" -ForegroundColor Green
	}
	# Run the scan
	Write-Host "Starting Dell Command Update scan..." -ForegroundColor Yellow
	#log scan results
	$scanResult = & $DCUexePath /scan 2>&1
	Write-Host Scan results: $scanResult -ForegroundColor Green

	# Apply updates with reboot DISabled ( PC will restart at the end of this script)
	Write-Host "Applying Dell Updates..." -ForegroundColor Yellow
	$applyResult = & $DCUexePath /applyUpdates -reboot=Disable 2>&1
	Write-Host "Dell Updates installed. See result: $applyResult" -ForegroundColor Yellow

	# Check for errors
	if ($scanResult -match "Error" -or $applyResult -match "Error") {
		Write-Host "An error occurred during the update process. Error: $_" -ForegroundColor Red
	} else {
		Write-Host "Dell updates completed successfully." -ForegroundColor Green
	}
} catch {
		Write-Host "An unexpected error occurred with Dell Command Update: $_" -ForegroundColor Red
		}
} # end function definition

# ==========================
# Function Execution: Run-DellUpdates
# ==========================
Run-DellUpdates


#endregion