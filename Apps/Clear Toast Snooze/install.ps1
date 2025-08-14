Function Get-LoggedInUser {
    try {
        $SessionList = quser 2>$null
        if ($SessionList) {
            $UserInfo = foreach ($Session in ($SessionList | Select-Object -Skip 1)) {
                $Session = $Session.ToString().trim() -replace '\s+', ' ' -replace '>', ''
                if ($Session.Split(' ')[3] -eq 'Active') {
                    [PSCustomObject]@{
                        UserName     = $session.Split(' ')[0]
                        SessionName  = $session.Split(' ')[1]
                        SessionID    = $Session.Split(' ')[2]
                        SessionState = $Session.Split(' ')[3]
                        IdleTime     = $Session.Split(' ')[4]
                        LogonTime    = $session.Split(' ')[5, 6, 7] -as [string] -as [datetime]
                    }
                } else {
                    [PSCustomObject]@{
                        UserName     = $session.Split(' ')[0]
                        SessionName  = $null
                        SessionID    = $Session.Split(' ')[1]
                        SessionState = 'Disconnected'
                        IdleTime     = $Session.Split(' ')[3]
                        LogonTime    = $session.Split(' ')[4, 5, 6] -as [string] -as [datetime]
                    }
                }
            }
            $UserInfo | Sort-Object LogonTime
        }
    } catch {
        Write-Error $_.Exception.Message
    }
}

if (($pshome -like "*syswow64*") -and ((Get-WmiObject Win32_OperatingSystem).OSArchitecture -like "64*")) {
    write-warning "Restarting script under 64 bit powershell"
 
    # relaunch this script under 64 bit shell
    & (join-path ($pshome -replace "syswow64", "sysnative")\powershell.exe) -file $myinvocation.mycommand.Definition @args
 
    # This will exit the original powershell process. This will only be done in case of an x86 process on a x64 OS.
    exit
}

# Create Folder for logs
$Logs = "$($env:programdata)\Microsoft\IntuneManagementExtension\Logs"
If (!(Test-Path $Logs)) {
    New-Item -Path "$Logs" -ItemType Directory
}

# Starts the log
Start-Transcript -Path "$Logs\ClearToastSnooze_Install.log" 

$TaskName = "Clear Snoozed Toasts v1.0.3"
$User = (Get-LoggedInUser).UserName

if (!(Test-Path C:\Users\$User\AppData\Roaming\ToastNotificationScript\Scripts\)) {
    New-Item -Path C:\Users\$User\AppData\Roaming\ToastNotificationScript\Scripts\ -ItemType Directory
}
Copy-Item ".\Clear-SnoozedToasts.ps1" C:\Users\$User\AppData\Roaming\ToastNotificationScript\Scripts\
Copy-Item ".\hiddenPoSH.vbs" C:\Users\$User\AppData\Roaming\ToastNotificationScript\Scripts\

# Check if there's any leftovers of old scheduled tasks
$OldTasks = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object TaskName -like 'Clear Snoozed Toasts*'
if ($OldTasks) {
    foreach ($OldTask in $OldTasks) {
        Unregister-ScheduledTask -TaskName $OldTask.TaskName -Confirm:$false
    }
}

# Register a new Scheduled Task using the XML
Register-ScheduledTask -xml (Get-Content .\ClearSnoozedToastsTask.xml | Out-String) -TaskName $TaskName -User "$($env:userdomain)\$User" -Force

Stop-Transcript