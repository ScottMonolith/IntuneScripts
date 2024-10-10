$PackageName = "lenovo-thinkvantage-system-update"

$choco_path = "C:\ProgramData\chocolatey\lib\$PackageName"
if (Test-Path -Path $choco_path -PathType Container){
    Write-Host "Found it!"
}
