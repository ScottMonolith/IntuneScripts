$WURebootKey = Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -ErrorAction Ignore
if ($WURebootKey) {
    Write-Output "WU reboot pending, NAG"
    Exit 1
}
else {
    Write-Output "No WU reboot pending."
    Exit 0
}