$OS = Get-CimInstance Win32_OperatingSystem
$Uptime = (Get-Date) - ($OS.LastBootUpTime)

if ($Uptime.Days -ge 10){
    Write-Output "Uptime $($Uptime.Days) days, NAG"
    Exit 1
}else {
    Write-Output "Uptime $($Uptime.Days) days, no nag"
    Exit 0
}