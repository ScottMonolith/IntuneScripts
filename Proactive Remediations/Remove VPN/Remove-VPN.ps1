# Define the server address to remove
$serverAddress = 'ne-mjgbbcwkjn.dynamic-m.com'

# Get all VPN connections and filter based on the server address
$AllUservpnConnection = Get-VpnConnection -AllUserConnection -ErrorAction SilentlyContinue | Where-Object { $_.ServerAddress -eq $serverAddress }
$UservpnConnection = Get-VpnConnection -ErrorAction SilentlyContinue | Where-Object { $_.ServerAddress -eq $serverAddress }

if ($AllUservpnConnection) {
    foreach ($vpn in $AllUservpnConnection) {
        Remove-VpnConnection -Name $vpn.Name -AllUserConnection -Force
    }
}
if ($UservpnConnection) {
    foreach ($vpn in $UservpnConnection) {
        Remove-VpnConnection -Name $vpn.Name -Force
    }
}