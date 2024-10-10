# Create Folder for logs
$Logs = "$($env:programdata)\Microsoft\IntuneManagementExtension\Logs"
If (!(Test-Path $Logs)) {
    New-Item -Path "$Logs" -ItemType Directory
}

function Get-TimeStamp {
    return Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
}

# Starts the log
Start-Transcript -Path "$Logs\MilestoneXProtect_Uninstall.log"

Write-Output "$(Get-TimeStamp) - Checking if Milestone XProtect is installed..."
$MStoneX = Get-ChildItem 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall', 'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall' -ErrorAction SilentlyContinue |
    Get-ItemProperty |
    Where-Object { $_.DisplayName -like "*Milestone XProtect Smart Client*" }

if ($MStoneX) {
    Write-Output "$(Get-TimeStamp) - '$($MStoneX.DisplayName)' is installed, uninstalling..."
    foreach ($Uninstall in $MStoneX.UninstallString) {
        if ($Uninstall -like '*msiexec*') {
            Write-Output "$(Get-TimeStamp) - Skipping msiexec uninstall..."
            #$uninstallGUID = "{" + $Uninstall.Split("{")[-1]
	        #Start-Process -FilePath "msiexec.exe" -ArgumentList  "/X", $uninstallGUID, "/qn" -Wait -WindowStyle Hidden
        }
        else {
            Write-Output "$(Get-TimeStamp) - Uninstalling non-MSI (VideoOS)..."
            Start-Process -FilePath $Uninstall.Split("--")[0] -Argumentlist "--uninstall" -Wait #-WindowStyle Hidden
        }
    }
}
else {
    Write-Output "$(Get-TimeStamp) - Could not find any product installed with 'Milestone XProtect Smart Client' in the name."
    Exit
}

if (Test-Path "${env:programfiles(x86)}\Common Files\VideoOS") {
    Write-Output "$(Get-TimeStamp) - Removing leftover folder '${env:programfiles(x86)}\Common Files\VideoOS'..."
    Remove-Item -Path "${env:programfiles(x86)}\Common Files\VideoOS" -Force -Recurse
}

if (!(Test-Path "$($env:ProgramFiles)\Milestone\XProtect Smart Client\Client.exe")) {
    Write-Output "$(Get-TimeStamp) - $($MstoneX.Name) Uninstall complete!"
}
else {
    Write-Output "$(Get-TimeStamp) - '$($env:ProgramFiles)\Milestone\XProtect Smart Client\Client.exe' still exists, please investigate uninstall failures."
}
Stop-Transcript