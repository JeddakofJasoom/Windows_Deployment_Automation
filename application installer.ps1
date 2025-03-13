	
#####Install 'NuGet' package if missing from system, depending on Windows version.#####
if ( -not ( Get-PackageProvider -ListAvailable | Where-Object Name -eq "Nuget" ) ) {
        Write-Host "Installing latest version of 'NuGet' package from Microsoft" -ForegroundColor Yellow
		$null = Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    }
	
###RUN WINGET TO INSTALL SPECIFIC APPLICATIONS.###

# Define the applications to install (name and corresponding winget package)
$apps = @(
[PSCustomObject]@{Name="Adobe Acrobat PRO"; Package="adobe.acrobat.Pro"},
[PSCustomObject]@{Name="Adobe Acrobat Reader"; Package="adobe.acrobat.reader.64-bit"},
[PSCustomObject]@{Name="Autodesk Desktop (CAD viewer)"; Package="AutoDesk.DesktopApp "},
[PSCustomObject]@{Name="Bluebeam Revu 20"; Package="Bluebeam.Revu.20"},
[PSCustomObject]@{Name="Bluebeam Revu 21"; Package="Bluebeam.Revu.21"},
[PSCustomObject]@{Name="BluebeamOCR 21"; Package="Bluebeam.BluebeamOCR.21"},
[PSCustomObject]@{Name="Cisco Webex"; Package="Cisco.Webex"},
[PSCustomObject]@{Name="Datto Workplace (version 10) "; Package="Datto.Workplace "},
[PSCustomObject]@{Name="Dell Command Update"; Package="Dell.CommandUpdate"},
[PSCustomObject]@{Name="Dropbox"; Package="Dropbox.Dropbox"},
[PSCustomObject]@{Name="DW Spectrum"; Package="DW.Spectrum.Client "},
[PSCustomObject]@{Name="Firefox"; Package="Mozilla.Firefox"},
[PSCustomObject]@{Name="Google Chrome"; Package="Google.Chrome"},
[PSCustomObject]@{Name="Google.Earth"; Package="Google.EarthPro"},
[PSCustomObject]@{Name="Grammarly for Windows"; Package="Grammarly.Grammarly"},
[PSCustomObject]@{Name="Lenovo Commercial Vantage"; Package="9NR5B8GVVM13"},
[PSCustomObject]@{Name="ndOffice (NetDocs) "; Package="NetDocuments.ndOffice"},
[PSCustomObject]@{Name="Powershell 7"; Package="microsoft.powershell"},
[PSCustomObject]@{Name="Slack"; Package="SlackTechnologies.Slack"},
[PSCustomObject]@{Name="Splashtop Streamer"; Package="Splashtop.SplashtopStreamer"},
[PSCustomObject]@{Name="VLC Media Player"; Package="VideoLAN.VLC"},
[PSCustomObject]@{Name="Zoom Workplace"; Package="Zoom.Zoom"},
[PSCustomObject]@{Name="7-Zip"; Package="7zip.7zip "}
# Uncomment and add more applications as needed:
#	[PSCustomObject]@{Name=" "; Package=" "}
#	[PSCustomObject]@{Name=" "; Package=" "}
#	[PSCustomObject]@{Name=" "; Package=" "}
#	[PSCustomObject]@{Name=" "; Package=" "}
)

# CREATE GUI POPUP to allow user to select apps from the above list
$selectedApps = $apps | Out-GridView -Title "Select Applications to Install" -PassThru

# Install selected applications
foreach ($app in $selectedApps) {
    Write-Host "Installing: $($app.Name)" -ForegroundColor Cyan
    winget.exe install $app.Package --scope machine --silent --accept-source-agreements
}
Write-Host "Installation of SELECTED software via winget completed." -ForegroundColor Green
Write-Host "Updating all software to latest version." -ForegroundColor Cyan
winget.exe upgrade --all


<#NOTES: 
	: YOU HAVE TO REMOVE THE " , " ON THE LAST APPLICATION OR THIS WILL FAIL!!!
	: make sure there is a "," after each "}" until the last "}" to ensure all apps are installed. 
	: you need to use the specific package name as listed in the winget repository
	: winget search "*app name*" will return list of all available versions of the application. 
		:: The * * act as wild cards for your query. #>
<# NOTES: 
	: for quick single installs use the standard installation command below.
		: Add app package name in the "". 
	: If you do not include the --silent switch, it will give you verbose installation progress by default. 
	: The --accept-source-agreements is used to auto select "yes" to use the ms store and allow the command to run automatically.
winget.exe install "" --scope machine --accept-source-agreements
	#>


#region other installers
## INSTALL OFFICE 365 ##
	# NOTE: needs the additional parameters to prevent GUI popup. 
	# NOTE: Be sure to have both the .exe and .xml file in the $sources folder.
	# NOTE: Change $sources directory as needed: 
<#
	$sources = "C:\Sources"
	$Office365InstallPath = "$sources\OfficeSetup.exe"
	$configurationFilePath = "$sources\O365Configuration.xml"
	$arguments = "/configure $configurationFilePath"
Start-Process -FilePath $Office365InstallPath -ArgumentList $arguments -Wait 
#>

# install Sonicwall NetExtender:
# msiexec.exe /i "D:\Scripts\NetExtender-x64-10.2.341.msi" /qn /norestart server=#.#.#.# domain=LocalDomain EDITABLE=TRUE netlogon=true ALLUSERS=2
	<# notes:
	: /qn = silent install 
	: /norestart = does not restart PC after install
	: server = public IP address
	: domain = LocalDomain always
	: ALLUSERS=2 installs this for all users on the PC; case sensitive command.
	#> 
#endregion other installers

