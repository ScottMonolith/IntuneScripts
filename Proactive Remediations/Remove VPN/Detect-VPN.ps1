# Define the server address
$serverAddress = 'ne-mjgbbcwkjn.dynamic-m.com'

# Get all VPN connections and filter based on the server address
$AllUservpnConnection = Get-VpnConnection -AllUserConnection -ErrorAction SilentlyContinue | Where-Object { $_.ServerAddress -eq $serverAddress }
$UservpnConnection = Get-VpnConnection -ErrorAction SilentlyContinue | Where-Object { $_.ServerAddress -eq $serverAddress }

if ($AllUservpnConnection) {
    Write-Output "All user VPN exists!"
    Exit 1
}
if ($UservpnConnection) {
    Write-Output "User VPN exists!"
    Exit 1
}
else {
    Write-Output "No old VPN exists."
    Exit 0
}