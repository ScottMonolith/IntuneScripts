$RegistryPath = 'HKLM:\SOFTWARE\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\'
$KeyName = 'bMIPLabelling'
$ValueData = '1'

try {
    $null = Get-ItemProperty -Path "$RegistryPath" -Name $KeyName -ErrorAction Stop
}
catch {
    Write-Host "Key could not be found."
    exit 1
}
$value = (Get-ItemProperty -Path "$RegistryPath" -Name $KeyName -ErrorAction SilentlyContinue).$KeyName
$ValueType = $value.GetType().Name

if ($ValueData -ne (Get-ItemPropertyValue -Path "$RegistryPath" -Name $KeyName)) {
    # Return false if the registry key has the incorrect setting
    Write-Host "Key doesn't have the correct setting."
    exit 1
}
elseif ($ValueType -ne 'Int32') {
    # Return false if the registry key is the wrong type
    Write-Host "Key exists but is the wrong type."
    exit 1
}
else {
    Write-Host "Good to go"
    exit 0
}