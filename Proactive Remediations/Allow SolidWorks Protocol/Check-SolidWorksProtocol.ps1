# Define registry path
$RegistryPath = "HKCU:\SOFTWARE\Policies\Microsoft\Office\16.0\Common\Security\Trusted Protocols\All Applications\conisio:"

if (Test-Path -Path $RegistryPath) {
    # Return 0 if the path exists
    Write-Host "Registry path does exist."
    Exit 0
}
else {
    # Return 1 if the path does not exist (and run the remediation)
    Write-Host "Registry path does not exist."
    Exit 1
}