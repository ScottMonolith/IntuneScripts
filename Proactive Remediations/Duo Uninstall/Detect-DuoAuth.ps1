Write-Output "Finding Duo installation..."
$Duo = Get-ChildItem 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall', 'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall' -ErrorAction SilentlyContinue | 
            Get-ItemProperty |
            Where-Object { $_.DisplayName -like "*Duo*" }
$CredFilter = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Provider Filters\{BD7B4D1C-9364-429c-8447-0B63346D7177}' -ErrorAction SilentlyContinue
$CredProv1 = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Providers\{44E2ED41-48C7-4712-A3C3-250C5E6D5D84}' -ErrorAction SilentlyContinue
$CredProv2 = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Providers\{B7A5BA48-DF88-4F47-B648-64F27990480B}' -ErrorAction SilentlyContinue
$CLSID = Get-ItemProperty -LiteralPath 'HKLM:\Classes\CLSID\{44E2ED41-48C7-4712-A3C3-250C5E6D5D84}' -ErrorAction SilentlyContinue
$ProgFilesFolder = Get-ChildItem 'C:\Program Files\Duo Security' -ErrorAction SilentlyContinue
if ($Duo -or $CredFilter -or $CredProv1 -or $CredProv2 -or $CLSID -or $ProgFilesFolder) {
    Write-Output "Duo Installed!"
    Exit 1
}
else {
    Write-Output "Duo not installed."
    Exit 0
}