<#

.SYNOPSIS
PSAppDeployToolkit - This script performs the installation or uninstallation of an application(s).

.DESCRIPTION
- The script is provided as a template to perform an install, uninstall, or repair of an application(s).
- The script either performs an "Install", "Uninstall", or "Repair" deployment type.
- The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.

The script imports the PSAppDeployToolkit module which contains the logic and functions required to install or uninstall an application.

PSAppDeployToolkit is licensed under the GNU LGPLv3 License - (C) 2024 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the
Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details. You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

.PARAMETER DeploymentType
The type of deployment to perform. Default is: Install.

.PARAMETER DeployMode
Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode. Default is: Interactive. Options: Interactive = Shows dialogs, Silent = No dialogs, NonInteractive = Very silent, i.e. no blocking apps. NonInteractive mode is automatically set if it is detected that the process is not user interactive.

.PARAMETER AllowRebootPassThru
Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.

.PARAMETER TerminalServerMode
Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Desktop Session Hosts/Citrix servers.

.PARAMETER DisableLogging
Disables logging to file for the script. Default is: $false.

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
    [System.String]$DeploymentType = 'Install',

    [Parameter(Mandatory = $false)]
    [ValidateSet('Interactive', 'Silent', 'NonInteractive')]
    [System.String]$DeployMode = 'Interactive',

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
    AppVendor = 'Dassault Systems'
    AppName = 'SolidWorks'
    AppVersion = '2023 SP5'
    AppArch = 'x64'
    AppLang = 'EN'
    AppRevision = '01'
    AppSuccessExitCodes = @(0)
    AppRebootExitCodes = @(1641, 3010)
    AppScriptVersion = '1.0.0'
    AppScriptDate = '2025-02-04'
    AppScriptAuthor = 'Scott Brescia'

    # Install Titles (Only set here to override defaults set by the toolkit).
    InstallName = ''
    InstallTitle = ''

    # Script variables.
    DeployAppScriptFriendlyName = $MyInvocation.MyCommand.Name
    DeployAppScriptVersion = '4.0.5'
    DeployAppScriptParameters = $PSBoundParameters
	ForceWimDetection = $true
}

function Install-ADTDeployment
{
    ##================================================
    ## MARK: Pre-Install
    ##================================================
    $adtSession.InstallPhase = "Pre-$($adtSession.DeploymentType)"

    ## Show Welcome Message, close Internet Explorer if required, allow up to 3 deferrals, verify there is enough disk space to complete the install, and persist the prompt.
    Show-ADTInstallationWelcome -CloseProcesses sldProdMon, SLDWORKS, sldworks_fs, EdmServer, ViewServer -CloseProcessesCountdown 600 -CheckDiskSpace -PersistPrompt

    ## Show Progress Message (with the default message).
    Show-ADTInstallationProgress -WindowTitle "$($adtSession.AppName) $($adtSession.AppVersion)" -StatusMessage "Installation in Progress..." -StatusMessageDetail "The installation process will take a long time to complete, please be patient.  You can continue to work while this application is being installed." -NotTopMost

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
	Start-ADTProcess -FilePath 'startswinstall.exe' -ArgumentList "/install /now" -WindowStyle 'Hidden'

    ##================================================
    ## MARK: Post-Install
    ##================================================
    $adtSession.InstallPhase = "Post-$($adtSession.DeploymentType)"

    ## <Perform Post-Installation tasks here>
	if (Test-Path -Path "$env:programfiles\SOLIDWORKS Corp\SOLIDWORKS PDM\ViewSetup.exe") {
		if (Test-Path -Path "C:\EG-Boxer") {
			if (Test-Path -Path "HKLM:\Software\Wow6432Node\SOLIDWORKS\Applications\PDMWorks Enterprise\Databases\EG-Boxer") {
				Write-ADTLogEntry -Message "PDM Vault View appears to already exist..."
			}
			else {
				Write-ADTLogEntry -Message "C:\EG-Boxer exists, but vault view does not.  Removing folder and running vault view setup."
				Remove-ADTFolder -Path 'C:\EG-Boxer'
				Start-ADTProcess -FilePath "$envProgramFiles\SOLIDWORKS Corp\SOLIDWORKS PDM\ViewSetup.exe" -ArgumentList "/q `"$($adtSession.DirFiles)\EG-Boxer.cvs`"" -WindowStyle "Hidden"
			}
		}
		else {
			Write-ADTLogEntry -Message "C:\EG-Boxer does not exist, and neither does the vault view.  Running vault view setup."
			Start-ADTProcess -FilePath "$envProgramFiles\SOLIDWORKS Corp\SOLIDWORKS PDM\ViewSetup.exe" -ArgumentList "/q `"$($adtSession.DirFiles)\EG-Boxer.cvs`"" -WindowStyle "Hidden"
		}
	}
	else {
		Write-ADTLogEntry -Message "Failed to find '$envProgramFiles\SOLIDWORKS Corp\SOLIDWORKS PDM\ViewSetup.exe' - please add Vault View manually." -Severity 3
	}
	
	# Disable SOLIDWORKS Inspection add-in 
	Set-ADTRegistryKey -Key 'HKLM:\SOFTWARE\SolidWorks\SOLIDWORKS 2023\AddIns\{61092750-66c4-4fd9-9116-da3414a71650}' -Name '(Default)' -Type 'DWord' -Value 0
	Set-ADTRegistryKey -Key 'HKLM:\SOFTWARE\SolidWorks\SOLIDWORKS 2023\AddInsStartup\{61092750-66c4-4fd9-9116-da3414a71650}' -Name '(Default)' -Type 'DWord' -Value 0
    Set-ADTRegistryKey -Key 'HKLM:\SOFTWARE\SolidWorks\AddIns\{61092750-66c4-4fd9-9116-da3414a71650}' -Name '(Default)' -Type 'DWord' -Value 0
	Set-ADTRegistryKey -Key 'HKLM:\SOFTWARE\SolidWorks\AddInsStartup\{61092750-66c4-4fd9-9116-da3414a71650}' -Name '(Default)' -Type 'DWord' -Value 0
	$LoggedOnuser = Get-ADTLoggedOnUser
	if ($LoggedOnuser.IsConsoleSession){
		Set-ADTRegistryKey -Key 'HKCU:\Software\SolidWorks\AddInsStartup\{61092750-66C4-4FD9-9116-DA3414A71650}' -Name '(Default)' -Type 'DWord' -Value 0 -SID $LoggedOnuser.SID
	}
	# Remove link to SOLIDWORKS Inspection
	Remove-ADTFile -Path "$envCommonDesktop\SOLIDWORKS Inspection 2023.lnk"
    
	## Display a message at the end of the install.
	Show-ADTInstallationPrompt -Title "$($adtSession.AppName) $($adtSession.AppVersion)" -Message "Installation Complete!" -ButtonRightText 'OK' -Icon Information -NoWait
}

function Uninstall-ADTDeployment
{
    ##================================================
    ## MARK: Pre-Uninstall
    ##================================================
    $adtSession.InstallPhase = "Pre-$($adtSession.DeploymentType)"

    ## Show Welcome Message, close Internet Explorer with a 60 second countdown before automatically closing.
    Show-ADTInstallationWelcome -CloseProcesses sldProdMon, SLDWORKS, sldworks_fs, EdmServer, ViewServer, ConisioAdmin -CloseProcessesCountdown 60

    ## Show Progress Message (with the default message).
    Show-ADTInstallationProgress -WindowTitle "$($adtSession.AppName) $($adtSession.AppVersion)" -StatusMessage "Uninstallation in Progress..." -StatusMessageDetail "The uninstallation process will take a long time to complete, please be patient.  You can continue to work while this application is being uninstalled." -NotTopMost

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
	# Remove-MSIApplications -Name 'SolidWorks 2023' # Will call the uninstaller but does it incompletely and messy. Keeping in case this ever gets better. Used Get-Uninstaller for MSIs below

	# Uninstall E-drawings
	Start-ADTMsiProcess -Action 'Uninstall' -ProductCode '{5DA7B824-6CD3-464E-A321-7A12A5AAC688}'
	Start-ADTMsiProcess -Action 'Uninstall' -ProductCode '{678A1D27-5CF1-4F17-BDA4-0A4843478E4C}'
	# Uninstall CAM 2023
	Start-ADTMsiProcess -Action 'Uninstall' -ProductCode '{6336104B-A756-43B6-9E4A-90A6F0B73709}'
	# Uninstall Flow Simulations 2023
	Start-ADTMsiProcess -Action 'Uninstall' -ProductCode '{CA66BF32-7373-41D3-83E6-AEEB00F777E7}'
	# Uninstall File Utilities 2023
	Start-ADTMsiProcess -Action 'Uninstall' -ProductCode '{27D1CA1A-717A-4A47-8680-9D35E57EDEB4}'
	# Uninstall Solidworks 2023
	Start-ADTMsiProcess -Action 'Uninstall' -ProductCode '{F24FAABB-0C72-4F06-9B55-DB08C884730C}'
	# Uninstall CEF for SOLIDWORKS Applications
	Start-ADTMsiProcess -Action 'Uninstall' -ProductCode '{93D5C716-DD70-4353-A1F7-AD013F1EE7AD}'
	Start-ADTMsiProcess -Action 'Uninstall' -ProductCode '{E76E31D0-F26B-4D73-8300-A441AA1806E9}'
	# Uninstall SOLIDWORKS PDM Client 2023 SP03
	Start-ADTMsiProcess -Action 'Uninstall' -ProductCode '{B9E3EB48-BD7B-4A76-8692-65BF8971331B}'
	
	# Uninstalling PDM causes Explorer to crash regularly, force it to restart
	$ProcessActive = Get-Process explorer -ErrorAction SilentlyContinue
	if (!$ProcessActive) {
		Write-ADTLogEntry -Message "Explorer PID not found, starting explorer"
		Start-ADTProcessAsUser -FilePath "$envSystemRoot\explorer.exe"
	}
	else {
		Write-ADTLogEntry -Message "PDM crashes explorer, killing and restarting explorer"
		$ProcessActive | Stop-Process
		Start-ADTProcessAsUser -FilePath "$envSystemRoot\explorer.exe"
	}
	
	# Uninstall SOLIDWORKS Inspection
	Start-ADTMsiProcess -Action 'Uninstall' -ProductCode '{2EAFF79F-7944-4584-9087-25FF662A024C}'
	
	##================================================
    ## MARK: Post-Uninstallation
    ##================================================
    $adtSession.InstallPhase = "Post-$($adtSession.DeploymentType)"

    ## <Perform Post-Uninstallation tasks here>
	
	# Remove extra folders and data
	Remove-ADTFolder -Path "$envProgramData\SOLIDWORKS"
	Remove-ADTFolder -Path "$envSystemDrive\SOLIDWORKS Data"
	Remove-ADTFolder -Path "$envProgramFiles\SOLIDWORKS Corp"
	Remove-ADTFolder -Path "$envProgramData\Microsoft\Windows\Start Menu\Programs\SOLIDWORKS Installation Manager"
	Remove-ADTFolder -Path 'C:\EG-Boxer'
	Remove-ADTFolder -Path 'C:\Windows\Solidworks'
	
	$LoggedOnuser = Get-ADTLoggedOnUser
	if ($LoggedOnuser.IsConsoleSession){
		Remove-ADTRegistryKey -Key "HKCU\Software\SolidWorks" -Recurse -SID $LoggedOnuser.SID
	}
	
	#Update-ADTDesktop
	
	Show-ADTInstallationPrompt -Title "$($adtSession.AppName) $($adtSession.AppVersion)" -Message "Uninstallation Complete!" -ButtonRightText 'OK' -Icon Information -NoWait
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
    Import-Module -FullyQualifiedName @{ ModuleName = $moduleName; Guid = '8c3c366b-8606-4576-9f2d-4051144f7ca2'; ModuleVersion = '4.0.5' } -Force
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

