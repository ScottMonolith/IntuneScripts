# Define registry path
$RegistryPath = "HKCU:\SOFTWARE\Policies\Microsoft\Office\16.0\Common\Security\Trusted Protocols\All Applications\conisio:"

if (-not (Test-Path -Path $RegistryPath)) {
    # Create the registry path if it doesn't exist
    New-Item -Path $RegistryPath -Force | Out-Null
}