# Define the name of the application to uninstall
$appName = "Dell SupportAssist"

# Get the application information
$app = Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE Name = '$appName'"

# Check if the application exists
if ($app) {
    # Uninstall the application
    $app.Uninstall()
    Write-Output "$appName has been successfully uninstalled."
} else {
    Write-Output "$appName is not installed on this system."
}
