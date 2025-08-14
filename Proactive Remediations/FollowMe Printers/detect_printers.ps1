# List of printer names to check
$PrintersToCheck = @("FollowMe-B&W", "FollowMe-Color")

# Function to check if a printer is installed
function Is-PrinterInstalled {
	param (
		[string]$PrinterName
	)
	$printers = Get-Printer | Where-Object Name -like "*$PrinterName*"
	return $printers
}

# Check all printers
$AllInstalled = $true
foreach ($printer in $PrintersToCheck) {
	if (-not (Is-PrinterInstalled -PrinterName $printer)) {
		Write-Output "Printer '$printer' is not installed."
		$AllInstalled = $false
	} else {
		Write-Output "Printer '$printer' is already installed."
	}
}

# Exit with appropriate code
if ($AllInstalled) {
	Write-Output "Printers installed."
	exit 0
} else {
	Write-Output "Need to install printers!"
	exit 1
}