# Get Bitlocker status
$bitlockerstatus = @()
try {
    $bitlockerstatus = Get-BitlockerVolume -ErrorAction Stop | Where-Object { ($_.ProtectionStatus -ne 'On') -and ($_.VolumeType -eq 'OperatingSystem') }
}
catch {
    $_ | Write-Error
    Exit 1
}
if ($bitlockerstatus) {
    Write-Host "Not enabled!"
    Exit 1
}
else {
    Write-Host "Bitlocker enabled."
    Exit 0
}