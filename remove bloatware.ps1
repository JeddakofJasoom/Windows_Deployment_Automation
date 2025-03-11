# List of apps to remove
$Packages = @(
   'Microsoft.OutlookForWindows',
   'Microsoft.GetHelp',
   'Microsoft.XboxGamingOverlay',
   'Microsoft.BingWeather',
   'Microsoft.MicrosoftSolitaireCollection',
   'Microsoft.Todos',
   'Microsoft.PowerAutomateDesktop',
   'Microsoft.BingNews',
   'Microsoft.BingSearch',
   'Microsoft.GamingApp',
   'Microsoft.ZuneMusic',
   'Clipchamp.Clipchamp',
   'Microsoft.Copilot',
   'Microsoft.YourPhone',
   'Microsoft.Windows.DevHome',
   'Microsoft.WindowsFeedbackHub',
   'Microsoft.GetHelp',
   'Microsoft.Getstarted',
   'microsoft.windowscommunicationsapps',
   'Microsoft.WindowsMaps',
   'Microsoft.MixedReality.Portal',
   'Microsoft.People',
   'Microsoft.Wallet',
   'Microsoft.Xbox.TCUI',
   'Microsoft.XboxApp',
   'Microsoft.XboxGameOverlay',
   'Microsoft.XboxGamingOverlay',
   'Microsoft.XboxIdentityProvider',
   'Microsoft.XboxSpeechToTextOverlay'
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
        }
    }
    catch {
        $FailedPackages += "$Package (Failed to Remove - $($_.Exception.Message))"
    }
}

# Display Results
Write-Host "`n=== Removal Summary ===" -ForegroundColor Cyan
Write-Host "`nSuccessfully Removed Packages:" -ForegroundColor Green
$RemovedPackages | ForEach-Object { Write-Host $_ }

Write-Host "`nFailed to Remove Packages:" -ForegroundColor Red
$FailedPackages | ForEach-Object { Write-Host $_ }

