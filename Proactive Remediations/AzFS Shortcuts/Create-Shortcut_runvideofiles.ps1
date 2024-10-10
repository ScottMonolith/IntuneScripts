# Define the target file or program for which you want to create a shortcut 
$targetPath = "\\azfsprdceus01.file.core.windows.net\runvideofiles"

# Define the name of the shortcut (without the .lnk extension)
$shortcutName = "Run Video Files"

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
