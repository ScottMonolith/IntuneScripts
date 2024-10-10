$LocalAdmins = @()
$LocalAdmins = ([ADSI]"WinNT://./Administrators").psbase.Invoke('Members') | % {
 ([ADSI]$_).InvokeGet('AdsPath')
}
# S-1-5-21-2202743274-2568467625-1232712444-512 = CORP\Domain Admins
# S-1-5-21-2202743274-2568467625-1232712444-3846 = CORP\Workstation Admins
$LocalAdmins = $LocalAdmins | Where-Object { $_ -and $_ -notmatch 'Administrator' -and $_ -notmatch 'Domain Admins' -and $_ -notmatch 'Workstation Admins' -and $_ -notmatch 'S-1-5-21-2202743274-2568467625-1232712444-512' -and $_ -notmatch 'S-1-5-21-2202743274-2568467625-1232712444-3846' }
if ($LocalAdmins) {
    $LocalAdmins = $LocalAdmins.replace('WinNT://','')
    $LocalAdmins -join ","
    # Set exit code 1 (failure)
    $ExitCode = 1
}
else {
    Write-Host "No unexpected local admins!"
    # Set exit code 0 (success)
    $ExitCode = 0
}
# Exit with the specified exit code
Exit $ExitCode