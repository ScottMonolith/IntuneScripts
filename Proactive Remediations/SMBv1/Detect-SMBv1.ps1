try {
    $SMBv1 = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol
}
catch {
    $_ | Write-Error
    Exit 1
}
if ($SMBv1.State -ne 'Disabled') {
    Write-Host "SMBv1 is '$($SMBv1.State)'!"
    Exit 1
}
else {
    Write-Host "SMBv1 is disabled."
    Exit 0
}