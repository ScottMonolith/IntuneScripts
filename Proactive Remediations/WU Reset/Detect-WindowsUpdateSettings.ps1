# Detect if Windows Update is misconfigured for Autopatch

$RegistryPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU\'
$KeyName = 'NoAutoUpdate'

try {
    $RegKey = Get-ItemProperty -Path "$RegistryPath" -Name $KeyName -ErrorAction Stop
}
catch {
    Write-Host "Key was not found!"
    exit 0
}

if ($RegKey) {
    # Return false if the registry key exists
    Write-Host "Key exists, reset WU settings!"
    exit 1
}