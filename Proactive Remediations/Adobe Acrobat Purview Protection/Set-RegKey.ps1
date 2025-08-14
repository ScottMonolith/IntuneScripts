$RegistryPath = 'HKLM:\SOFTWARE\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\'
$KeyName = 'bMIPLabelling'
$ValueType = "DWord"
$ValueData = '1'

if (-not (Test-Path -Path $RegistryPath)) {
    # Create the registry path if it doesn't exist
    New-Item -Path $RegistryPath -Force | Out-Null
}
$value = (Get-ItemProperty -Path "$RegistryPath" -Name $KeyName -ErrorAction SilentlyContinue).$KeyName
if ($value) {
    $ValueTypeTest = $value.GetType().Name
}

if (-not (Test-Path -Path "$RegistryPath\$KeyName")) {
    # Create the registry key if it doesn't exist
    New-ItemProperty -Path "$RegistryPath" -Name $KeyName -Value $ValueData -PropertyType $ValueType -Force | Out-Null
}
elseif ($ValueTypeTest -ne 'Int32') {
    # Change the registry key if it's the wrong type
    New-ItemProperty -Path "$RegistryPath" -Name $KeyName -Value $ValueData -PropertyType $ValueType -Force | Out-Null
}
else {
    # If the registry key exists, just update its value
    Set-ItemProperty -Path "$RegistryPath" -Name $KeyName -Value $ValueData
}