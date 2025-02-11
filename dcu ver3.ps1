# Define the possible directory paths for Dell Command Update
$DCUdirPath1 = "C:\Program Files (x86)\Dell\CommandUpdate\"
$DCUdirPath2 = "C:\Program Files\Dell\CommandUpdate\"
$global:DCUdirPath = $null  # Initialize the unified directory path variable

# Function to check if either path exists and set $DCUdirPath
function Set-DCUPath {
    if (Test-Path $DCUdirPath1) {
        $global:DCUdirPath = $DCUdirPath1
        Write-Host "Using Dell Command Update Path: $DCUdirPath1"
    } elseif (Test-Path $DCUdirPath2) {
        $global:DCUdirPath = $DCUdirPath2
        Write-Host "Using Dell Command Update Path: $DCUdirPath2"
    } else {
        Write-Host "Dell Command Update is not installed on this system."
		try {
			
    }
}
	$InstallDCU = "install -e --id Dell.CommandUpdate --scope machine --accept-source-agreements"


		Start-Process -FilePath "winget.exe" -ArgumentList $InstallDCU -NoNewWindow -Wait




# Function to run Dell updates
function Run-DellUpdates {

$DCUexePath = Join-Path -Path $global:DCUdirPath -ChildPath "dcu-cli.exe"
    if (Test-Path $DCUexePath) {
		try {
			# Run the scan
			Write-Host "Starting Dell Command Update scan..." -Foregroundcolor -Yellow
			$scanResult = & $DCUexePath /scan 2>&1
			Write-Host $scanResult

			# Apply updates with reboot enabled
			Write-Host "Applying updates..."
			$applyResult = & $DCUexePath /applyUpdates -reboot=Enable 2>&1
			Write-Host $applyResult

			# Check for errors
			if ($scanResult -match "Error" -or $applyResult -match "Error") {
				Write-Host "An error occurred during the update process."
			} else {
				Write-Host "Dell updates completed successfully."
			}
		}
		catch {
			Write-Host "An unexpected error occurred: $_"
		}
	}
	else {
		Write-Host "Dell Command Update executable not found in $global:DCUdirPath"
	}
    }
    else {
        Write-Host "Dell Command Update path is not set."
    }
}

# Function to check and run Dell updates
function Check-And-Run-DCU {
    Set-DCUPath  # Set the correct path
    Run-DellUpdates  # Run updates if the path is valid
}

# Call the function to check and run Dell updates
Check-And-Run-DCU