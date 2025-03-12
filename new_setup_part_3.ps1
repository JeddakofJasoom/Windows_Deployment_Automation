#Setup part 3

Write-Host "Starting 'New setup part 3' in 10 seconds... Please do not interact with the screen as this script is automated to reboot." -ForegroundColor Yellow
	Start-Sleep -Seconds 10

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
Log-Message "~~~~~"
Log-Message "New Setup Part 3 Script has started here."

### REMOVE CURRENT REG KEY for NEW_SETUP_PART_3.PS1
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
Remove-Item -Path $RegPath  
	Log-Message "Removed registry key to run part 3 script."
Start-Sleep -Seconds 1

### RUN NEW_SETUP_PART_4.PS1 ON NEXT LOGON
New-Item -path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion" -name "RunOnce" -Force
$ScriptPath = "C:\Sources\new_setup_part_4.ps1"  # UPDATE TO NEXT SCRIPT NUMBER
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
$ScriptCommand = "powershell.exe -ExecutionPolicy Bypass -File `"$ScriptPath`" -Verb RunAs"
Set-ItemProperty -Path $RegPath -Name "AutoRunScript" -Value $ScriptCommand


	###################################
	#~ USER PROFILE SETTINGS CHANGE: ~#
	###################################
#region user profile changes
					
# INSTALL THE POLICYFILEEDITOR MODULE TO UPDATE LOCAL GROUP POLICY 
Try {
    $null = Get-InstalledModule PolicyFileEditor -ErrorAction Stop
} Catch {
    if ( -not ( Get-PackageProvider -ListAvailable | Where-Object Name -eq "Nuget" ) ) {
        $null = Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    }
    $null = Install-Module PolicyFileEditor -Force
}
$null = Import-Module PolicyFileEditor -Force

# Variables
$ComputerPolicyFile = Join-Path $env:SystemRoot '\System32\GroupPolicy\Machine\registry.pol'
$UserPolicyFile = Join-Path $env:SystemRoot '\System32\GroupPolicy\User\registry.pol'
$WinVer = Get-CimInstance win32_operatingsystem

# DEFINE COMPUTER (HKLM) POLICIES:
$ComputerPolicies = @(
# DISABLE NEWS/INTERESTS ON TASKBAR
    [PSCustomObject]@{Key = 'Software\Policies\Microsoft\Windows\Windows Feeds'; ValueName = 'EnableFeeds'; Data = '0'; Type = 'Dword' }
# 	[PSCustomObject]@{Key = ' '; ValueName = ' '; Data = ' '; Type = 'Dword' }
# 	[PSCustomObject]@{Key = ' '; ValueName = ' '; Data = ' '; Type = 'Dword' }
)

# DEFINE USER (HKCU) POLICIES: 
$UserPolicies = @(
# DISABLE 'WEB SEARCH RESULTS' IN WINDOWS SEARCH 
    [PSCustomObject]@{Key = 'SOFTWARE\Policies\Microsoft\Windows\Explorer'; ValueName = 'DisableSearchBoxSuggestions'; Data = '1'; Type = 'Dword' } 
# TASKBAR ALIGN TO LEFT 
    [PSCustomObject]@{Key = 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; ValueName = 'TaskbarAl'; Data = '0'; Type = 'Dword' } 
# DISABLE TASKVIEW BUTTON
    [PSCustomObject]@{Key = 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; ValueName = 'ShowTaskViewButton'; Data = '0'; Type = 'Dword' } 
# SET NUMLOCK TO ALWAYS ON
	[PSCustomObject]@{Key = '.DEFAULT\Control Panel\Keyboard'; ValueName = 'InitialKeyboardIndicators'; Data = '2'; Type = 'Dword' }
# 	[PSCustomObject]@{Key = ' '; ValueName = ' '; Data = ' '; Type = 'Dword' }
# 	[PSCustomObject]@{Key = ' '; ValueName = ' '; Data = ' '; Type = 'Dword' }
)
 
# Set group policies
try {
    Write-Output 'Setting local group policies...'
    $ComputerPolicies | Set-PolicyFileEntry -Path $ComputerPolicyFile -ErrorAction Stop
    $UserPolicies | Set-PolicyFileEntry -Path $UserPolicyFile -ErrorAction Stop
    gpupdate /force /wait:0 | Out-Null
    Write-Output 'Group policies set.'
}
catch {
    Write-Warning 'Unable to apply group policies.'
    Write-Output $_
}
  
# CLEANUP START MENU & TASKBAR
try {
    if ($WinVer.Caption -like '*Windows 11*') {
        # Reset existing start menu layouts
        $Layout = 'AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState'
        Get-ChildItem 'C:\Users' | ForEach-Object { Remove-Item "C:\Users\$($_.Name)\$Layout" -Recurse -Force -ErrorAction Ignore }
    }
    # Restart Explorer 
    if ($env:USERNAME -ne 'defaultuser0') { Get-Process -Name Explorer -ErrorAction SilentlyContinue | Stop-Process -Force }
}
catch {
    Write-Warning 'Unable to complete start menu & taskbar cleanup tasks.'
    Write-Output $_
}
	
	# SET DEFAULT APPS:
dism /online /Import-DefaultAppAssociations:C:\Sources\DefaultApps.xml
<#
.html = Chrome
.pdf = Adobe
mailto = OUTLOOK
.eml = OUTLOOK
#>
#endregion user profile changes

	################################
	#~ BLOATWARE REMOVAL SECTION: ~#	
	################################
#region bloatware Removal

# List of apps to remove
$Packages = @(
   'Clipchamp.Clipchamp',
   'Microsoft.BingNews',
   'Microsoft.BingSearch',
   'Microsoft.BingWeather',
   'Microsoft.GamingApp',
   'Microsoft.GetHelp',
   'Microsoft.Getstarted',
   'Microsoft.MicrosoftSolitaireCollection',
   'Microsoft.MicrosoftOfficeHub',
   'Microsoft.MixedReality.Portal',
   'Microsoft.OutlookForWindows', #Outlook (new)
   'Microsoft.People',
   'Microsoft.PowerAutomateDesktop',
   'Microsoft.Todos', #Todo List
   'Microsoft.Wallet',
   'Microsoft.Windows.DevHome',
   'microsoft.windowscommunicationsapps', #Windows Mail 
   'Microsoft.WindowsFeedbackHub',
   'Microsoft.WindowsMaps',
   'Microsoft.Xbox.TCUI',
   'Microsoft.XboxApp',
   'Microsoft.XboxGameOverlay',
   'Microsoft.XboxGamingOverlay',
   'Microsoft.XboxGamingOverlay',
   'Microsoft.XboxIdentityProvider',
   'Microsoft.XboxSpeechToTextOverlay'
   'Microsoft.YourPhone',
   'Microsoft.ZuneMusic'
)

# Create log arrays
$RemovedPackages = @()
$FailedPackages = @()

ForEach ($Package in $Packages) {
    try {
        # Find the installed package
        $App = Get-AppxPackage -AllUsers | Where-Object { $_.PackageFullName -like "$Package*" }
        if ($App) {
            # Attempt to remove the package
            Remove-AppxPackage -Package $App.PackageFullName -AllUsers -ErrorAction Stop
            $RemovedPackages += $Package
        } else {
            $FailedPackages += "$Package (Not Found)"
} } catch {
      $FailedPackages += "$Package (Failed to Remove - $($_.Exception.Message))"
} }

# Display Results - Successfully Removed: 
Write-Host "`n=== Removal Summary ===" -ForegroundColor Cyan
Write-Host "`nSuccessfully Removed Packages:" -ForegroundColor Green
$RemovedPackages | ForEach-Object { Write-Host $_ }

# Display Results - Failed to Remove (includes already uninstalled): 
Write-Host "`nFailed to Remove Packages:" -ForegroundColor Red
$FailedPackages | ForEach-Object { Write-Host $_ }

#endregion bloatware removal


# UPDATE WINDOWS DEFENDER WITH POWERSHELL
Update-MpSignature
Log-Message "AV signature definitions updated." 

# RUN DELL COMMAND UPDATE
cd "c:\program files (x86)\Dell\CommandUpdate\"
& ".\dcu-cli.exe" /scan 
Log-Message "Installing available Dell updates..."
& ".\dcu-cli.exe" /ApplyUpdates -reboot=Disable
	Log-Message "Dell Command updates installed." 
	
# REBOOT PC 
Write-Host "Dell Command Updates are installed and require reboot. Rebooting PC in 5 seconds..." -ForegroundColor Red
Log-Message "End of Part 3 setup script."
Start-Sleep -Seconds 5 #wait 5 seconds to complete logging
Restart-Computer -force