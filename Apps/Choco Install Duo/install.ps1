if (($pshome -like "*syswow64*") -and ((Get-WmiObject Win32_OperatingSystem).OSArchitecture -like "64*")) {
    write-warning "Restarting script under 64 bit powershell"
 
    # relaunch this script under 64 bit shell
    & (join-path ($pshome -replace "syswow64", "sysnative")\powershell.exe) -file $myinvocation.mycommand.Definition @args
 
    # This will exit the original powershell process. This will only be done in case of an x86 process on a x64 OS.
    exit
}

$PackageName = Get-Content choco.txt
$InstallParameter = Get-Content parameter.txt -ErrorAction SilentlyContinue

Start-Transcript -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\$PackageName-install.log" -Force

$localprograms = C:\ProgramData\chocolatey\choco.exe list
if ($localprograms -like "*$PackageName*"){
    C:\ProgramData\chocolatey\choco.exe upgrade $PackageName -y --package-parameters="$InstallParameter"
}else{
    C:\ProgramData\chocolatey\choco.exe install $PackageName -y --package-parameters="$InstallParameter"
}

Stop-Transcript
