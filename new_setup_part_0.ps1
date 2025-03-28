#Setup part 0

#SET DELAY ON FIRST LOGON: 
	Write-Host "Windows updates are running automatically. Waiting 1 minute for DHCP to pull IP address and auto install necessary drivers."
Start-Sleep -Seconds 60 

#DISABLE AUTO SCREEN LOCK
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows" -Name "Personalization" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreen" -Value "1" -ErrorAction Continue
	Write-Host "Set registry keys to disable screen lock while running updates to monitor progress." -Foregroundcolor Green
Start-Sleep -Seconds 5

#RUN NEW_SETUP_PART_1.PS1 ON NEXT LOGON
New-Item -path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion" -name "RunOnce" -Force
$ScriptPath = "D:\Scripts\new_setup_part_1.ps1"  # UPDATE TO NEXT SCRIPT NUMBER
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
$ScriptCommand = "powershell.exe -ExecutionPolicy Bypass -File `"$ScriptPath`" -Verb RunAs"
Set-ItemProperty -Path $RegPath -Name "AutoRunScript" -Value $ScriptCommand 
	Write-Host "Set registry keys to run new setup part 1 on next logon." -Foregroundcolor Green
Start-Sleep -Seconds 5

#SET POWER CONFIG TO PREVENT SLEEP. 
powercfg.exe /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
powercfg -x standby-timeout-ac 0   # Disables sleep when on AC power
Write-Host "Disabled sleep while on AC power." -Foregroundcolor Green

#WAIT 10 MINUTES FOR WINDOWS UPDATES TO INSTALL
    Write-Host "Windows Updates are auto installing necessary drivers. Will reboot PC in 5 minutes to start main installation and setup." -ForegroundColor Cyan
Start-Sleep -Seconds 300 #wait 5 minutes

# PRINT TO SCREEN 10 SECOND COUNTDOWN AND FORCE REBOOT PC. 
Write-Host "Rebooting PC in 10 seconds..." -ForegroundColor Red
Start-Sleep -Seconds 10 
Restart-Computer -Force