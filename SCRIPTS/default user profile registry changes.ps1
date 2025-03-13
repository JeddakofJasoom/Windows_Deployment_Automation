<# 
This first script configures several Windows 11 settings that are more appropriate for business use.
. Creates *local* group policies to add registry keys on first logon. 
. Has to be local GPO as the reg key for current user has to be done under the logged in user to take effect. 
. modified from https://gist.github.com/redlttr/8b95df51fd472d459b5c3a3ae6c8f5ad
. if running as standalone script, you must run this first to allow scripts to be run:
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
#>

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

<# (OPTIONAL) Check policies: 
Report on configured policies
Get-PolicyFileEntry -Path $ComputerPolicyFile -All
Get-PolicyFileEntry -Path $UserPolicyFile -All
remove the policies
Get-PolicyFileEntry -Path $ComputerPolicyFile -All | Remove-PolicyFileEntry -Path $ComputerPolicyFile
Get-PolicyFileEntry -Path $UserPolicyFile -All | Remove-PolicyFileEntry -Path $UserPolicyFile
#>