# Create Folder for logs
$Logs = "$($env:programdata)\Microsoft\IntuneManagementExtension\Logs"
If (!(Test-Path $Logs)) {
    New-Item -Path "$Logs" -ItemType Directory
}

# Starts the log
Start-Transcript -Path "$Logs\DuoAuth_Uninstall.log"

Write-Output "Finding Duo installation..."
$Duo = Get-ChildItem 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall', 'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall' -ErrorAction SilentlyContinue | 
            Get-ItemProperty |
            Where-Object { $_.DisplayName -like "*Duo*" }
if ($Duo) {
    Write-Output "'$($Duo.DisplayName)' is installed, uninstalling..."
    foreach ($Uninstall in $Duo.UninstallString) {
        if ($Uninstall -like '*msiexec*') {
            Write-Output "Using msiexec uninstall..."
            $uninstallGUID = "{" + $Uninstall.Split("{")[-1]
        }
        else {
            Write-Output "Removing registry key '$($Duo.PSPath)'..."
            $Duo.PSPath | Remove-Item -Force
        }
    }
    if (!$uninstallGUID) {
        Write-Output "Uninstall String is not producing valid results, fall back to PSChildName..."
        $uninstallGUID = $Duo.PSChildName
    }
}
else {
    Write-Output "Duo not found, nothing to remove!"
}

$PackageName = "duo-authentication"

$choco_path = "C:\ProgramData\chocolatey\lib\$PackageName"
$choco_install = $null
if (Test-Path -Path $choco_path -PathType Container){
    Write-Output "Duo installed via choco."
    $choco_install = 1
}

if ($choco_install) {
    Write-Output "Removing Duo via chocolatey."
    Start-Process choco.exe -ArgumentList "uninstall `"$PackageName`"" -Wait -PassThru
}
else {
    if ($uninstallGUID) {
        Write-Output "Uninstalling Duo"
        Start-Process msiexec -ArgumentList "/x $uninstallGUID /qn /norestart /l*v `"$Logs\DuoAuth_Uninstall-MSI.log`"" -Wait -PassThru
    }
    else {
        Write-Output "Uninstall GUID is null, nothing to uninstall."
    }
}

# Check for leftover cruft...
Write-Output "Checking for registry leftovers..."
$CredFilter = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Provider Filters\{BD7B4D1C-9364-429c-8447-0B63346D7177}' -ErrorAction SilentlyContinue
$CredProv1 = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Providers\{44E2ED41-48C7-4712-A3C3-250C5E6D5D84}' -ErrorAction SilentlyContinue
$CredProv2 = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Providers\{B7A5BA48-DF88-4F47-B648-64F27990480B}' -ErrorAction SilentlyContinue
$CLSID = Get-ItemProperty -LiteralPath 'HKLM:\Classes\CLSID\{44E2ED41-48C7-4712-A3C3-250C5E6D5D84}' -ErrorAction SilentlyContinue

if ($CredFilter) {
    Write-Output "Cred Provider Filter found, removing!"
    $CredFilter | Remove-Item -Force
}
if ($CredProv1) {
    Write-Output "Cred Provider 1 found, removing!"
    $CredProv1 | Remove-Item -Force
}
if ($CredProv2) {
    Write-Output "Cred Provider 2 found, removing!"
    $CredProv2 | Remove-Item -Force
}
if ($CLSID) {
    Write-Output "CLSID found, removing!"
    $CLSID | Remove-Item -Force
}

Write-Output "Checking for DLL leftovers..."
$ProgFilesFolder = Get-ChildItem 'C:\Program Files\Duo Security' -ErrorAction SilentlyContinue
if ($ProgFilesFolder) {
    Write-Output "Deleting program files folder for Duo..."
    $ProgFilesFolder | Remove-Item -Recurse -Force
}

# End of log
Stop-Transcript