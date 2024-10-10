# Define the target file or program for which you want to create a shortcut 
$targetPath = "\\monooc1fs01.corp.monolithmaterials.com\oc1reactorfiles_short"

# Define the name of the shortcut (without the .lnk extension)
$shortcutName = "OC1 Reactor Files Short"

# Define the path to the public desktop directory
$publicDesktopPath = [System.Environment]::GetFolderPath("CommonDesktopDirectory")

# Create a WScript Shell object to create the shortcut
$shell = New-Object -ComObject WScript.Shell

# Create a shortcut object
$shortcut = $shell.CreateShortcut("$publicDesktopPath\$shortcutName.lnk")

# Set the target path for the shortcut
$shortcut.TargetPath = $targetPath

# Save the shortcut
$shortcut.Save()

# Clean up the objects
$shell = $null
$shortcut = $null
