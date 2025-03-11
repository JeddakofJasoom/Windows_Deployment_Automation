#region	WINGET
	
#####Install 'NuGet' package if missing from system, depending on Windows version.#####
	$ConfirmPreference = 'None'
    Write-Host "Installing latest version of 'NuGet' package from Microsoft" -ForegroundColor Yellow
	Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

###RUN WINGET TO INSTALL SPECIFIC APPLICATIONS.###
Write-Host "Running 'WinGet' to install specific software applications." -ForegroundColor Yellow 
# Define the applications to install (name and corresponding winget package)
$apps = @(
	@{Name="Powershell 7"; Package="microsoft.powershell"},
	@{Name="Google Chrome"; Package="Google.Chrome"},
	@{Name="Adobe Acrobat Reader"; Package="adobe.acrobat.reader.64-bit"},
#Uncomment and add more applications as needed:	
#	@{Name="Dell Command Update"; Package="Dell.CommandUpdate"}
#	@{Name="Lenovo Commercial Vantage"; Package="9NR5B8GVVM13"},
#	@{Name="Adobe Acrobat Pro"; Package="adobe.acrobat.Pro"},
#	@{Name="Splashtop Streamer"; Package="Splashtop.SplashtopStreamer"},
#	@{Name="Zoom Workplace "; Package="Zoom.Zoom"},
#   @{Name="VLC Media Player"; Package="VideoLAN.VLC"}
#   @{Name="Firefox"; Package="Mozilla.Firefox"}
#	@{Name="Bluebeam Revu 20"; Package="Bluebeam.Revu.20"},
#	@{Name="Bluebeam Revu 21"; Package="Bluebeam.Revu.21"},
#	@{Name="BluebeamOCR 21"; Package="Bluebeam.BluebeamOCR.21"},
#	@{Name=" "; Package=" "},
# 	@{Name=" "; Package=" "},
)
	<#NOTES: 
		: YOU HAVE TO REMOVE THE " , " ON THE LAST APPLICATION OR THIS WILL FAIL!!!
		: make sure there is a "," after each "}" until the last "}" to ensure all apps are installed. 
		: you need to use the specific package name as listed in the winget repository
		: winget search "*app name*" will return list of all available versions of the application. 
			:: The * * act as wild cards for your query. #>

## INSTALL ALL APPLICATIONS LISTED ABOVE.## 
foreach ($app in $apps) { #attempt to install all applications listed in above function
winget.exe install $app.Package --scope machine --silent --accept-source-agreements
winget.exe upgrade --all
}
	<# NOTES: 
		: for quick single installs use the standard installation command below.
			: Add app package name in the "". 
		: If you do not include the --silent switch, it will give you verbose installation progress by default. 
		: The --accept-source-agreements is used to auto select "yes" to use the ms store and allow the command to run automatically.
	winget.exe install "" --scope machine --accept-source-agreements
		#>
#endregion WinGet

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

