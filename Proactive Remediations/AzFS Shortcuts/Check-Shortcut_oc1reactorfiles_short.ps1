# Define the name of the shortcut (without the .lnk extension)
$shortcutName = "OC1 Reactor Files Short"

# Define the path to the public desktop directory
$publicDesktopPath = [System.Environment]::GetFolderPath("CommonDesktopDirectory")

if (Test-Path "$publicDesktopPath\$shortcutName.lnk"){
    Write-Host "Shortcut path exists."
    Exit 0
}
else {
    Write-Host "Shortcut path does not exist."
    Exit 1
}