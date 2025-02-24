#set delay on first logon: 
Start-Sleep -Seconds 60

New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows" -Name "Personalization" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreen" -Value "1" -ErrorAction Continue
	Log-Message "Set registry keys to force auto login with ITNGAdmin account on next logon."
Start-Sleep -Seconds 1

### RUN NEW_SETUP_PART_1.PS1 ON NEXT LOGON
New-Item -path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion" -name "RunOnce" -Force
$ScriptPath = "D:\Scripts\new_setup_part_1.ps1"  # UPDATE TO NEXT SCRIPT NUMBER
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
$ScriptCommand = "powershell.exe -ExecutionPolicy Bypass -File `"$ScriptPath`" -Verb RunAs"
Set-ItemProperty -Path $RegPath -Name "AutoRunScript" -Value $ScriptCommand 
Start-Sleep -Seconds 1


function Force-RestartAfterUpdates {
    Write-Host "Monitoring Windows Update installation..." -ForegroundColor Cyan

    while ($true) {
        # Check if a reboot is required after updates
        $RebootPending = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" -Name "RebootRequired" -ErrorAction SilentlyContinue

        if ($RebootPending) {
            Write-Host "Updates installed! System will restart NOW!" -ForegroundColor Red
            Start-Sleep -Seconds 5  # Short delay before forcing reboot
            Restart-Computer -Force
            break
        } else {
            Write-Host "Updates still installing... Checking again in 20 seconds." -ForegroundColor Yellow
            Start-Sleep -Seconds 20
        }
    }
}
Force-RestartAfterUpdates
