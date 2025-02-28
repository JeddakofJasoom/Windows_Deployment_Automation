#set delay on first logon: 
Start-Sleep -Seconds 60

New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows" -Name "Personalization" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreen" -Value "1" -ErrorAction Continue
	Write-Host "Set registry keys to force auto login with ITNGAdmin account on next logon." -Foregroundcolor Green
Start-Sleep -Seconds 5

### RUN NEW_SETUP_PART_1.PS1 ON NEXT LOGON
New-Item -path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion" -name "RunOnce" -Force
$ScriptPath = "D:\Scripts\new_setup_part_1.ps1"  # UPDATE TO NEXT SCRIPT NUMBER
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
$ScriptCommand = "powershell.exe -ExecutionPolicy Bypass -File `"$ScriptPath`" -Verb RunAs"
Set-ItemProperty -Path $RegPath -Name "AutoRunScript" -Value $ScriptCommand 
Write-Host "Set registry keys to run new setup part 1 on next logon." -Foregroundcolor Green

#set power config to prevent sleep. 
powercfg.exe /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
powercfg -x standby-timeout-ac 0   # Disables sleep when on AC power
Write-Host "Disabled sleep while on AC power." -Foregroundcolor Green

$winupdateResult = Get-WindowsUpdate -AcceptAll -Install -ErrorAction Continue 2>&1 | Out-String

#Write-Host "Windows updates are running automatically. Will check for pending reboot status in 10 minutes to automatically reboot." 

#Start-Sleep -Seconds 600

<#
function Force-RestartAfterUpdates {
    Write-Host "Monitoring Windows Update installation..." -ForegroundColor Cyan

    while ($true) {
        # Check if a reboot is required after updates
        $RebootPending = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -ErrorAction SilentlyContinue

        if ($RebootPending) {
            Write-Host "Windows Updates installed. System will restart in 30 seconds." -ForegroundColor Green
            Start-Sleep -Seconds 30  # Short delay before forcing reboot
            Restart-Computer -Force
            break
        } else {
            Write-Host "Updates still installing... Checking again in 60 seconds." -ForegroundColor Yellow
            Start-Sleep -Seconds 60
        }
    }
}
Force-RestartAfterUpdates
#>