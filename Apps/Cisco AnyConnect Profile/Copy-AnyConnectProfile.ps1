$Logs = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs"

# Create Folder for logs
$Logs = "$($env:programdata)\Microsoft\IntuneManagementExtension\Logs"
If (Test-Path $Logs) {

}
Else {
    New-Item -Path "$Logs" -ItemType Directory
}

# Starts the log
Start-Transcript -Path "$Logs\CiscoSecureClient_Install-Profile.log" 

$ProfileInstall = ".\preferences.xml"
$ProfileLocation = "C:\Users\$($env:USERNAME)\AppData\Local\Cisco\Cisco Secure Client\VPN"

if (Test-Path $ProfileLocation) {
    Write-Output "Profile folder '$ProfileLocation' already exists." 
}
else {
    try {
        $null = New-Item -Path $ProfileLocation -ItemType directory -Force -ErrorAction Stop
    }
    catch {
        $_ | Write-Error
    }
    if (Test-Path $ProfileLocation) {
        Write-Output "Profile folder '$ProfileLocation' created."
    }
}

$profilelocationfile = "$Profilelocation\preferences.xml"

if (Test-Path $profilelocationfile) {
    Write-Output "Profile file '$profilelocationfile' exists, attempting overwrite."
    try {
        Copy-Item $ProfileInstall -Destination $Profilelocation -Force -ErrorAction Stop
    }
    catch {
        $_ | Write-Error
    }
    if (Test-Path $profilelocationfile) {
        Write-Output "Profile copied to '$profilelocationfile'."
    }
}
else {
    try {
        Copy-Item $ProfileInstall -Destination $Profilelocation -ErrorAction Stop
    }
    catch {
        $_ | Write-Error
    }
    if (Test-Path $profilelocationfile) {
        Write-Output "Profile copied to '$profilelocationfile'."
    }
}

# End of log
Stop-Transcript

# Display a message indicating the script has finished
Write-Output "Cisco Secure Client profile script completed."