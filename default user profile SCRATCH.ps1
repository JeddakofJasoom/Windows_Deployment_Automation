###user profile settings change: 

# DISABLE WIDGETS
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft" -Name "Dsh"
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -PropertyType DWORD -Value 0 -Force
# DISABLE TASKVIEW
New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -PropertyType DWORD -Value 0 -Force
# DISABLE THE RANDOM ICON LINKS IN WINDOWS SEARCH
New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows" -Name "Windows Search"
# TASKBAR ALIGN TO LEFT 
New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -PropertyType DWORD -Value 0 -Force
# REMOVE "COPILOT" FOR ALL USERS
Get-AppxPackage -AllUsers "Microsoft.Copilot" | Remove-AppxPackage
# REMOVE "OUTLOOK (NEW)" FOR ALL USERS
Get-AppxPackage -AllUsers "Microsoft.OutlookForWindows" | Remove-AppxPackage
# SET NUMLOCK TO ALWAYS ON
Set-ItemProperty -Path "Registry::HKEY_USERS\.DEFAULT\Control Panel\Keyboard" -Name "InitialKeyboardIndicators" -Value "2" 
# DISABLE 'WEB SEARCH RESULTS' IN WINDOWS SEARCH 
New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows" -name "Explorer" 
New-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -PropertyType DWORD -Value 1 -Force
