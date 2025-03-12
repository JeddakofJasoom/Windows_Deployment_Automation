#This second script removes the quick installer bloatware and configures several Windows 11 settings that are more appropriate for business use.
# modified from https://gist.github.com/redlttr/8b95df51fd472d459b5c3a3ae6c8f5ad

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


<# Additional that aren't in 24H2 Pro:
    '7EE7776C.LinkedInforWindows',
    'Microsoft.MinecraftUWP',
    'Facebook.Facebook',    
    'Microsoft.NetworkSpeedTest', 
    'Microsoft.Messaging',   
    'Microsoft.MicrosoftOfficeHub',     
    'Microsoft.MicrosoftPowerBIForWindows', 
    'Microsoft.Microsoft3DViewer',  
    'Microsoft.3DBuilder',
    'Microsoft.ConnectivityStore',
    'Microsoft.FreshPaint',       
    'Microsoft.CommsPhone',
    'Microsoft.Office.Sway',   
    'Microsoft.OfficeLens', 
    'Microsoft.Appconnector',
    'Microsoft.Print3D',    
    'Microsoft.OneConnect',    
    'Microsoft.BingFinance',
    'Microsoft.BingFoodAndDrink',     
    'Microsoft.BingWeather',  
    'Microsoft.Whiteboard',    
    'Microsoft.WindowsReadingList',   
    'Microsoft.BingHealthAndFitness',
    'Microsoft.SkypeApp',
    'Microsoft.BingNews',  
    'Microsoft.BingTranslator',    
    'Microsoft.BingSports', 
    'Microsoft.BingTravel', 
#>