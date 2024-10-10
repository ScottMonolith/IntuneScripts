# Remove MS Teams 'Personal'
$MSTeams = "MicrosoftTeams"
$WinPackage = Get-AppxPackage | Where-Object {$_.Name -eq $MSTeams}
$ProvisionedPackage = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $WinPackage }

If ($WinPackage) {
    Remove-AppxPackage -Package $WinPackage.PackageFullName
}

If ($ProvisionedPackage) {
    Remove-AppxProvisionedPackage -online -Packagename $ProvisionedPackage.Packagename
}

$WinPackageCheck = Get-AppxPackage | Where-Object {$_.Name -eq $MSTeams}
$ProvisionedPackageCheck = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $WinPackage }

If (($WinPackageCheck) -or ($ProvisionedPackageCheck)) {
    throw
}