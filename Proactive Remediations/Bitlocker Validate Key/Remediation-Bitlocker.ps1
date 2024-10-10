try {
    $BLinfo = Get-Bitlockervolume
    if ($BLinfo.EncryptionPercentage -eq '100')
    {
        $Result = (Get-BitLockerVolume -MountPoint $env:SystemDrive).KeyProtector
        $Recoverykey = $result.recoverypassword	
        Write-Output "Bitlocker recovery key $recoverykey"
        Exit 0
    }
    if ($BLinfo.EncryptionPercentage -ne '100' -and $BLinfo.EncryptionPercentage -ne '0')
    {
        Resume-BitLocker -MountPoint $env:SystemDrive
        $BLV = Get-BitLockerVolume -MountPoint $env:SystemDrive | Select-Object *
        $KeyProtectorID = $BLV.KeyProtector | Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' }
        BackupToAAD-BitLockerKeyProtector -MountPoint "$($env:SystemDrive)" -KeyProtectorId $KeyProtectorID
        Exit 1
    }
    if ($BLinfo.VolumeStatus -eq 'FullyEncrypted' -and $BLinfo.ProtectionStatus -eq 'Off')
    {
        Resume-BitLocker -MountPoint $env:SystemDrive
        $BLV = Get-BitLockerVolume -MountPoint $env:SystemDrive | Select-Object *
        $KeyProtectorID = $BLV.KeyProtector | Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' }
        BackupToAAD-BitLockerKeyProtector -MountPoint "$($env:SystemDrive)" -KeyProtectorId $KeyProtectorID
        Exit 1
    }
    if ($BLinfo.EncryptionPercentage -eq '0')
    {
        Enable-BitLocker -MountPoint $env:SystemDrive -EncryptionMethod XtsAes256 -UsedSpaceOnly -SkipHardwareTest -RecoveryPasswordProtector
        $BLV = Get-BitLockerVolume -MountPoint $env:SystemDrive | Select-Object *
        $KeyProtectorID = $BLV.KeyProtector | Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' }
        BackupToAAD-BitLockerKeyProtector -MountPoint "$($env:SystemDrive)" -KeyProtectorId $KeyProtectorID
        Exit 1
    }
}
catch {
    Write-Warning "Value Missing"
	Exit 1
}