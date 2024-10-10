# Create Folder for logs
$Logs = "$($env:programdata)\Microsoft\IntuneManagementExtension\Logs"
If (!(Test-Path $Logs)) {
    New-Item -Path "$Logs" -ItemType Directory
}

function Get-TimeStamp {
    return Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
}

# Starts the log
Start-Transcript -Path "$Logs\PIDataLink_Uninstall.log"

Write-Output "$(Get-TimeStamp) - Checking if PI AF Client 2023 is installed..."
$AF = Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -eq "PI AF Client 2023"}

Write-Output "$(Get-TimeStamp) - Checking if PI Datalink 2023 x64 is installed..."
$PIDL64 = Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -eq "AVEVA PI DataLink 2023 x64"}

Write-Output "$(Get-TimeStamp) - Checking if PI Datalink 2023 x86 is installed..."
$PIDL32 = Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -eq "AVEVA PI DataLink 2023 x86"}

if ($AF) {
    Write-Output "$(Get-TimeStamp) - PI AF Client 2023 is installed, uninstalling..."
    $null = $AF.Uninstall()
}
if ($PIDL64) {
    Write-Output "$(Get-TimeStamp) - PI Datalink 2023 x64 is installed, uninstalling..."
    $null = $PIDL64.Uninstall()
}
if ($PIDL32) {
    Write-Output "$(Get-TimeStamp) - PI Datalink 2023 x86 is installed, uninstalling..."
    $null = $PIDL32.Uninstall()
}
if (Test-Path "$(${env:ProgramFiles(x86)})\PIPC") {
    Write-Output "$(Get-TimeStamp) - Folder '$(${env:ProgramFiles(x86)})\PIPC' still exists, deleting recursively..."
    Remove-Item -Force -Recurse -Path "$(${env:ProgramFiles(x86)})\PIPC"
}
if (!($AF) -and !($PIDL64) -and !($PIDL32)) {
    Write-Output "$(Get-TimeStamp) - No PI Datalink or PI AF Client software found, exiting without doing anything."
}
else {
    Write-Output "$(Get-TimeStamp) - Uninstallation complete!"
}

Stop-Transcript