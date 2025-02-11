<# contents:

- variables 
- fn: check dcu installed
	- check path 1
	- check path 2
	- update global path variable 
- fn: update scan
- fn: apply updates




#>

    # Define the possible directory paths for Dell Command Update
$DCUdirPath1 = "C:\Program Files (x86)\Dell\CommandUpdate\"
$DCUdirPath2 = "C:\Program Files\Dell\CommandUpdate\"
$global:DCUdirPath = $null  # Initialize the unified directory path variable
    # install dcu through winget
$InstallDCU = "install -e --id Dell.CommandUpdate --scope machine --accept-source-agreements"
    #dcu commands
$DCU_CLI = Join-Path -Path $global:DCUdirPath -ChildPath "dcu-cli.exe"

# doesn't work: Start-Process -WorkingDirectory $global:DCUdirPath -FilePath $DCU_CLI -ArgumentList "/scan -reboot=Disable" -NoNewWindow -Wait *> $scanResult




# ==========================
# Define function: Set-DCUPath
# ==========================
function Set-DCUPath { # Function to check if either path exists and set $DCUdirPath
    if (Test-Path $DCUdirPath1) {
        $global:DCUdirPath = $DCUdirPath1
        Write-Host "Using Dell Command Update Path: $DCUdirPath1"
    } elseif (Test-Path $DCUdirPath2) {
        $global:DCUdirPath = $DCUdirPath2
        Write-Host "Using Dell Command Update Path: $DCUdirPath2"
    } else { #DCU not installed
        Write-Host "Dell Command Update is not installed on this system."
		try { 
				#install DCU through winget  
			Start-Process -FilePath "winget.exe" -ArgumentList $InstallDCU -NoNewWindow -Wait
				#log install
			Write-Host "Installed Dell Command Update through winget." -Foregroundcolor -Green
			Log-Message "Installed Dell Command Update through winget."
		} catch {
			Write-Host "Dell Command is not installed on this system. Winget FAILED to install DCU." -Foregroundcolor -Red
		}
    }
} #end function definition

# ==========================
# Function Execution: Set-DCUPath
# ==========================
	Set-DCUPath


# ==========================
# Define function: Run-DellUpdates
# ==========================
function Run-DellUpdates {

try { 
	Write-Host "Starting Dell Command Update scan..." -ForegroundColor Yellow
	# Run the scan
	$scanResult = & $DCU_CLI "/scan" 2>&1
	#log scan results
	Write-Host "Scan results: $scanResult" -ForegroundColor Cyan
	Log-Message "Dell scan results: $scanResult"
} catch {
throw }

try { 
	Write-Host "Installing Dell Command updates..." -ForegroundColor Yellow
	    # Install updates, no autoreboot, and log all output and errors to $applyResult
    $applyResult = & $DCU_CLI "/applyupdates" "-reboot=Disable" 2>&1
	    #log scan results
	Write-Host "Dell updates installed: $applyResult" -ForegroundColor Green
	Log-Message "Dell updates installed: $applyResult"
} catch {
throw }

} #end function definition

# ==========================
# Function Execution: Run-DellUpdates
# ==========================
	Run-DellUpdates