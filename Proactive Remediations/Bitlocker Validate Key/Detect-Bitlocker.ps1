try {
    $Result = (Get-BitLockerVolume -MountPoint $env:SystemDrive).KeyProtector
    $Recoverykey = $result.recoverypassword
    if ($Recoverykey) {
        Write-Output "Bitlocker recovery key available '$Recoverykey'"
        exit 0
    }
    else {
        Write-Output "No bitlocker recovery key available, starting remediation"
        exit 1
    }
}
catch {
    Write-Warning "Value Missing"
    exit 1
}