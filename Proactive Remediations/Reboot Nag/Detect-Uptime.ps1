$Uptime= get-computerinfo | Select-Object OSUptime 
if ($Uptime.OsUptime.Days -ge 5){
    Write-Output "Uptime $($Uptime.OsUptime.Days) days, NAG"
    Exit 1
}else {
    Write-Output "Uptime $($Uptime.OsUptime.Days) days, no nag"
    Exit 0
}