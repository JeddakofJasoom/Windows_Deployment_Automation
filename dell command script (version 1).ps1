# Define the directory path and commands
$dirPath = "C:\Program Files (x86)\Dell\CommandUpdate\"
$reinstallDCU = "winget install -e --id Dell.CommandUpdate --scope machine --accept-source-agreements"
$DCScan = ".\dcu-cli.exe /scan"
$DCApplyUpdates = ".\dcu-cli.exe /applyUpdates -reboot=Disable"

# Function to check directory and run dcu-cli.exe
function Check-And-Run {
    if (Test-Path $dirPath) {
        Write-Host "Directory '$dirPath' exists. Running Dell Command Update commands..." -ForegroundColor Green
        Run-DCU-Commands
    }
    else {
        Write-Host "Directory '$dirPath' does not exist. Running reinstall command..." -ForegroundColor Yellow
        try {
            # Reinstall Dell Command Update
            Invoke-Expression $reinstallDCU
            Write-Host "Reinstallation completed successfully." -ForegroundColor Green
        }
        catch {
            Write-Host "ERROR: Failed to reinstall Dell Command Update. Error: $_" -ForegroundColor Red
            }
			
			# Check again if directory exists
        if (Test-Path $dirPath) {
            Write-Host "Directory '$dirPath' now exists. Running Dell Command Update commands..." -ForegroundColor Green
            Run-DCU-Commands
        }
        else {
            Write-Host "ERROR: Directory '$dirPath' still does not exist after reinstallation." -ForegroundColor Red
        }
    }
}

# Function to run dcu-cli.exe commands
function Run-DCU-Commands {
    try {
        # Run the scan command
        Write-Host "Running Dell Command Update Scan..." -ForegroundColor Cyan
        Invoke-Expression $DCScan
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Scan completed successfully. Proceeding to apply updates..." -ForegroundColor Green
        }
        else {
            throw "Scan failed with exit code $LASTEXITCODE."
        }

        # Run the apply updates command
        Write-Host "Applying updates with reboot disabled..." -ForegroundColor Cyan
        Invoke-Expression $DCApplyUpdates
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Updates applied successfully without reboot." -ForegroundColor Green
        }
        else {
            throw "Failed to apply updates with exit code $LASTEXITCODE."
        }
    }
    catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
    }
}

# Run the main function
Check-And-Run
