# Remove Microsoft bloatware/crapware in Windows 10

# Custom logging function
function Write-Log {
    param (
        [Parameter(Mandatory=$true)]
        [string] $Message
    )

    $logFilePath = "$($env:ProgramData)\Microsoft\RemoveBloatware\RemoveW10Bloatware.log"
    Add-Content -Path $logFilePath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
}

# Create a tag file just so Intune knows this was installed
if (-not (Test-Path "$($env:ProgramData)\Microsoft\RemoveBloatware"))
{
    New-Item -ItemType Directory -Force -Path "$($env:ProgramData)\Microsoft\RemoveBloatware" > $null
}

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

# Print a warning for not found apps
$UninstallPackages | ForEach-Object {
    if (($_ -notin $InstalledPackages.Name) -and ($_ -notin $ProvisionedPackages.DisplayName)) {
        Write-Log -Message "Warning: App not found: [$_]"
    }
}

# Remove provisioned packages first
ForEach ($ProvPackage in $ProvisionedPackages) {

    Write-Log -Message "Attempting to remove provisioned package: [$($ProvPackage.DisplayName)]..."

    Try {
        Remove-AppxProvisionedPackage -PackageName $ProvPackage.PackageName -Online -ErrorAction Stop > $null
        Write-Log -Message "Successfully removed provisioned package: [$($ProvPackage.DisplayName)]"
    }
    Catch {
        Write-Log -Message "Warning: Failed to remove provisioned package: [$($ProvPackage.DisplayName)]"
    }
}

# Remove appx packages
ForEach ($AppxPackage in $InstalledPackages) {

    Write-Log -Message "Attempting to remove Appx package: [$($AppxPackage.Name)]..."

    Try {
        Remove-AppxPackage -Package $AppxPackage.PackageFullName -AllUsers -ErrorAction Stop > $null
        Write-Log -Message "Successfully removed Appx package: [$($AppxPackage.Name)]"
    }
    Catch {
        Write-Log -Message "Warning: Failed to remove Appx package: [$($AppxPackage.Name)]"
    }
}

# Remove installed programs
$InstalledPrograms | ForEach-Object {

    Write-Log -Message "Attempting to uninstall: [$($_.Name)]..."

    Try {
        $_ | Uninstall-Package -AllVersions -Force -ErrorAction Stop > $null
        Write-Log -Message "Successfully uninstalled: [$($_.Name)]"
    }
    Catch {
        Write-Log -Message "Warning: Failed to uninstall: [$($_.Name)]"
    }
}