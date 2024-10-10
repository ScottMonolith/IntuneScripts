function Get-MultipleRegistryKeys { 
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$RegistrySettings
    )

    foreach ($setting in $RegistrySettings) {
        $RegistryPath = $setting.RegistryPath
        $KeyName = $setting.KeyName
        $ValueData = $setting.ValueData
        try {
            $null = Get-ItemPropertyValue -Path "$RegistryPath" -Name $KeyName
        }
        catch {
            Write-Host "Key could not be found."
            return $false
        }
        # Check if the registry key has the correct setting
        if ($ValueData -ne (Get-ItemPropertyValue -Path "$RegistryPath" -Name $KeyName)) {
            # Return false if the registry key doesn't exist
            Write-Host "Key '$RegistryPath\$KeyName' doesn't have the correct setting."
            return $false
        }
        else {
            $true
        }
    }
}

# Define an array of registry settings to set
$registrySettings = @(
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\AES 128/128"
        KeyName = "Enabled"
        ValueType = "DWord"
        ValueData = 4294967295
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\AES 256/256"
        KeyName = "Enabled"
        ValueType = "DWord"
        ValueData = 4294967295
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\DES 56/56"
        KeyName = "Enabled"
        ValueType = "DWord"
        ValueData = 0
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\NULL"
        KeyName = "Enabled"
        ValueType = "DWord"
        ValueData = 0
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC2 128/128"
        KeyName = "Enabled"
        ValueType = "DWord"
        ValueData = 0
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC2 40/128"
        KeyName = "Enabled"
        ValueType = "DWord"
        ValueData = 0
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC2 56/128"
        KeyName = "Enabled"
        ValueType = "DWord"
        ValueData = 0
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Hashes\MD5"
        KeyName = "Enabled"
        ValueType = "DWord"
        ValueData = 4294967295
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Hashes\SHA"
        KeyName = "Enabled"
        ValueType = "DWord"
        ValueData = 4294967295
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Hashes\SHA256"
        KeyName = "Enabled"
        ValueType = "DWord"
        ValueData = 4294967295
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Hashes\SHA384"
        KeyName = "Enabled"
        ValueType = "DWord"
        ValueData = 4294967295
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Hashes\SHA512"
        KeyName = "Enabled"
        ValueType = "DWord"
        ValueData = 4294967295
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\KeyExchangeAlgorithms\Diffie-Hellman"
        KeyName = "Enabled"
        ValueType = "DWord"
        ValueData = 0
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\KeyExchangeAlgorithms\ECDH"
        KeyName = "Enabled"
        ValueType = "DWord"
        ValueData = 4294967295
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\KeyExchangeAlgorithms\PKCS"
        KeyName = "Enabled"
        ValueType = "DWord"
        ValueData = 4294967295
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\Multi-Protocol Unified Hello\Client"
        KeyName = "DisabledByDefault"
        ValueType = "DWord"
        ValueData = 1
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\Multi-Protocol Unified Hello\Client"
        KeyName = "Enabled"
        ValueType = "DWord"
        ValueData = 0
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\Multi-Protocol Unified Hello\Server"
        KeyName = "DisabledByDefault"
        ValueType = "DWord"
        ValueData = 1
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\Multi-Protocol Unified Hello\Server"
        KeyName = "Enabled"
        ValueType = "DWord"
        ValueData = 0
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\PCT 1.0\Client"
        KeyName = "DisabledByDefault"
        ValueType = "DWord"
        ValueData = 1
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\PCT 1.0\Client"
        KeyName = "Enabled"
        ValueType = "DWord"
        ValueData = 0
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\PCT 1.0\Server"
        KeyName = "DisabledByDefault"
        ValueType = "DWord"
        ValueData = 1
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\PCT 1.0\Server"
        KeyName = "Enabled"
        ValueType = "DWord"
        ValueData = 0
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client"
        KeyName = "DisabledByDefault"
        ValueType = "DWord"
        ValueData = 1
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client"
        KeyName = "Enabled"
        ValueType = "DWord"
        ValueData = 0
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server"
        KeyName = "DisabledByDefault"
        ValueType = "DWord"
        ValueData = 1
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server"
        KeyName = "Enabled"
        ValueType = "DWord"
        ValueData = 0
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client"
        KeyName = "DisabledByDefault"
        ValueType = "DWord"
        ValueData = 1
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client"
        KeyName = "Enabled"
        ValueType = "DWord"
        ValueData = 0
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server"
        KeyName = "DisabledByDefault"
        ValueType = "DWord"
        ValueData = 1
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server"
        KeyName = "Enabled"
        ValueType = "DWord"
        ValueData = 0
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client"
        KeyName = "DisabledByDefault"
        ValueType = "DWord"
        ValueData = 1
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client"
        KeyName = "Enabled"
        ValueType = "DWord"
        ValueData = 0
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server"
        KeyName = "DisabledByDefault"
        ValueType = "DWord"
        ValueData = 1
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server"
        KeyName = "Enabled"
        ValueType = "DWord"
        ValueData = 0
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client"
        KeyName = "DisabledByDefault"
        ValueType = "DWord"
        ValueData = 1
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client"
        KeyName = "Enabled"
        ValueType = "DWord"
        ValueData = 0
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server"
        KeyName = "DisabledByDefault"
        ValueType = "DWord"
        ValueData = 1
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server"
        KeyName = "Enabled"
        ValueType = "DWord"
        ValueData = 0
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client"
        KeyName = "DisabledByDefault"
        ValueType = "DWord"
        ValueData = 0
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client"
        KeyName = "Enabled"
        ValueType = "DWord"
        ValueData = 4294967295
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server"
        KeyName = "DisabledByDefault"
        ValueType = "DWord"
        ValueData = 0
    },
    @{
        RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server"
        KeyName = "Enabled"
        ValueType = "DWord"
        ValueData = 4294967295
    }
)

# Call the function to get the registry settings
Get-MultipleRegistryKeys -RegistrySettings $registrySettings
