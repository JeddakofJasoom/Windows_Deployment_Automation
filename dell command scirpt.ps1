# Define the directory path and commands
$dirPath = "C:\Program Files (x86)\Dell\CommandUpdate\"
$reinstallDCU = "winget install -e --id Dell.CommandUpdate --scope machine --accept-source-agreements"
$DCScan = "$dirPath\dcu-cli.exe /scan"
$DCApplyUpdates = "$dirPath\dcu-cli.exe /applyUpdates -reboot=Disable"

#region Function to run dcu-cli.exe commands


# Function to run dcu-cli.exe commands
function Run-DCU-Commands {
    try {
        # Run the scan command
        Write-Host "Running Dell Command Update Scan..." -ForegroundColor Yellow
        Invoke-Command $DCScan
        if ($LASTEXITCODE -eq 500) {
			Write-Host "Scan shows no Dell updates available. Moving on to next task..." -ForegroundColor Green
			Log-Message "Scan shows no Dell updates available. Moved on to next task."
        } else {
            Write-Host "Scan shows new Dell updates available. Proceeding to install Dell updates..." -ForegroundColor Yellow
        }
        # Run the apply updates command
        Write-Host "Applying Dell updates with reboot disabled..." -ForegroundColor Yellow
        Invoke-Expression $DCApplyUpdates
        if ($LASTEXITCODE -eq 500) {
			Write-Host "Failed to apply updates because there are no new updates available. Exit code: $LASTEXITCODE."
		} else {
            Write-Host "Dell Updates applied successfully without reboot." -ForegroundColor Green
        }
    } catch {
        Write-Host "Other unknown error occurred: ERROR: $_" -ForegroundColor Red
    }
}


function Check-And-Run {
    if (Test-Path $dirPath) {
        Write-Host "Directory '$dirPath' exists. Running Dell Command Update commands..." -ForegroundColor Green
        Run-DCU-Commands
    }
    else {
        Write-Host "Directory '$dirPath' does not exist. Running reinstall command..." -ForegroundColor Yellow
        try {
            # Reinstall Dell Command Update
			Invoke-Command $reinstallDCU
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
# Run the main function
Check-And-Run



#endregion




###### most recent version but still outputs this: 


<#
Green: Directory 'C:\Program Files (x86)\Dell\CommandUpdate\' exists. Running Dell Command Update commands...
Yellow: Running Dell Command Update Scan...
Yellow: Scan shows new Dell updates available. Proceeding to install Dell updates...
Yellow: Applying Dell updates with reboot disabled...
Green: Dell Updates applied successfully without reboot.

rest is in white from output from the actual cli command... maybe just use this instead????
PS C:\Program Files (x86)\Dell\CommandUpdate> & .\dcu-cli.exe /scan
Checking for updates...
Checking for application component updates...
Determining available updates...
Check for updates completed
Number of applicable updates for the current system configuration: 0
No updates available.
Execution completed.
The program exited with return code: 500

#>



# Define the directory path and commands
$dirPath = "C:\Program Files (x86)\Dell\CommandUpdate\"
$reinstallDCU = "install -e --id Dell.CommandUpdate --scope machine --accept-source-agreements"
$DCScan = "$dirPath\dcu-cli.exe"
$DCApplyUpdates = "$dirPath\dcu-cli.exe /applyUpdates -reboot=Disable"


#region Function to run dcu-cli.exe commands


# Function to run dcu-cli.exe commands
function Run-DCU-Commands {

try {
    # Run the scan command
    Write-Host "Running Dell Command Update Scan..." -ForegroundColor Yellow
    Start-Process -WorkingDirectory $dirPath -FilePath $DCScan -ArgumentList "/scan" -NoNewWindow -Wait
        
    #check when scan completes:    
    if ($LASTEXITCODE -eq 500) { #500 - no new updates and auto ends scan command. 
		Write-Host "Scan shows no Dell updates available. Moving on to next task..." -ForegroundColor Green
#			Log-Message "Scan shows no Dell updates available. Moved on to next task."
    } else {
        Write-Host "Scan shows new Dell updates available. Proceeding to install Dell updates..." -ForegroundColor Yellow
            try { 
                # Run the apply updates command
                Write-Host "Applying Dell updates with reboot disabled..." -ForegroundColor Yellow
                Start-Process -WorkingDirectory $dirPath -FilePath $DCScan -ArgumentList "/applyupdates" -NoNewWindow -Wait
                        
                    #check when apply updates completes:
                    if ($LASTEXITCODE -eq 500) {
			            Write-Host "Failed to apply updates because there are no new updates available. Exit code: $LASTEXITCODE."
		            } 
                    else {
                        Write-Host "Dell Updates applied successfully without reboot." -ForegroundColor Green
                            }
            } 
            catch {
                throw "apply updates errored"
            }
        } #closing else  
} catch { #throw error if something weird happens: 
        Write-Host "Other unknown error occurred: ERROR: $_" -ForegroundColor Red
    }
} #end function defintion


function Check-And-Run {
    if (Test-Path $dirPath) {
        Write-Host "Directory '$dirPath' exists. Running Dell Command Update commands..." -ForegroundColor Green
        Run-DCU-Commands
    }
    else {
        Write-Host "Directory '$dirPath' does not exist. Running reinstall command..." -ForegroundColor Yellow
        #if DCU doesn't exist, try to install through winget:
        try {
            # Reinstall Dell Command Update
			Start-Process -FilePath "winget.exe" -ArgumentList $reinstallDCU -NoNewWindow -Wait
            Write-Host "Reinstallation completed successfully." -ForegroundColor Green
        }
        catch {
            Write-Host "ERROR: Failed to reinstall Dell Command Update. Error: $_" -ForegroundColor Red
            }	
        }
} #end function definition

# Run the main function
Check-And-Run

#Run-DCU-Commands

#endregion


