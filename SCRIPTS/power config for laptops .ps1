# Define registry paths for each setting
$powerButtonPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\4f971e89-eebd-4455-a8de-9e59040e7347\7648efa3-dd9c-4e3e-b566-50f929386280"
$sleepButtonPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\4f971e89-eebd-4455-a8de-9e59040e7347\96996bc0-ad50-47ec-923b-6f41874dd9eb"
$lidCloseActionPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\4f971e89-eebd-4455-a8de-9e59040e7347\5ca83367-6e45-459f-a27b-476b1d01c936"

# Function to create key if it doesn't exist
function Ensure-RegistryKey {
    param (
        [string]$path
    )
    if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
    }
}

# Create missing registry keys if they do not exist
Ensure-RegistryKey -path $powerButtonPath
Ensure-RegistryKey -path $sleepButtonPath
Ensure-RegistryKey -path $lidCloseActionPath

<# Set Power Button action - when you push the physical power button:
0 = do nothing 
1 = sleep
2 = hibernate
3 = shut down
4 = turn off display
#> 
Set-ItemProperty -Path $powerButtonPath -Name "ACSettingIndex" -Value 3   # Plugged in: Shut down
Set-ItemProperty -Path $powerButtonPath -Name "DCSettingIndex" -Value 3   # On battery: Shut down

<# Set Sleep Button action - when you click sleep: 
0 = do nothing 
1 = sleep
2 = hibernate
3 = shut down
4 = turn off display
#> 
Set-ItemProperty -Path $sleepButtonPath -Name "ACSettingIndex" -Value 0   # Plugged in: Do nothing
Set-ItemProperty -Path $sleepButtonPath -Name "DCSettingIndex" -Value 0   # On battery: Do nothing

<# Set Lid Close Action
0 = do nothing 
1 = sleep
2 = hibernate
3 = shut down
#> 
Set-ItemProperty -Path $lidCloseActionPath -Name "ACSettingIndex" -Value 0   # Plugged in: Do nothing
Set-ItemProperty -Path $lidCloseActionPath -Name "DCSettingIndex" -Value 3   # On battery: Shut down

# Output confirmation
Write-Output "Registry settings for Power Button, Sleep Button, and Lid Close Action have been updated."
