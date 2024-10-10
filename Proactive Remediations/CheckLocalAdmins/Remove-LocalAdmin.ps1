$LocalAdmins = @()
$LocalAdmins = ([ADSI]"WinNT://./Administrators").psbase.Invoke('Members') | % {
 ([ADSI]$_).InvokeGet('AdsPath')
}
# S-1-5-21-2202743274-2568467625-1232712444-512 = CORP\Domain Admins
# S-1-5-21-2202743274-2568467625-1232712444-3846 = CORP\Workstation Admins
$LocalAdmins = $LocalAdmins | Where-Object { $_ -and $_ -notmatch 'Administrator' -and $_ -notmatch 'Domain Admins' -and $_ -notmatch 'Workstation Admins' -and $_ -notmatch 'S-1-5-21-2202743274-2568467625-1232712444-512' -and $_ -notmatch 'S-1-5-21-2202743274-2568467625-1232712444-3846' }
if ($LocalAdmins -contains 'WinNT://S-1-12-1-3145490437-1261976021-3131153818-889479219') {
    # SID S-1-12-1-3145490437-1261976021-3131153818-889479219 is not known, likely orphaned.  Remove it.
    Remove-LocalGroupMember -Group Administrators -Member S-1-12-1-3145490437-1261976021-3131153818-889479219
}
# Exit with the specified exit code
Exit $ExitCode