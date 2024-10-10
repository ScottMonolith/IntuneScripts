# Install Folder paths to change for the new folders
$InstallFilePath = "C:\temp\Cisco\"

# MSI to change for the new MSIs
$MobilityInstaller = "$InstallFilePath\cisco-secure-client-win-5.0.01242-core-vpn-predeploy-k9.msi"
$SBLInstaller = "$InstallFilePath\cisco-secure-client-win-5.0.01242-sbl-predeploy-k9.msi"
$DARTInstaller= "$InstallFilePath\cisco-secure-client-win-5.0.01242-dart-predeploy-k9.msi"

#Zip path = Comment out which one is not needed. NB the .\ is the one needed for the Intune app
$ZipFile = ".\CiscoVPN.zip"

# Create Folder for logs
$Logs = "$($env:programdata)\Microsoft\IntuneManagementExtension\Logs"
If (Test-Path $Logs) {

}
Else {
    New-Item -Path "$Logs" -ItemType Directory
}

# Starts the log
Start-Transcript -Path "$Logs\CiscoSecureClient_Uninstall.log" 

# Display a message indicating the start of the script
Write-Output "Starting Cisco Secure Client uninstallation script..."

# Copies the Cisco files
Write-Output "Copying Cisco files..."
$ZipPath = "$InstallFilePath\CiscoVPN.zip"
If (Test-Path $InstallFilePath) {
    Write-Host "Install file path '$InstallFilePath' exists."    
}
Else {
    try {
        $null = New-Item -ItemType Directory -Force -Path $InstallFilePath -ErrorAction Stop
    }
    catch {
        $_ | Write-Error
    }
}

try {
    $null = Copy-Item $ZipFile -Destination $ZipPath -ErrorAction Stop
}
catch {
    $_ | Write-Error
}

try {
    $null = Expand-Archive -LiteralPath $ZipPath -DestinationPath $InstallFilePath -Force -ErrorAction Stop
}
catch {
    $_ | Write-Error
}

Write-Output "Cisco files copied & extracted."

try {
    $null = Remove-Item -LiteralPath $ZipPath -Force -ErrorAction Stop
}
catch {
    $_ | Write-Error
}
Write-Output "Cleaned up Zip file."

Write-Output "Start uninstall"

$msiFiles = @(
    $MobilityInstaller,
    $SBLInstaller,
    $DARTInstaller
)

foreach ($msiFile in $msiFiles) {
    Write-Output "Uninstalling $msiFile..."
    $shortlogname = $msifile.replace($InstallFilePath,"").replace("\","").replace(".msi","").replace("-predeploy-k9","")
    $msiExec = Start-Process msiexec -ArgumentList "/x `"$msiFile`" /qn /norestart /l*v `"$Logs\$shortlogname`_uninstall.log`"" -Wait -PassThru

    if ($msiExec.ExitCode -eq 0) {
        Write-Output "$msiFile uninstalled successfully"
    } else {
        Write-Output "Failed to uninstall '$msiFile'. Exit code: '$($msiExec.ExitCode)'"
        # Handle exit codes that should not trigger a reboot
        if ($msiExec.ExitCode -ne 1641 -and $msiExec.ExitCode -ne 3010) {
            Write-Output "Error: '$msiFile' uninstallation failed and will not trigger a reboot."
        }
    }
}

$GlobalProfileLocation = "$($env:programdata)\Cisco\Cisco Secure Client\"

if (Test-Path $GlobalProfileLocation) {
    try {
        Remove-Item -Path $GlobalProfileLocation -Force -Recurse -ErrorAction Stop
    }
    catch {
        $_ | Write-Error
    }
}
else {
    Write-Output "Profile location '$GlobalProfileLocation' does not exist."
}

try {
    Remove-Item -LiteralPath $InstallFilePath -Force -Recurse -ErrorAction Stop
}
catch {
    $_ | Write-Error
}
Write-Output "Cleaned up install folder '$InstallFilePath'."

# End of log
Stop-Transcript

# Display a message indicating the script has finished
Write-Output "Cisco Secure Client uninstallation script completed."