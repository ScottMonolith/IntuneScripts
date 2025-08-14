<#

.SYNOPSIS
PSAppDeployToolkit - This script performs the installation or uninstallation of an application(s).

.DESCRIPTION
- The script is provided as a template to perform an install, uninstall, or repair of an application(s).
- The script either performs an "Install", "Uninstall", or "Repair" deployment type.
- The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.

The script imports the PSAppDeployToolkit module which contains the logic and functions required to install or uninstall an application.

PSAppDeployToolkit is licensed under the GNU LGPLv3 License - © 2025 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the
Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details. You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

.PARAMETER DeploymentType
The type of deployment to perform.

.PARAMETER DeployMode
Specifies whether the installation should be run in Interactive (shows dialogs), Silent (no dialogs), or NonInteractive (dialogs without prompts) mode.

Silent mode is automatically set if it is detected that the process is not user interactive, no users are logged on, the device is in Autopilot mode, or there's specified processes to close that are currently running.

.PARAMETER SuppressRebootPassThru
Suppresses the 3010 return code (requires restart) from being passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.

.PARAMETER TerminalServerMode
Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Desktop Session Hosts/Citrix servers.

.PARAMETER DisableLogging
Disables logging to file for the script.

.EXAMPLE
powershell.exe -File Invoke-AppDeployToolkit.ps1

.EXAMPLE
powershell.exe -File Invoke-AppDeployToolkit.ps1 -DeployMode Silent

.EXAMPLE
powershell.exe -File Invoke-AppDeployToolkit.ps1 -DeploymentType Uninstall

.EXAMPLE
Invoke-AppDeployToolkit.exe -DeploymentType Install -DeployMode Silent

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
    [System.String]$DeploymentType,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Interactive', 'Silent', 'NonInteractive')]
    [System.String]$DeployMode,

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.SwitchParameter]$SuppressRebootPassThru,

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.SwitchParameter]$TerminalServerMode,

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.SwitchParameter]$DisableLogging
)


##================================================
## MARK: Variables
##================================================

# Zero-Config MSI support is provided when "AppName" is null or empty.
# By setting the "AppName" property, Zero-Config MSI will be disabled.
$adtSession = @{
    # App variables.
    AppVendor = 'Monolith'
    AppName = 'Data Services QuickStart'
    AppVersion = '0.5'
    AppArch = 'x64'
    AppLang = 'EN'
    AppRevision = '01'
    AppSuccessExitCodes = @(0)
    AppRebootExitCodes = @(1641, 3010)
    AppProcessesToClose = @()
    AppScriptVersion = '0.5'
    AppScriptDate = '2025-06-11'
    AppScriptAuthor = 'Scott Brescia'
	RequireAdmin = $true

    # Install Titles (Only set here to override defaults set by the toolkit).
    InstallName = ''
    InstallTitle = ''

    # Script variables.
    DeployAppScriptFriendlyName = $MyInvocation.MyCommand.Name
    DeployAppScriptParameters = $PSBoundParameters
    DeployAppScriptVersion = '4.1.0'
}

function Install-ADTDeployment
{
    [CmdletBinding()]
    param
    (
    )

    ##================================================
    ## MARK: Pre-Install
    ##================================================
    $adtSession.InstallPhase = "Pre-$($adtSession.DeploymentType)"

    ## Show Welcome Message, close processes if specified, allow up to 3 deferrals, verify there is enough disk space to complete the install, and persist the prompt.
    $saiwParams = @{
        AllowDefer = $false
        DeferTimes = 3
        CheckDiskSpace = $true
        PersistPrompt = $true
    }
    if ($adtSession.AppProcessesToClose.Count -gt 0)
    {
        $saiwParams.Add('CloseProcesses', $adtSession.AppProcessesToClose)
    }
    Show-ADTInstallationWelcome @saiwParams

    ## Show Progress Message (with the default message).
    Show-ADTInstallationProgress -WindowTitle "$($adtSession.AppName) $($adtSession.AppVersion)" -WindowSubtitle "Monolith Materials - App Installation" -StatusMessage "Installation in Progress..." -StatusMessageDetail "The installation process will take a while to complete, please be patient.  You can continue to work while this application is being installed." -NotTopMost

    ## <Perform Pre-Installation tasks here>
    if (!(Get-ADTApplication -Name 'Windows Subsystem for Linux')) {
        Write-ADTLogEntry -Message "WSL is missing, telling user to install manually..."
        Show-ADTInstallationPrompt -Message "WSL is a pre-requesite for this application, please install via Company Portal before installing this QuickStart." -ButtonRightText OK -Icon Error -NoWait
        Close-ADTSession -ExitCode 70001
    }

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
    # Define Python version - matches chocolatey package as well as filesystem paths.  'Full' var is for Get-ADTApplication and Write-ADTLogEntry below.
    $pythonver = 'Python312'
    $pythonverfull = 'Python 3.12'

    if (!(Get-ADTApplication -Name 'Microsoft Visual Studio Code')) {
        Write-ADTLogEntry -Message "VSCode not installed, installing..."
        Show-ADTInstallationProgress -WindowTitle "$($adtSession.AppName) $($adtSession.AppVersion)" -WindowSubtitle "Monolith Materials - App Installation" -StatusMessage "Installation in Progress..." -StatusMessageDetail "Installing VSCode..." -NotTopMost
        Start-ADTProcess -FilePath "C:\ProgramData\chocolatey\choco.exe" -Argumentlist 'install vscode -y' -CreateNoWindow
    }
    if (!(Get-ADTApplication -Name "$pythonverfull")) {
        Write-ADTLogEntry -Message "$($pythonverfull) not installed, installing..."
        Show-ADTInstallationProgress -WindowTitle "$($adtSession.AppName) $($adtSession.AppVersion)" -WindowSubtitle "Monolith Materials - App Installation" -StatusMessage "Installation in Progress..." -StatusMessageDetail "Installing $($pythonverfull)..." -NotTopMost
        Start-ADTProcess -FilePath "C:\ProgramData\chocolatey\choco.exe" -Argumentlist "install $pythonver -y" -CreateNoWindow
        Update-ADTEnvironmentPsProvider
        $PathToAdd = "C:\$pythonver\;C:\$pythonver\Scripts\"
        $Paths = (Get-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment').GetValue('PATH', $null, 'DoNotExpandEnvironmentNames') -split ';'
        $NewPath = ($Paths + $PathToAdd) -join ';'
        [System.Environment]::SetEnvironmentVariable('PATH', $NewPath, [System.EnvironmentVariableTarget]::Machine)
    }
    if (!(Get-ADTApplication -Name 'PowerShell 7-x64')) {
        Write-ADTLogEntry -Message "PowerShell 7 not installed, installing..."
        Show-ADTInstallationProgress -WindowTitle "$($adtSession.AppName) $($adtSession.AppVersion)" -WindowSubtitle "Monolith Materials - App Installation" -StatusMessage "Installation in Progress..." -StatusMessageDetail "Installing pwsh (PowerShell)..." -NotTopMost
        Start-ADTProcess -FilePath "C:\ProgramData\chocolatey\choco.exe" -Argumentlist 'install pwsh -y' -CreateNoWindow
        Update-ADTEnvironmentPsProvider
        $PathToAdd = "$env:ProgramFiles\PowerShell\7"
        $Paths = (Get-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment').GetValue('PATH', $null, 'DoNotExpandEnvironmentNames') -split ';'
        $NewPath = ($Paths + $PathToAdd) -join ';'
        [System.Environment]::SetEnvironmentVariable('PATH', $NewPath, [System.EnvironmentVariableTarget]::Machine)
    }
    if (!(Get-ADTApplication -Name 'AWS Command Line Interface v2')) {
        Write-ADTLogEntry -Message "AWS CLI not installed, installing..."
        Show-ADTInstallationProgress -WindowTitle "$($adtSession.AppName) $($adtSession.AppVersion)" -WindowSubtitle "Monolith Materials - App Installation" -StatusMessage "Installation in Progress..." -StatusMessageDetail "Installing AWS CLI..." -NotTopMost
        Start-ADTProcess -FilePath "C:\ProgramData\chocolatey\choco.exe" -Argumentlist 'install awscli -y' -CreateNoWindow
        Update-ADTEnvironmentPsProvider
        $PathToAdd = "$env:ProgramFiles\Amazon\AWSCLIV2\"
        $Paths = (Get-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment').GetValue('PATH', $null, 'DoNotExpandEnvironmentNames') -split ';'
        $NewPath = ($Paths + $PathToAdd) -join ';'
        [System.Environment]::SetEnvironmentVariable('PATH', $NewPath, [System.EnvironmentVariableTarget]::Machine)
    }
    if (!(Get-ADTApplication -Name 'Git')) {
        Write-ADTLogEntry -Message "GIT not installed, installing..."
        Show-ADTInstallationProgress -WindowTitle "$($adtSession.AppName) $($adtSession.AppVersion)" -WindowSubtitle "Monolith Materials - App Installation" -StatusMessage "Installation in Progress..." -StatusMessageDetail "Installing GIT..." -NotTopMost
        Start-ADTProcess -FilePath "C:\ProgramData\chocolatey\choco.exe" -Argumentlist 'install git -y' -CreateNoWindow
        Update-ADTEnvironmentPsProvider
        $PathToAdd = "$env:ProgramFiles\Git\bin"
        $Paths = (Get-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment').GetValue('PATH', $null, 'DoNotExpandEnvironmentNames') -split ';'
        $NewPath = ($Paths + $PathToAdd) -join ';'
        [System.Environment]::SetEnvironmentVariable('PATH', $NewPath, [System.EnvironmentVariableTarget]::Machine)
    }
    if (!(Get-ADTApplication -Name 'GitHub CLI')) {
        Write-ADTLogEntry -Message "GitHub CLI not installed, installing..."
        Show-ADTInstallationProgress -WindowTitle "$($adtSession.AppName) $($adtSession.AppVersion)" -WindowSubtitle "Monolith Materials - App Installation" -StatusMessage "Installation in Progress..." -StatusMessageDetail "Installing GitHub CLI..." -NotTopMost
        Start-ADTProcess -FilePath "C:\ProgramData\chocolatey\choco.exe" -Argumentlist 'install gh -y' -CreateNoWindow
        Update-ADTEnvironmentPsProvider
        $PathToAdd = "$env:ProgramFiles\GitHub CLI"
        $Paths = (Get-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment').GetValue('PATH', $null, 'DoNotExpandEnvironmentNames') -split ';'
        $NewPath = ($Paths + $PathToAdd) -join ';'
        [System.Environment]::SetEnvironmentVariable('PATH', $NewPath, [System.EnvironmentVariableTarget]::Machine)
    }
    if (!(Get-ADTApplication -Name 'Rancher Desktop')) {
        Write-ADTLogEntry -Message "Rancher Desktop not installed, installing..."
        Show-ADTInstallationProgress -WindowTitle "$($adtSession.AppName) $($adtSession.AppVersion)" -WindowSubtitle "Monolith Materials - App Installation" -StatusMessage "Installation in Progress..." -StatusMessageDetail "Installing Rancher Desktop..." -NotTopMost
        if (!(Get-ADTApplication -Name 'Windows Subsystem for Linux')) {
            Write-ADTLogEntry -Message "WSL is missing, installing now..."
            #Start-ADTProcessAsUser -FilePath "powershell" -ArgumentList "-noprofile -command `"winget install --exact --silent --id=9P9TQF7MRM4R --source=msstore`""
            # Until I sort out winget, user will need to manually install WSL...
        }
        Start-ADTProcess -FilePath "C:\ProgramData\chocolatey\choco.exe" -Argumentlist "install rancher-desktop -y --install-arguments=""/l*v $env:ProgramData\Microsoft\IntuneManagementExtension\Logs\rancher-desktop_msi_install.log""" -CreateNoWindow
    }
    if (!(Get-ADTApplication -Name 'Node.js')) {
        Write-ADTLogEntry -Message "Node.js not installed, installing..."
        Show-ADTInstallationProgress -WindowTitle "$($adtSession.AppName) $($adtSession.AppVersion)" -WindowSubtitle "Monolith Materials - App Installation" -StatusMessage "Installation in Progress..." -StatusMessageDetail "Installing Node.js..." -NotTopMost
        Start-ADTProcess -FilePath "C:\ProgramData\chocolatey\choco.exe" -Argumentlist "install nodejs -y" -CreateNoWindow
    }
    if (!(Get-ADTApplication -Name 'Yarn')) {
        Write-ADTLogEntry -Message "Yarn not installed, installing..."
        Show-ADTInstallationProgress -WindowTitle "$($adtSession.AppName) $($adtSession.AppVersion)" -WindowSubtitle "Monolith Materials - App Installation" -StatusMessage "Installation in Progress..." -StatusMessageDetail "Installing Yarn..." -NotTopMost
        Start-ADTProcess -FilePath "C:\ProgramData\chocolatey\choco.exe" -Argumentlist "install yarn -y" -CreateNoWindow
    }

    ##================================================
    ## MARK: Post-Install
    ##================================================
    $adtSession.InstallPhase = "Post-$($adtSession.DeploymentType)"

    ## <Perform Post-Installation tasks here>
    if (!(Test-Path -Path "C:\GitHub")) {
        New-Item -Path "C:\GitHub" -ItemType "directory"
    }
    #Set-ADTItemPermission -Path 'C:\GitHub' -User 'BUILTIN\Users' -Permission FullControl -Inheritance ObjectInherit,ContainerInherit

    # Get user vars
    #$UserAppDataPath = (Get-ADTUserProfiles -LoadProfilePaths | Where-Object NTAccount -eq $RunAsActiveUser.NTAccount ).AppDataPath.FullName
    $UserProfilePath = (Get-ADTUserProfiles -LoadProfilePaths | Where-Object NTAccount -eq $RunAsActiveUser.NTAccount ).ProfilePath.FullName

    # Add env vars
    [System.Environment]::SetEnvironmentVariable("AWS_DEFAULT_SSO_REGION", "us-east-2", "Machine")
    [System.Environment]::SetEnvironmentVariable("AWS_DEFAULT_SSO_START_URL", "https://monolithcorp.awsapps.com/start/", "Machine")

    # Install pipx / upgrade pip...
    Show-ADTInstallationProgress -WindowTitle "$($adtSession.AppName) $($adtSession.AppVersion)" -WindowSubtitle "Monolith Materials - App Installation" -StatusMessage "Post-Install Configuration" -StatusMessageDetail "Installing pipx..." -NotTopMost
    Start-ADTProcessAsUser -FilePath "C:\$pythonver\python.exe" -ArgumentList '-m pip install --user pipx' -CreateNoWindow
    Show-ADTInstallationProgress -WindowTitle "$($adtSession.AppName) $($adtSession.AppVersion)" -WindowSubtitle "Monolith Materials - App Installation" -StatusMessage "Post-Install Configuration" -StatusMessageDetail "Upgrading pip..." -NotTopMost
    Start-ADTProcessAsUser -FilePath "C:\$pythonver\python.exe" -Argumentlist '-m pip install --upgrade pip' -CreateNoWindow
    Update-ADTEnvironmentPsProvider
    $PathToAdd = "$UserProfilePath\AppData\Roaming\Python\$pythonver\Scripts"
    $Paths = (Get-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment').GetValue('PATH', $null, 'DoNotExpandEnvironmentNames') -split ';'
    $NewPath = ($Paths + $PathToAdd) -join ';'
    [System.Environment]::SetEnvironmentVariable('PATH', $NewPath, [System.EnvironmentVariableTarget]::Machine)
    
    # Install copier
    Show-ADTInstallationProgress -WindowTitle "$($adtSession.AppName) $($adtSession.AppVersion)" -WindowSubtitle "Monolith Materials - App Installation" -StatusMessage "Post-Install Configuration" -StatusMessageDetail "Installing copier..." -NotTopMost
    Start-ADTProcessAsUser -FilePath "%appdata%\Python\$pythonver\Scripts\pipx.exe" -ArgumentList 'install copier' -ExpandEnvironmentVariables -CreateNoWindow

    # Install pre-commit
    Show-ADTInstallationProgress -WindowTitle "$($adtSession.AppName) $($adtSession.AppVersion)" -WindowSubtitle "Monolith Materials - App Installation" -StatusMessage "Post-Install Configuration" -StatusMessageDetail "Installing pre-commit..." -NotTopMost
    Start-ADTProcessAsUser -FilePath "%appdata%\Python\$pythonver\Scripts\pipx.exe" -ArgumentList 'install pre-commit' -ExpandEnvironmentVariables -CreateNoWindow
    
    <# Removed Ruff/Pyright per Steven Dhawan - "We handle those at the project level so once people have pdm and run a pdm install those will get added to the virtual environment. Having them installed at the machine level might cause some version issues down the line"
    # Install ruff
    Show-ADTInstallationProgress -WindowTitle "$($adtSession.AppName) $($adtSession.AppVersion)" -WindowSubtitle "Monolith Materials - App Installation" -StatusMessage "Post-Install Configuration" -StatusMessageDetail "Installing ruff..." -NotTopMost
    Start-ADTProcessAsUser -FilePath "%appdata%\Python\$pythonver\Scripts\pipx.exe" -ArgumentList 'install ruff' -ExpandEnvironmentVariables -CreateNoWindow

    # Install pyright
    Show-ADTInstallationProgress -WindowTitle "$($adtSession.AppName) $($adtSession.AppVersion)" -WindowSubtitle "Monolith Materials - App Installation" -StatusMessage "Post-Install Configuration" -StatusMessageDetail "Installing pyright..." -NotTopMost
    Start-ADTProcessAsUser -FilePath "%appdata%\Python\$pythonver\Scripts\pipx.exe" -ArgumentList 'install pyright' -ExpandEnvironmentVariables -CreateNoWindow
    #>

    # Install awsume/aws-sso-util using pipx from the user's appdata path
    Show-ADTInstallationProgress -WindowTitle "$($adtSession.AppName) $($adtSession.AppVersion)" -WindowSubtitle "Monolith Materials - App Installation" -StatusMessage "Post-Install Configuration" -StatusMessageDetail "Installing awsume..." -NotTopMost
    Start-ADTProcessAsUser -FilePath "%appdata%\Python\$pythonver\Scripts\pipx.exe" -ArgumentList 'install awsume' -ExpandEnvironmentVariables -CreateNoWindow
    Show-ADTInstallationProgress -WindowTitle "$($adtSession.AppName) $($adtSession.AppVersion)" -WindowSubtitle "Monolith Materials - App Installation" -StatusMessage "Post-Install Configuration" -StatusMessageDetail "Installing aws-sso-util..." -NotTopMost
    Start-ADTProcessAsUser -FilePath "%appdata%\Python\$pythonver\Scripts\pipx.exe" -ArgumentList 'install aws-sso-util' -ExpandEnvironmentVariables -CreateNoWindow
    Update-ADTEnvironmentPsProvider
    $PathToAdd = "$UserProfilePath\.local\bin"
    $Paths = (Get-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment').GetValue('PATH', $null, 'DoNotExpandEnvironmentNames') -split ';'
    $NewPath = ($Paths + $PathToAdd) -join ';'
    [System.Environment]::SetEnvironmentVariable('PATH', $NewPath, [System.EnvironmentVariableTarget]::Machine)
    if (!(Test-Path -Path "$UserProfilePath\.aws\config")) {
        Show-ADTInstallationProgress -WindowTitle "$($adtSession.AppName) $($adtSession.AppVersion)" -WindowSubtitle "Monolith Materials - App Installation" -StatusMessage "Post-Install Configuration" -StatusMessageDetail "Configuring aws sso... lookout for a terminal window to complete the AWS SSO configuration" -NotTopMost
        Start-ADTProcessAsUser -FilePath "$env:programfiles\Amazon\AWSCLIV2\aws.exe" -ArgumentList 'configure sso'
    }
    Show-ADTInstallationProgress -WindowTitle "$($adtSession.AppName) $($adtSession.AppVersion)" -WindowSubtitle "Monolith Materials - App Installation" -StatusMessage "Post-Install Configuration" -StatusMessageDetail "Configuring aws-sso-util...lookout for a terminal window with a code." -NotTopMost
    Start-ADTProcessAsUser -FilePath "%userprofile%\pipx\venvs\aws-sso-util\Scripts\aws-sso-util.exe" -ArgumentList 'configure populate --region us-east-2 --role-name-case lower --trim-role-name access --trim-role-name aws --trim-role-name user --trim-role-name istrator --account-name-case lower --trim-account-name monolith-materials-' -ExpandEnvironmentVariables
    
    # Install PDM
    Show-ADTInstallationProgress -WindowTitle "$($adtSession.AppName) $($adtSession.AppVersion)" -WindowSubtitle "Monolith Materials - App Installation" -StatusMessage "Post-Install Configuration" -StatusMessageDetail "Installing PDM..." -NotTopMost
    Start-ADTProcessAsUser -FilePath "powershell" -ArgumentList "(Invoke-WebRequest -Uri https://pdm-project.org/install-pdm.py -UseBasicParsing).Content | C:\$pythonver\python.exe -" -CreateNoWindow
    Update-ADTEnvironmentPsProvider
    $PathToAdd = "$UserProfilePath\AppData\Roaming\Python\Scripts"
    $Paths = (Get-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment').GetValue('PATH', $null, 'DoNotExpandEnvironmentNames') -split ';'
    $NewPath = ($Paths + $PathToAdd) -join ';'
    [System.Environment]::SetEnvironmentVariable('PATH', $NewPath, [System.EnvironmentVariableTarget]::Machine)
    
    # Setup GitHub / clone repo's - issues with this running from Intune, will comment out...
    <#
    Show-ADTInstallationProgress -WindowTitle "$($adtSession.AppName) $($adtSession.AppVersion)" -WindowSubtitle "Monolith Materials - App Installation" -StatusMessage "Post-Install Configuration" -StatusMessageDetail "Configuring Git/GitHub... lookout for a cmd prompt" -NotTopMost
    Start-ADTProcessAsUser -FilePath "$env:programfiles\GitHub CLI\gh.exe" -ArgumentList 'config set git_protocol https -h github.com' -CreateNoWindow
    $AuthResult = Start-ADTProcessAsUser -FilePath "$env:programfiles\GitHub CLI\gh.exe" -ArgumentList 'auth login' -SuccessExitCodes 0, 1 -PassThru -CreateNoWindow -ErrorAction SilentlyContinue
    Write-ADTLogEntry -Message "StdErr: $($RepoClonePDMCodeArtifact.StdErr)"
    Show-ADTInstallationProgress -WindowTitle "$($adtSession.AppName) $($adtSession.AppVersion)" -WindowSubtitle "Monolith Materials - App Installation" -StatusMessage "Post-Install Configuration" -StatusMessageDetail "Cloning GitHub repo's..." -NotTopMost
    if (Test-Path -Path "C:\GitHub\pdm-code-artifact-setup") {
        Remove-ADTFolder -Path C:\GitHub\pdm-code-artifact-setup
        #New-ADTFolder -Path C:\GitHub\pdm-code-artifact-setup
    }
    #else {
        #New-ADTFolder -Path C:\GitHub\pdm-code-artifact-setup
    #}
    $GitCloneOutput = Start-ADTProcessAsUser -FilePath "git" -ArgumentList 'clone https://github.com/monolithmaterials/pdm-code-artifact-setup C:\GitHub\pdm-code-artifact-setup' -CreateNoWindow
    Write-ADTLogEntry -Message "StdErr: $($GitCloneOutput.StdErr)"
    if (Test-Path -Path "C:\GitHub\aws-utils") {
        Remove-ADTFolder -Path C:\GitHub\aws-utils
        #New-ADTFolder -Path C:\GitHub\aws-utils
    }
    #else {
        #New-ADTFolder -Path C:\GitHub\aws-utils
    #}
    Start-ADTProcessAsUser -FilePath "git" -ArgumentList 'clone https://github.com/monolithmaterials/aws-utils C:\GitHub\aws-utils'
    #>

    # This needs to be run in PoSH 7, and should be a post-script step the end user runs themselves.
    #Start-ADTProcessAsUser -FilePath "powershell.exe" -ArgumentList "-file C:\GitHub\aws-utils\codeart\index-password.ps1"

    #$pulumiq = Show-ADTInstallationPrompt -Message 'Do you want to install the optional Pulumi components?' -ButtonRightText 'Yes' -ButtonLeftText 'No'


    ## Display a message at the end of the install.
    if (!$adtSession.UseDefaultMsi) {
        Show-ADTInstallationPrompt -Message 'Installation Complete!' -ButtonRightText 'OK' -Icon Information -NoWait
    }
}

function Uninstall-ADTDeployment
{
    [CmdletBinding()]
    param
    (
    )

    ##================================================
    ## MARK: Pre-Uninstall
    ##================================================
    $adtSession.InstallPhase = "Pre-$($adtSession.DeploymentType)"

    ## If there are processes to close, show Welcome Message with a 60 second countdown before automatically closing.
    if ($adtSession.AppProcessesToClose.Count -gt 0)
    {
        Show-ADTInstallationWelcome -CloseProcesses $adtSession.AppProcessesToClose -CloseProcessesCountdown 60
    }

    ## Show Progress Message (with the default message).
    Show-ADTInstallationProgress

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


    ##================================================
    ## MARK: Post-Uninstallation
    ##================================================
    $adtSession.InstallPhase = "Post-$($adtSession.DeploymentType)"

    ## <Perform Post-Uninstallation tasks here>
}

function Repair-ADTDeployment
{
    [CmdletBinding()]
    param
    (
    )

    ##================================================
    ## MARK: Pre-Repair
    ##================================================
    $adtSession.InstallPhase = "Pre-$($adtSession.DeploymentType)"

    ## If there are processes to close, show Welcome Message with a 60 second countdown before automatically closing.
    if ($adtSession.AppProcessesToClose.Count -gt 0)
    {
        Show-ADTInstallationWelcome -CloseProcesses $adtSession.AppProcessesToClose -CloseProcessesCountdown 60
    }

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
    # Import the module locally if available, otherwise try to find it from PSModulePath.
    if (Test-Path -LiteralPath "$PSScriptRoot\PSAppDeployToolkit\PSAppDeployToolkit.psd1" -PathType Leaf)
    {
        Get-ChildItem -LiteralPath $PSScriptRoot\PSAppDeployToolkit -Recurse -File | Unblock-File -ErrorAction Ignore
        Import-Module -FullyQualifiedName @{ ModuleName = "$PSScriptRoot\PSAppDeployToolkit\PSAppDeployToolkit.psd1"; Guid = '8c3c366b-8606-4576-9f2d-4051144f7ca2'; ModuleVersion = '4.1.0' } -Force
    }
    else
    {
        Import-Module -FullyQualifiedName @{ ModuleName = 'PSAppDeployToolkit'; Guid = '8c3c366b-8606-4576-9f2d-4051144f7ca2'; ModuleVersion = '4.1.0' } -Force
    }

    # Open a new deployment session, replacing $adtSession with a DeploymentSession.
    $iadtParams = Get-ADTBoundParametersAndDefaultValues -Invocation $MyInvocation
    $adtSession = Remove-ADTHashtableNullOrEmptyValues -Hashtable $adtSession
    $adtSession = Open-ADTSession @adtSession @iadtParams -PassThru
}
catch
{
    $Host.UI.WriteErrorLine((Out-String -InputObject $_ -Width ([System.Int32]::MaxValue)))
    exit 60008
}


##================================================
## MARK: Invocation
##================================================

# Commence the actual deployment operation.
try
{
    # Import any found extensions before proceeding with the deployment.
    Get-ChildItem -LiteralPath $PSScriptRoot -Directory | & {
        process
        {
            if ($_.Name -match 'PSAppDeployToolkit\..+$')
            {
                Get-ChildItem -LiteralPath $_.FullName -Recurse -File | Unblock-File -ErrorAction Ignore
                Import-Module -Name $_.FullName -Force
            }
        }
    }

    # Invoke the deployment and close out the session.
    & "$($adtSession.DeploymentType)-ADTDeployment"
    Close-ADTSession
}
catch
{
    # An unhandled error has been caught.
    $mainErrorMessage = "An unhandled error within [$($MyInvocation.MyCommand.Name)] has occurred.`n$(Resolve-ADTErrorRecord -ErrorRecord $_)"
    Write-ADTLogEntry -Message $mainErrorMessage -Severity 3

    ## Error details hidden from the user by default. Show a simple dialog with full stack trace:
    # Show-ADTDialogBox -Text $mainErrorMessage -Icon Stop -NoWait

    ## Or, a themed dialog with basic error message:
    Show-ADTInstallationPrompt -Message "$($adtSession.DeploymentType) failed at line $($_.InvocationInfo.ScriptLineNumber), char $($_.InvocationInfo.OffsetInLine):`n$($_.InvocationInfo.Line.Trim())`n`nMessage:`n$($_.Exception.Message)" -MessageAlignment Left -ButtonRightText OK -Icon Error -NoWait

    Close-ADTSession -ExitCode 60001
}

