# Check for Microsoft bloatware/crapware

# List of built-in apps to remove
$UninstallPackages = @(
    "Microsoft.BingWeather"
    "Microsoft.Getstarted"
    "Microsoft.GetHelp"
    "Microsoft.Microsoft3DViewer"
    "Microsoft.MicrosoftOfficeHub"
    "Microsoft.MicrosoftSolitaireCollection"
    "Microsoft.MixedReality.Portal"
    "Microsoft.OneConnect"
    "Microsoft.SkypeApp"
    "Microsoft.windowscommunicationsapps"
    "Microsoft.WindowsFeedbackHub"
    "Microsoft.Xbox.TCUI"
    "Microsoft.XboxApp"
    "Microsoft.XboxGameOverlay"
    "Microsoft.XboxGamingOverlay"
    "Microsoft.XboxIdentityProvider"
    "Microsoft.XboxSpeechToTextOverlay"
    "Microsoft.YourPhone"
    "Microsoft.ZuneMusic"
    "Microsoft.ZuneVideo"
)

# List of programs to uninstall
$UninstallPrograms = @(
)
$user=whoami
$InstalledPackages = Get-AppxPackage -User $user | Where-Object {($UninstallPackages -contains $_.Name)}
$ProvisionedPackages = Get-AppxProvisionedPackage -Online | Where-Object {($UninstallPackages -contains $_.DisplayName)}
$InstalledPrograms = Get-Package | Where-Object {$UninstallPrograms -contains $_.Name}

if ($InstalledPackages -or $ProvisionedPackages -or $InstalledPrograms) {
    Write-Host "Bloatware Exists"
    Exit 1
}
else {
    Write-Host "No bloatware!"
    Exit 0
}