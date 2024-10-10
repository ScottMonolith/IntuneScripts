# Create Folder for logs
$Logs = "$($env:programdata)\Microsoft\IntuneManagementExtension\Logs"
If (!(Test-Path $Logs)) {
    New-Item -Path "$Logs" -ItemType Directory
}

function Get-TimeStamp {
    return Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
}

# Starts the log
Start-Transcript -Path "$Logs\PIDataLink_Install.log"

Write-Output "$(Get-TimeStamp) - Checking if any version of the PI AF Client is installed..."
$AF = Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -like "PI AF Client*"}

Write-Output "$(Get-TimeStamp) - Checking if any version of PI Datalink x64 is installed..."
$PIDL64 = Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -like "*PI DataLink * x64"}

Write-Output "$(Get-TimeStamp) - Checking if any version of PI Datalink x86 is installed..."
$PIDL32 = Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -like "*PI DataLink * x86"}

if ($AF) {
    Write-Output "$(Get-TimeStamp) - '$($AF.Name)' is installed, uninstalling..."
    $null = $AF.Uninstall()
}
if ($PIDL64) {
    Write-Output "$(Get-TimeStamp) - '$($PIDL64.Name)' is installed, uninstalling..."
    $null = $PIDL64.Uninstall()
}
if ($PIDL32) {
    Write-Output "$(Get-TimeStamp) - '$($PIDL32.Name)' is installed, uninstalling..."
    $null = $PIDL32.Uninstall()
}
if (!($AF) -and !($PIDL64) -and !($PIDL32)) {
    Write-Output "$(Get-TimeStamp) - No other versions found, continuing with installation..."
}

Write-Output "$(Get-TimeStamp) - Starting install of PI Datalink 2023 (and associated dependencies)..."

Start-Process -FilePath "Setup.exe" -Argumentlist "-f silent.ini" -Wait -WindowStyle Hidden

Write-Output "$(Get-TimeStamp) - Install of PI Datalink 2023 complete!"

Stop-Transcript