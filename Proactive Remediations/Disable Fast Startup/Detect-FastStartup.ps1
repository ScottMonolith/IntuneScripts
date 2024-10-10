$Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
$Name = "HiberbootEnabled"

$FastStartup = Get-ItemPropertyValue $path -Name $Name -ErrorAction SilentlyContinue

if (!(Test-Path $Path)) {
    Write-Output "Power registry path missing!"
    Exit 1
}
if ($FastStartup -ne 0) {
    Write-Output "Fast startup enabled!"
    Exit 1
}
else {
    Write-Output "Fast startup disabled."
    Exit 0
}