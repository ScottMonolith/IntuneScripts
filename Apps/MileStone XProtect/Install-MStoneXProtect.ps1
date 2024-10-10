# Create Folder for logs
$Logs = "$($env:programdata)\Microsoft\IntuneManagementExtension\Logs"
If (!(Test-Path $Logs)) {
    New-Item -Path "$Logs" -ItemType Directory
}

function Get-TimeStamp {
    return Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
}

# Starts the log
Start-Transcript -Path "$Logs\MilestoneXProtect_Install.log"

Write-Output "$(Get-TimeStamp) - Starting install of Milestone XProtect..."
Start-Process -FilePath "XProtect Smart Client 2023 R2 Installer x64.exe" -Argumentlist "--quiet" -Wait -WindowStyle Hidden
if (Test-Path "$($env:ProgramFiles)\Milestone\XProtect Smart Client\Client.exe") {
    Write-Output "$(Get-TimeStamp) - Install of Milestone XProtect complete!"
}
else {
    Write-Output "$(Get-TimeStamp) - Install of Milestone XProtect failed, '$($env:ProgramFiles)\Milestone\XProtect Smart Client\Client.exe' is missing.  Please investigate!"
}
Stop-Transcript