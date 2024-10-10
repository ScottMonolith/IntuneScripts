$Uptime= get-computerinfo | Select-Object OSUptime 
if ($Uptime.OsUptime.Days -ge 7){
    Write-Output "!! '$($Uptime.OsUptime.Days)' days!!"
    Exit 1
}else {
    Write-Output "Recent reboot, '$($Uptime.OsUptime.Days)' days ago"
    Exit 0
}