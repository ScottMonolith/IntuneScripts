if (Get-AppxPackage -AllUsers -Name Microsoft.Edge.GameAssist) {
    Write-Host "GameAssist exists, remove!"
    exit 1
}
else {
    Write-Host "GameAssist does not exist."
    exit 0
}