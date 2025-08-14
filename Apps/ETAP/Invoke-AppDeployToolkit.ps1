<#

.SYNOPSIS
PSAppDeployToolkit - This script performs the installation or uninstallation of an application(s).

.DESCRIPTION
- The script is provided as a template to perform an install, uninstall, or repair of an application(s).
- The script either performs an "Install", "Uninstall", or "Repair" deployment type.
- The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.

The script imports the PSAppDeployToolkit module which contains the logic and functions required to install or uninstall an application.

PSAppDeployToolkit is licensed under the GNU LGPLv3 License - (C) 2025 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the
Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details. You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

.PARAMETER DeploymentType
The type of deployment to perform.

.PARAMETER DeployMode
Specifies whether the installation should be run in Interactive (shows dialogs), Silent (no dialogs), or NonInteractive (dialogs without prompts) mode.

NonInteractive mode is automatically set if it is detected that the process is not user interactive.

.PARAMETER AllowRebootPassThru
Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.

.PARAMETER TerminalServerMode
Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Desktop Session Hosts/Citrix servers.

.PARAMETER DisableLogging
Disables logging to file for the script.

.EXAMPLE
powershell.exe -File Invoke-AppDeployToolkit.ps1 -DeployMode Silent

.EXAMPLE
powershell.exe -File Invoke-AppDeployToolkit.ps1 -AllowRebootPassThru

.EXAMPLE
powershell.exe -File Invoke-AppDeployToolkit.ps1 -DeploymentType Uninstall

.EXAMPLE
Invoke-AppDeployToolkit.exe -DeploymentType "Install" -DeployMode "Silent"

.INPUTS
None. You cannot pipe objects to this script.

.OUTPUTS
None. This script does not generate any output.

.NOTES
Toolkit Exit Code Ranges:
- 60000 - 68999: Reserved for built-in exit codes in Invoke-AppDeployToolkit.ps1, and Invoke-AppDeployToolkit.exe
- 69000 - 69999: Recommended for user customized exit codes in Invoke-AppDeployToolkit.ps1
- 70000 - 79999: Recommended for user customized exit codes in PSAppDeployToolkit.Extensions module.

.LINK
https://psappdeploytoolkit.com

#>

[CmdletBinding()]
param
(
    [Parameter(Mandatory = $false)]
    [ValidateSet('Install', 'Uninstall', 'Repair')]
    [PSDefaultValue(Help = 'Install', Value = 'Install')]
    [System.String]$DeploymentType,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Interactive', 'Silent', 'NonInteractive')]
    [PSDefaultValue(Help = 'Interactive', Value = 'Interactive')]
    [System.String]$DeployMode,

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.SwitchParameter]$AllowRebootPassThru,

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.SwitchParameter]$TerminalServerMode,

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.SwitchParameter]$DisableLogging
)


##================================================
## MARK: Variables
##================================================

$adtSession = @{
    # App variables.
    AppVendor = ''
    AppName = 'ETAP'
    AppVersion = '24.0.1'
    AppArch = 'x64'
    AppLang = 'EN'
    AppRevision = '01'
    AppSuccessExitCodes = @(0)
    AppRebootExitCodes = @(1641, 3010)
    AppScriptVersion = '1.0.0'
    AppScriptDate = '2025-03-17'
    AppScriptAuthor = 'Scott Brescia'

    # Install Titles (Only set here to override defaults set by the toolkit).
    InstallName = ''
    InstallTitle = ''

    # Script variables.
    DeployAppScriptFriendlyName = $MyInvocation.MyCommand.Name
    DeployAppScriptVersion = '4.0.6'
    DeployAppScriptParameters = $PSBoundParameters
    ForceWimDetection = $true
}

function Install-ADTDeployment
{
    ##================================================
    ## MARK: Pre-Install
    ##================================================
    $adtSession.InstallPhase = "Pre-$($adtSession.DeploymentType)"

    ## Show Welcome Message, verify there is enough disk space to complete the install, and persist the prompt.
    Show-ADTInstallationWelcome -CloseProcesses etaps64 -CloseProcessesCountdown 300 -CheckDiskSpace -PersistPrompt

    ## Show Progress Message (with the default message).
    Show-ADTInstallationProgress -WindowTitle "$($adtSession.AppName) $($adtSession.AppVersion)" -StatusMessage "Installation in Progress..." -StatusMessageDetail "The installation will take a long time (20+ minutes) to complete.`nPlease be patient, you can use your computer while the installation is progressing." -NotTopMost

    ## <Perform Pre-Installation tasks here>


    ##================================================
    ## MARK: Install
    ##================================================
    $adtSession.InstallPhase = $adtSession.DeploymentType

    ## Handle Zero-Config MSI installations.
    if ($adtSession.UseDefaultMsi)
    {
        $ExecuteDefaultMSISplat = @{ Action = $adtSession.DeploymentType; FilePath = $adtSession.DefaultMsiFile }
        if ($adtSession.DefaultMstFile)
        {
            $ExecuteDefaultMSISplat.Add('Transform', $adtSession.DefaultMstFile)
        }
        Start-ADTMsiProcess @ExecuteDefaultMSISplat
        if ($adtSession.DefaultMspFiles)
        {
            $adtSession.DefaultMspFiles | Start-ADTMsiProcess -Action Patch
        }
    }
    ## <Perform Installation tasks here>
    $ProcessResult = Start-ADTProcess -FilePath "$($adtSession.DirFiles)\EtapSetup.exe" -ArgumentList "/quiet INSTALLFOLDER=`"C:\Program Files (x86)\ETAP\ETAP 2400`"" -PassThru

    ## Manual attempt to install software, ETAP supported method is above...
    # Start-ADTMsiProcess -Action 'Install' -FilePath 'ETAPCore.msi' -ArgumentList "/QN TARGETDIR=`"$($envProgramFilesX86)\ETAP`""
	# Start-ADTMsiProcess -Action 'Install' -FilePath "$($adtSession.DirFiles)\redist\SqlLocalDB.msi" -ArgumentList "/QN ALLUSERS=1 MSIFASTINSTALL=7 IACCEPTSQLLOCALDBLICENSETERMS=YES REBOOT=ReallySuppress"
	# Start-ADTMsiProcess -Action 'Install' -FilePath "$($adtSession.DirFiles)\redist\w_ifort_runtime_p_2022.2.0.9553.msi" -ArgumentList "/QN REBOOT=ReallySuppress"
	# Start-ADTMsiProcess -Action 'Install' -FilePath "$($adtSession.DirFiles)\redist\CRRuntime_32bit_13_0_26.msi" -ArgumentList "/QN MSIFASTINSTALL=7 UPGRADE=1 REBOOT=ReallySuppress"
	# Start-ADTProcess -FilePath "$($envProgramData)\chocolatey\choco.exe" -ArgumentList 'install dotnet-6.0-aspnetruntime -y'
	# Start-ADTProcess -FilePath "$($envProgramData)\chocolatey\choco.exe" -ArgumentList 'install vcredist140 -y'

    ##================================================
    ## MARK: Post-Install
    ##================================================
    $adtSession.InstallPhase = "Post-$($adtSession.DeploymentType)"

    ## <Perform Post-Installation tasks here>
    # Required license file
	#Copy-ADTFile -Path "$($adtSession.DirFiles)\Etaps.ini" -Destination "$($envProgramFilesX86)\ETAP\ETAP 2400\Other\"
    Copy-ADTFile -Path "$($adtSession.DirFiles)\Etaps.ini" -Destination "c:\ETAP 2400\Other\"
	Copy-ADTFileToUserProfiles -Path "$($adtSession.DirFiles)\Etaps.ini" -Destination "AppData\Local\OTI\ETAPS\24.0.0\"

    # Force LocalDB fix - currently broken, STDOut not working...
	# $SqlLocalDBStatus = Start-ADTProcessAsUser -FilePath "sqllocaldb" -ArgumentList "i | findstr ETAPLocalDB19" -PassThru
	# if (!$SqlLocalDBStatus) {
		# Write-ADTLogEntry -Message "SQL localDB does not exist, creating..." -Source 'SQL-localDB'
		# Write-ADTLogEntry -Message "$($SqlLocalDBStatus)" -Source 'SQL-localDB'
		# # Start-ADTProcess -FilePath "sqllocaldb" -ArgumentList "stop ETAPLocalDB19"
		# # Start-ADTProcess -FilePath "sqllocaldb" -ArgumentList "delete ETAPLocalDB19"
		# # Start-ADTProcess -FilePath "sqllocaldb" -ArgumentList "create `"ETAPLocalDB19`" 15.0 -s"
		# # Start-ADTProcess -FilePath "sqllocaldb" -ArgumentList "start ETAPLocalDB19"
	# }
	# else {
		# Write-ADTLogEntry -Message "SQL localDB exists." -Source 'SQL-localDB'
		# Write-ADTLogEntry -Message "Get-Member $SqlLocalDBStatus" -Source 'SQL-localDB'
	# }

    ## Display a message at the end of the install.
    if ($ProcessResult.ExitCode -eq 3010) {
		Show-ADTInstallationPrompt -Title "$($adtSession.AppName) $($adtSession.AppVersion)" -Message "Installation Complete!" -ButtonRightText 'OK' -Icon Information -NoWait
		Show-ADTInstallationRestartPrompt -CountdownSeconds 600 -CountdownNoHideSeconds 60
	}
	else {
		Show-ADTInstallationPrompt -Title "$($adtSession.AppName) $($adtSession.AppVersion)" -Message "Installation Complete!" -ButtonRightText 'OK' -Icon Information -NoWait
	}
}

function Uninstall-ADTDeployment
{
    ##================================================
    ## MARK: Pre-Uninstall
    ##================================================
    $adtSession.InstallPhase = "Pre-$($adtSession.DeploymentType)"

    ## Show Welcome Message, close Internet Explorer with a 60 second countdown before automatically closing.
    Show-ADTInstallationWelcome -CloseProcesses etaps64 -CloseProcessesCountdown 300

    ## Show Progress Message (with a custom message).
    Show-ADTInstallationProgress -WindowTitle "$($adtSession.AppName) $($adtSession.AppVersion)" -StatusMessage "Uninstallation in Progress..." -StatusMessageDetail "The uninstallation will take a while (20+ minutes) to complete.`nPlease be patient, you can use your computer while the uninstallation is progressing." -NotTopMost

    ## <Perform Pre-Uninstallation tasks here>


    ##================================================
    ## MARK: Uninstall
    ##================================================
    $adtSession.InstallPhase = $adtSession.DeploymentType

    ## Handle Zero-Config MSI uninstallations.
    if ($adtSession.UseDefaultMsi)
    {
        $ExecuteDefaultMSISplat = @{ Action = $adtSession.DeploymentType; FilePath = $adtSession.DefaultMsiFile }
        if ($adtSession.DefaultMstFile)
        {
            $ExecuteDefaultMSISplat.Add('Transform', $adtSession.DefaultMstFile)
        }
        Start-ADTMsiProcess @ExecuteDefaultMSISplat
    }

    ## <Perform Uninstallation tasks here>
    $ProcessResult = Start-ADTProcess -FilePath "$($adtSession.DirFiles)\EtapSetup.exe" -ArgumentList "/quiet /uninstall" -PassThru
    
    ## Original attempt to uninstall directly, ETAP supported method is above...
    # Start-ADTMsiProcess -Action 'Uninstall' -FilePath 'ETAPCore.msi'
	# Start-ADTMsiProcess -Action 'Uninstall' -FilePath "$($adtSession.DirFiles)\redist\SqlLocalDB.msi"
	# Start-ADTMsiProcess -Action 'Uninstall' -FilePath "$($adtSession.DirFiles)\redist\w_ifort_runtime_p_2022.2.0.9553.msi"
	# Start-ADTMsiProcess -Action 'Uninstall' -FilePath "$($adtSession.DirFiles)\redist\CRRuntime_32bit_13_0_26.msi"
	# if (Test-Path -Path "$envProgramData\chocolatey\lib\dotnet-6.0-aspnetruntime") {
	# 	Start-ADTProcess -FilePath "$($envProgramData)\chocolatey\choco.exe" -ArgumentList 'uninstall dotnet-6.0-aspnetruntime -y'
	# }
	#Start-ADTProcess -FilePath "$($envProgramData)\chocolatey\choco.exe" -ArgumentList 'uninstall vcredist140 -y'

    ##================================================
    ## MARK: Post-Uninstallation
    ##================================================
    $adtSession.InstallPhase = "Post-$($adtSession.DeploymentType)"

    ## <Perform Post-Uninstallation tasks here>
    Remove-ADTFolder -Path "$($envProgramFilesX86)\ETAP"
	Remove-ADTFolder -Path "C:\ETAP 2400"
	Remove-ADTFileFromUserProfiles -Path "AppData\Local\OTI" -Recurse
	Remove-ADTFileFromUserProfiles -Path "AppData\Roaming\OTI" -Recurse
	if ($ProcessResult.ExitCode -eq 3010) {
		Show-ADTInstallationPrompt -Message "Uninstallation Complete!`nIt is required to reboot." -ButtonRightText 'OK' -Icon Information
		Show-ADTInstallationRestartPrompt -CountdownSeconds 600 -CountdownNoHideSeconds 30
	}
	else {
		Show-ADTInstallationPrompt -Title "$($adtSession.AppName) $($adtSession.AppVersion)" -Message "Uninstallation Complete!" -ButtonRightText 'OK' -Icon Information -NoWait
	}
}

function Repair-ADTDeployment
{
    ##================================================
    ## MARK: Pre-Repair
    ##================================================
    $adtSession.InstallPhase = "Pre-$($adtSession.DeploymentType)"

    ## Show Welcome Message, close Internet Explorer with a 60 second countdown before automatically closing.
    Show-ADTInstallationWelcome -CloseProcesses iexplore -CloseProcessesCountdown 60

    ## Show Progress Message (with the default message).
    Show-ADTInstallationProgress

    ## <Perform Pre-Repair tasks here>


    ##================================================
    ## MARK: Repair
    ##================================================
    $adtSession.InstallPhase = $adtSession.DeploymentType

    ## Handle Zero-Config MSI repairs.
    if ($adtSession.UseDefaultMsi)
    {
        $ExecuteDefaultMSISplat = @{ Action = $adtSession.DeploymentType; FilePath = $adtSession.DefaultMsiFile }
        if ($adtSession.DefaultMstFile)
        {
            $ExecuteDefaultMSISplat.Add('Transform', $adtSession.DefaultMstFile)
        }
        Start-ADTMsiProcess @ExecuteDefaultMSISplat
    }

    ## <Perform Repair tasks here>


    ##================================================
    ## MARK: Post-Repair
    ##================================================
    $adtSession.InstallPhase = "Post-$($adtSession.DeploymentType)"

    ## <Perform Post-Repair tasks here>
}


##================================================
## MARK: Initialization
##================================================

# Set strict error handling across entire operation.
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
$ProgressPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
Set-StrictMode -Version 1

# Import the module and instantiate a new session.
try
{
    $moduleName = if ([System.IO.File]::Exists("$PSScriptRoot\PSAppDeployToolkit\PSAppDeployToolkit.psd1"))
    {
        Get-ChildItem -LiteralPath $PSScriptRoot\PSAppDeployToolkit -Recurse -File | Unblock-File -ErrorAction Ignore
        "$PSScriptRoot\PSAppDeployToolkit\PSAppDeployToolkit.psd1"
    }
    else
    {
        'PSAppDeployToolkit'
    }
    Import-Module -FullyQualifiedName @{ ModuleName = $moduleName; Guid = '8c3c366b-8606-4576-9f2d-4051144f7ca2'; ModuleVersion = '4.0.6' } -Force
    try
    {
        $iadtParams = Get-ADTBoundParametersAndDefaultValues -Invocation $MyInvocation
        $adtSession = Open-ADTSession -SessionState $ExecutionContext.SessionState @adtSession @iadtParams -PassThru
    }
    catch
    {
        Remove-Module -Name PSAppDeployToolkit* -Force
        throw
    }
}
catch
{
    $Host.UI.WriteErrorLine((Out-String -InputObject $_ -Width ([System.Int32]::MaxValue)))
    exit 60008
}


##================================================
## MARK: Invocation
##================================================

try
{
    Get-Item -Path $PSScriptRoot\PSAppDeployToolkit.* | & {
        process
        {
            Get-ChildItem -LiteralPath $_.FullName -Recurse -File | Unblock-File -ErrorAction Ignore
            Import-Module -Name $_.FullName -Force
        }
    }
    & "$($adtSession.DeploymentType)-ADTDeployment"
    Close-ADTSession
}
catch
{
    Write-ADTLogEntry -Message ($mainErrorMessage = Resolve-ADTErrorRecord -ErrorRecord $_) -Severity 3
    Show-ADTDialogBox -Text $mainErrorMessage -Icon Stop | Out-Null
    Close-ADTSession -ExitCode 60001
}
finally
{
    Remove-Module -Name PSAppDeployToolkit* -Force
}
