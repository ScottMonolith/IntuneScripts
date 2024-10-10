$PackageName = "slack"

$choco_path = "C:\ProgramData\chocolatey\lib\$PackageName"
if (Test-Path -Path $choco_path -PathType Container){
    Write-Host "Found it!"
}
