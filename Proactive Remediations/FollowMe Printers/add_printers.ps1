# Black & White FollowMe Printer for PaperCut
$PrinterBWName = "FollowMe-B&W"
$PrinterBWUNC = "\\monooc1print01.corp.monolithmaterials.com\FollowMe-B&W"
# Color FollowMe Printer for PaperCut
$PrinterColorName = "FollowMe-Color"
$PrinterColorUNC = "\\monooc1print01.corp.monolithmaterials.com\FollowMe-Color"

# Add the printers
$PrinterBWStatus = Get-Printer | Where-Object Name -like "*$PrinterBWName*"
if (!$PrinterBWStatus) {
	Write-Output "Adding '$PrinterBWName'..."
	Add-Printer -ConnectionName $PrinterBWUNC
}
else {
	Write-Output "'$PrinterBWName' already exists."
}

$PrinterColorStatus = Get-Printer | Where-Object Name -like "*$PrinterColorName*"
if (!$PrinterColorStatus) {
	Write-Output "Adding '$PrinterColorName'..."
	Add-Printer -ConnectionName $PrinterColorUNC
}
else {
	Write-Output "'$PrinterColorName' already exists."
}