# Detect the status of the 'Automatically save my restartable apps and restart them when I sign back in' setting

# Default Exit Code (1 = fail)
$exitCode = 1

try {
    # Reg Key Used
    $registryPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    $registryKey  = "RestartApps"
    
    # Get key
    $regProps = Get-ItemProperty -Path $registryPath -ErrorAction SilentlyContinue
    
    if (-not $regProps) {
        Write-Output "Key doesn't exist"
    }
    elseif (-not ($regProps.PSObject.Properties.Name -contains $registryKey)) {
        Write-Output "Property doesn't exist"
    }
    else {
        $value = $regProps.$registryKey
        
        if ($value -eq 1) {
            Write-Output "Key '$registryPath\$registryKey' equals 1."
            $exitCode = 0
        }
        else {
            Write-Output "Key '$registryPath\$registryKey' Does not equals 1. Value is $value."
        }
    }
}
catch {
    Write-Error "Error : $_"
}
finally {
    exit $exitCode
}