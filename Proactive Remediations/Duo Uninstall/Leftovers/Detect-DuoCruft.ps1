Write-Output "Finding Duo cruft..."
$Duo = Test-Path "$env:ProgramFiles\Duo Security\WindowsLogon"
if ($Duo) {
    Write-Output "Duo cruft found!"
    Exit 1
}
else {
    Write-Output "No cruft present."
    Exit 0
}