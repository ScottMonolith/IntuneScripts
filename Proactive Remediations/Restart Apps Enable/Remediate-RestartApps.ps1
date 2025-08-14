# Enable the 'Automatically save my restartable apps and restart them when I sign back in' setting
try {
    # Reg keys
    $RegistryPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    $RegistryKey = "RestartApps"

    # Is it already remediated

    $Value = Get-ItemProperty -Path $RegistryPath -Name $RegistryKey | Select-Object -ExpandProperty $RegistryKey
    if ($Value -ne 1) {
        Write-Output "Key $RegistryPath\$RegistryKey is not equals to 1. Remediating..."
        Set-ItemProperty -Path $RegistryPath -Name $RegistryKey -Value 1 | Out-Null
        Write-Output "Key $RegistryPath\$RegistryKey has been updated to 1."
    } else {
        Write-Output "Key $RegistryPath\$RegistryKey is already equals to 1. No action needed."
    }
    exit 0
} catch {
    Write-Error "Error : $_"
    exit 1
}