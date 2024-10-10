$folderPath = "C:\Users\Public\Desktop"
$acl = Get-Acl $folderPath
if ($acl.Access.IdentityReference -contains "NT AUTHORITY\Authenticated Users") {
    $aclSpec = $acl | Select-Object -ExpandProperty Access | Where-Object IdentityReference -eq 'NT AUTHORITY\Authenticated Users'
    if ($aclSpec.FileSystemRights -eq 'Modify, Synchronize' -and $aclSpec.AccessControlType -eq 'Allow') {
        Write-Host 'Permissions are setup!'
        Exit 0
    }
    else {
        Write-Host 'Public desktop permissions are not setup.'
        Exit 1
    }
}
else {
    Write-Host 'Public desktop permissions are not setup.'
    Exit 1
}