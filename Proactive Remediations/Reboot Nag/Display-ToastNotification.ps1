# Create Write-Log function
function Write-Log() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias("LogContent")]
        [string]$Message,
        [Parameter(Mandatory=$false)]
        [Alias('LogPath')]
        [string]$Path = "$env:APPDATA\ToastNotificationScript\New-ToastNotification.log",
        [Parameter(Mandatory=$false)]
        [ValidateSet("Error","Warn","Info")]
        [string]$Level = "Info"
    )
    Begin {
        # Set VerbosePreference to Continue so that verbose messages are displayed.
        $VerbosePreference = 'Continue'
    }
    Process {
		if (Test-Path $Path) {
			$LogSize = (Get-Item -Path $Path).Length/1MB
			$MaxLogSize = 5
		}
        # Check for file size of the log. If greater than 5MB, it will create a new one and delete the old.
        if ((Test-Path $Path) -AND $LogSize -gt $MaxLogSize) {
            Write-Error "Log file $Path already exists and file exceeds maximum file size. Deleting the log and starting fresh."
            Remove-Item $Path -Force
            $NewLogFile = New-Item $Path -Force -ItemType File
        }
        # If attempting to write to a log file in a folder/path that doesn't exist create the file including the path.
        elseif (-NOT(Test-Path $Path)) {
            Write-Verbose "Creating $Path."
            $NewLogFile = New-Item $Path -Force -ItemType File
        }
        else {
            # Nothing to see here yet.
        }
        # Format Date for our Log File
        $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        # Write message to error, warning, or verbose pipeline and specify $LevelText
        switch ($Level) {
            'Error' {
                Write-Error $Message
                $LevelText = 'ERROR:'
            }
            'Warn' {
                Write-Warning $Message
                $LevelText = 'WARNING:'
            }
            'Info' {
                Write-Verbose $Message
                $LevelText = 'INFO:'
            }
        }
        # Write log entry to $Path
        "$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append -Encoding utf8
    }
    End {
    }
}
function Display-ToastNotification() {
    $Load = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
    $Load = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
    # Load the notification into the required format
    $ToastXML = New-Object -TypeName Windows.Data.Xml.Dom.XmlDocument
    $ToastXML.LoadXml($Toast.OuterXml)
        
    # Display the toast notification
    try {
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($App).Show($ToastXml)
    }
    catch { 
        Write-Log -Message 'Something went wrong when displaying the toast notification' -Level Warn
        Write-Log -Message 'Make sure the script is running as the logged on user' -Level Warn     
    }
    # Saving time stamp of when toast notification was run into registry
    Save-NotificationLastRunTime
}

function Get-GivenName() {
    Write-Log -Message "Running Get-GivenName function"
    try {
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement
        $PrincipalContext = [System.DirectoryServices.AccountManagement.PrincipalContext]::new([System.DirectoryServices.AccountManagement.ContextType]::Domain, [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain())
        $GivenName = ([System.DirectoryServices.AccountManagement.Principal]::FindByIdentity($PrincipalContext,[System.DirectoryServices.AccountManagement.IdentityType]::SamAccountName,[Environment]::UserName)).GivenName
        $PrincipalContext.Dispose()
    }
    catch [System.Exception] {
        Write-Log -Level Error -Message "$_"
    }
    if (-NOT[string]::IsNullOrEmpty($GivenName)) {
        Write-Log -Message "Given name retrieved from Active Directory: $GivenName"
        $GivenName
    }
    # This is the last resort of trying to find a given name. This part will be used if device is not joined to a local AD, and is not having the configmgr client installed
    elseif ([string]::IsNullOrEmpty($GivenName)) {
        Write-Log -Message "Given name not found in AD or no local AD is available. Continuing looking for given name elsewhere"
        $RegKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI"
        if ((Get-ItemProperty $RegKey).LastLoggedOnDisplayName) {
            $LoggedOnUserDisplayName = Get-Itemproperty -Path $RegKey -Name "LastLoggedOnDisplayName" | Select-Object -ExpandProperty LastLoggedOnDisplayName
            if (-NOT[string]::IsNullOrEmpty($LoggedOnUserDisplayName)) {
                $DisplayName = $LoggedOnUserDisplayName.Split(" ")
                $GivenName = $DisplayName[0]
                Write-Log -Message "Given name found directly in registry: $GivenName"
                $GivenName
            }
            else {
                Write-Log -Message "Given name not found in registry. Using nothing as placeholder"
                $GivenName = $null
            }
        }
        else {
            Write-Log -Message "Given name not found in registry. Using nothing as placeholder"
            $GivenName = $null
        }
    }
}

# Create Windows Push Notification function.
# This is testing if toast notifications generally are disabled within Windows 10
function Test-WindowsPushNotificationsEnabled() {
    $ToastEnabledKey = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name ToastEnabled -ErrorAction Ignore).ToastEnabled
    if ($ToastEnabledKey -eq "1") {
        Write-Log -Message "Toast notifications for the logged on user are enabled in Windows"
        $true
    }
    elseif ($ToastEnabledKey -eq "0") {
        Write-Log -Level Error -Message "Toast notifications for the logged on user are not enabled in Windows. The script will try to enable toast notifications for the logged on user"
        $false
    }
}

# Create Enable-WindowsPushNotifications
# This is used to re-enable toast notifications if the user disabled them generally in Windows
function Enable-WindowsPushNotifications() {
    $ToastEnabledKeyPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications"
    Write-Log -Message "Trying to enable toast notifications for the logged on user"
    try {
        Set-ItemProperty -Path $ToastEnabledKeyPath -Name ToastEnabled -Value 1 -Force
        Get-Service -Name WpnUserService** | Restart-Service -Force
        Write-Log -Message "Successfully enabled toast notifications for the logged on user"
    }
    catch {
        Write-Log -Level Error -Message "Failed to enable toast notifications for the logged on user. Toast notifications will probably not be displayed"
    }
}
# Create function to register custom notification app
function Register-CustomNotificationApp($fAppID,$fAppDisplayName) {
    Write-Log -Message "Running Register-NotificationApp function"
    $AppID = $fAppID
    $AppDisplayName = $fAppDisplayName
    # This removes the option to disable to toast notification
    [int]$ShowInSettings = 0
    # Adds an icon next to the display name of the notifying app
    [int]$IconBackgroundColor = 0
    $IconUri = "%SystemRoot%\ImmersiveControlPanel\images\logo.png"
    # Moved this into HKCU, in order to modify this directly from the toast notification running in user context
    $AppRegPath = "HKCU:\Software\Classes\AppUserModelId"
    $RegPath = "$AppRegPath\$AppID"
    try {
        if (-NOT(Test-Path $RegPath)) {
            New-Item -Path $AppRegPath -Name $AppID -Force | Out-Null
        }
        $DisplayName = Get-ItemProperty -Path $RegPath -Name DisplayName -ErrorAction SilentlyContinue | Select -ExpandProperty DisplayName -ErrorAction SilentlyContinue
        if ($DisplayName -ne $AppDisplayName) {
            New-ItemProperty -Path $RegPath -Name DisplayName -Value $AppDisplayName -PropertyType String -Force | Out-Null
        }
        $ShowInSettingsValue = Get-ItemProperty -Path $RegPath -Name ShowInSettings -ErrorAction SilentlyContinue | Select -ExpandProperty ShowInSettings -ErrorAction SilentlyContinue
        if ($ShowInSettingsValue -ne $ShowInSettings) {
            New-ItemProperty -Path $RegPath -Name ShowInSettings -Value $ShowInSettings -PropertyType DWORD -Force | Out-Null
        }
        $IconUriValue = Get-ItemProperty -Path $RegPath -Name IconUri -ErrorAction SilentlyContinue | Select -ExpandProperty IconUri -ErrorAction SilentlyContinue
        if ($IconUriValue -ne $IconUri) {
            New-ItemProperty -Path $RegPath -Name IconUri -Value $IconUri -PropertyType ExpandString -Force | Out-Null
        }
        $IconBackgroundColorValue = Get-ItemProperty -Path $RegPath -Name IconBackgroundColor -ErrorAction SilentlyContinue | Select -ExpandProperty IconBackgroundColor -ErrorAction SilentlyContinue
        if ($IconBackgroundColorValue -ne $IconBackgroundColor) {
            New-ItemProperty -Path $RegPath -Name IconBackgroundColor -Value $IconBackgroundColor -PropertyType ExpandString -Force | Out-Null
        }
        Write-Log "Created registry entries for custom notification app: $fAppDisplayName"
    }
    catch {
        Write-Log -Message "Failed to create one or more registry entries for the custom notification app" -Level Error
        Write-Log -Message "Toast Notifications are usually not displayed if the notification app does not exist" -Level Error
    }
}

function Write-PackageIDRegistry() {
    Write-Log -Message "Running Write-PackageIDRegistry function"
    $RegistryPath = "HKCU:\SOFTWARE\ToastNotificationScript"
    # Making sure that the registry path being used exists
    if (-NOT(Test-Path -Path $RegistryPath)) {
        try {
            New-Item -Path $RegistryPath -Force
        }
        catch { 
            Write-Log -Message "Error. Could not create ToastNotificationScript registry path" -Level Error
        }
    }
}
function Get-DeviceUptime() {
    Write-Log -Message "Running Get-DeviceUptime function"
    $OS = Get-CimInstance Win32_OperatingSystem
    $Uptime = (Get-Date) - ($OS.LastBootUpTime)
    $Uptime.Days
}

# Create function to store the timestamp of the notification execution
# Added in version 2.2.0
function Save-NotificationLastRunTime() {
    $RunTime = Get-Date -Format s
    if (-NOT(Get-ItemProperty -Path $global:RegistryPath -Name LastRunTime -ErrorAction Ignore)) {
        New-ItemProperty -Path $global:RegistryPath -Name LastRunTime -Value $RunTime -Force | Out-Null
    }
    else {
        Set-ItemProperty -Path $global:RegistryPath -Name LastRunTime -Value $RunTime -Force | Out-Null
    }
}

# Create function to retrieve the last run time of the notification
# Added in version 2.2.0
function Get-NotificationLastRunTime() {
    $LastRunTime = (Get-ItemProperty $global:RegistryPath -Name LastRunTime -ErrorAction Ignore).LastRunTime
    $CurrentTime = Get-Date -Format s
    if (-NOT[string]::IsNullOrEmpty($LastRunTime)) {
        $Difference = ([datetime]$CurrentTime - ([datetime]$LastRunTime)) 
        $MinutesSinceLastRunTime = [math]::Round($Difference.TotalMinutes)
        Write-Log -Message "Toast notification was previously displayed $MinutesSinceLastRunTime minutes ago"
        $MinutesSinceLastRunTime
    }
}

# Setting image variables
$LogoImageUri = "https://azpub.blob.core.windows.net/publicfiles/White - Two Colors.jpg"
$HeroImageUri = "https://azpub.blob.core.windows.net/publicfiles/Azure Background blank-min-min-min.jpg"
$LogoImage = "$env:TEMP\ToastLogoImage.png"
$HeroImage = "$env:TEMP\ToastHeroImage.png"
$Uptime = Get-DeviceUptime
$CustomAppEnabled = $true
$GreetGivenName = $true
$RunPackageIDEnabled = $true
# Setting global registry path
$global:RegistryPath = "HKCU:\SOFTWARE\ToastNotificationScript"
# Setting global custom action script location
$global:CustomScriptsPath = "$env:APPDATA\ToastNotificationScript\Scripts"
# Setting global script version
$global:ScriptVersion = "2.3.0"
$Type = "ToastReboot"
$CustomAppValue = "Restart Notification"
$LimitToastToRunEveryMinutesValue = 60

# Check to see if user snoozed the notification
$appId = 'Toast.Custom.App' # This should match whichever AppId you're using to create the toasts

$Load = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
$toastNotifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId)
$scheduled = $toastNotifier.getScheduledToastNotifications()

if ($scheduled.DeliveryTime) {
    Write-Log -Message "User has snoozed notifications, next notification delivery is '$($scheduled.DeliveryTime)'.  Stopping."
    # Original date and time string
    $originalDateTime = $scheduled.DeliveryTime
    # Convert to DateTime object
    $dateTime = [DateTimeOffset]::Parse($originalDateTime)
    # Convert to the desired format
    $convertedDateTime = $dateTime.ToString("yyyy-MM-ddTHH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture)

    # Output the result to the registry
    if (-NOT(Get-ItemProperty -Path $global:RegistryPath -Name LastRunTime -ErrorAction Ignore)) {
        New-ItemProperty -Path $global:RegistryPath -Name LastRunTime -Value $convertedDateTime -Force | Out-Null
    }
    else {
        Set-ItemProperty -Path $global:RegistryPath -Name LastRunTime -Value $convertedDateTime -Force | Out-Null
    }

    # Limit number of snoozes to 1
    if (-NOT(Get-ItemProperty -Path $global:RegistryPath -Name Snoozed -ErrorAction Ignore)) {
        New-ItemProperty -Path $global:RegistryPath -Name Snoozed -Value 1 -Force | Out-Null
    }
    else {
        Set-ItemProperty -Path $global:RegistryPath -Name Snoozed -Value 1 -Force | Out-Null
    }

    $SnoozeTask = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object TaskName -like 'Clear Snoozed Toasts*'
    if ($SnoozeTask) {
        $SnoozeTask | Start-ScheduledTask
    }
    else {
        Write-Log -Level Error "Scheduled task for clearing snoozed toasts not found!"
    }
    break
}

# Running RunPackageID function
if ($RunPackageIDEnabled) {
    Write-Log -Message "RunPackageID set to True. Will allow execution of PackageID directly from the toast action button"
    Write-PackageIDRegistry
}

# Build out registry for custom action for rebooting the device via the action button
try { 
    New-Item "HKCU:\Software\Classes\$($Type)\shell\open\command" -Force -ErrorAction SilentlyContinue | Out-Null
    New-ItemProperty -LiteralPath "HKCU:\Software\Classes\$($Type)" -Name 'URL Protocol' -Value '' -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
    New-ItemProperty -LiteralPath "HKCU:\Software\Classes\$($Type)" -Name '(default)' -Value "URL:$($Type) Protocol" -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
    $RegCommandValue = $CustomScriptsPath  + '\' + "$($Type).cmd"
    New-ItemProperty -LiteralPath "HKCU:\Software\Classes\$($Type)\shell\open\command" -Name '(default)' -Value $RegCommandValue -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
}
catch {
    Write-Log -Level Error "Failed to create the $Type custom protocol in HKCU\Software\Classes. Action button might not work"
    $ErrorMessage = $_.Exception.Message
    Write-Log -Level Error -Message "Error message: $ErrorMessage"
}
# Create custom script for rebooting the device directly from the action button
try {
    $CMDFileName = $Type + '.cmd'
    $CMDFilePath = $CustomScriptsPath + '\' + $CMDFileName
    try {
        New-item -Path $CustomScriptsPath -Name $CMDFileName -Force -OutVariable PathInfo | Out-Null
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Log -Level Error -Message "Error message: $ErrorMessage"              
    }
    try {
        $GetCustomScriptPath = $PathInfo.FullName
        [String]$Script = 'shutdown /r /t 0 /d p:0:0 /c "Toast Notification Reboot"'
        if (-NOT[string]::IsNullOrEmpty($Script)) {
            Out-File -FilePath $GetCustomScriptPath -InputObject $Script -Encoding ASCII -Force
        }
    }
    catch {
        Write-Log -Level Error "Failed to create the custom .cmd script for $Type. Action button might not work"
        $ErrorMessage = $_.Exception.Message
        Write-Log -Level Error -Message "Error message: $ErrorMessage"
    }
}
catch {
    Write-Log -Level Error "Failed to create the custom .cmd script for $Type. Action button might not work"
    $ErrorMessage = $_.Exception.Message
    Write-Log -Level Error -Message "Error message: $ErrorMessage"
}

#Fetching images from uri
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
try {
    Invoke-WebRequest -Uri $LogoImageUri -OutFile $LogoImage -ErrorAction Stop
    Invoke-WebRequest -Uri $HeroImageUri -OutFile $HeroImage -ErrorAction Stop
}
catch {
    Write-Log -Level Warn "Invoke-WebRequest error: $($_.Exception.Message)"
}


# Testing for blockers of toast notifications in Windows
$WindowsPushNotificationsEnabled = Test-WindowsPushNotificationsEnabled
if ($WindowsPushNotificationsEnabled -eq $False) {
    Enable-WindowsPushNotifications
}

# This option enables you to create a custom app doing the notification. 
# This also completely prevents the user from disabling the toast from within the UI (can be done with registry editing, if one knows how)
if ($CustomAppEnabled) {
    # Hardcoding the AppID. Only the display name is interesting
    $App = "Toast.Custom.App"
    Register-CustomNotificationApp -fAppID $App -fAppDisplayName $CustomAppValue
    # Check for required entries in registry for when using Custom App as application for the toast
    # Path to the notification app doing the actual toast
    $RegPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings"
    # Creating registry entries if they don't exist
    if (-NOT(Test-Path -Path $RegPath\$App)) {
        New-Item -Path $RegPath\$App -Force
        New-ItemProperty -Path $RegPath\$App -Name "ShowInActionCenter" -Value 0 -PropertyType "DWORD"
        New-ItemProperty -Path $RegPath\$App -Name "Enabled" -Value 1 -PropertyType "DWORD" -Force
        New-ItemProperty -Path $RegPath\$App -Name "SoundFile" -PropertyType "STRING" -Force
    }
    # Make sure the app used with the action center is enabled
    if ((Get-ItemProperty -Path $RegPath\$App -Name "Enabled" -ErrorAction SilentlyContinue).Enabled -ne "1") {
        New-ItemProperty -Path $RegPath\$App -Name "Enabled" -Value 1 -PropertyType "DWORD" -Force
    }    
    if ((Get-ItemProperty -Path $RegPath\$App -Name "ShowInActionCenter" -ErrorAction SilentlyContinue).ShowInActionCenter -ne "0") {
        New-ItemProperty -Path $RegPath\$App -Name "ShowInActionCenter" -Value 0 -PropertyType "DWORD" -Force
    }
    # Added to not play any sounds when notification is displayed with scenario: alarm
    if (-NOT(Get-ItemProperty -Path $RegPath\$App -Name "SoundFile" -ErrorAction SilentlyContinue)) {
        New-ItemProperty -Path $RegPath\$App -Name "SoundFile" -PropertyType "STRING" -Force
    }
}

# Checking if running toast with personal greeting with given name
if ($GreetGivenName) {
    Write-Log -Message "Greeting with given name selected. Replacing HeaderText"
    $GreetMorningText = "Good morning,"
    $GreetAfternoonText = "Good afternoon,"
    $GreetEveningText = "Good evening,"
    $Hour = (Get-Date).TimeOfDay.Hours
    if (($Hour -ge 0) -AND ($Hour -lt 12)) {
        Write-Log -Message "Greeting with $GreetMorningText"
        $Greeting = $GreetMorningText
    }
    elseif (($Hour -ge 12) -AND ($Hour -lt 16)) {
        Write-Log -Message "Greeting with $GreetAfternoonText"
        $Greeting = $GreetAfternoonText
    }
    else {
        Write-Log -Message "Greeting with $GreetEveningText"
        $Greeting = $GreetEveningText
    }
    $GivenName = Get-GivenName
    $HeaderText = "$Greeting $GivenName"
}

#Defining the Toast notification settings
#ToastNotification Settings
$Scenario = 'reminder' # <!-- Possible values are: reminder | short | long -->

# Random cheesy reboot messages
# Define a list of strings
$stringList = @(
"Time for a Power Nap! Your computer needs a quick reboot to recharge its brain cells.", 
"Reboot Required: Even computers need a fresh start sometimes. Think of it as a digital spa day!",
"Your computer needs a reboot. It's like a coffee break, but for circuits!",
"Your computer needs a reboot. It's feeling a bit 'byte'-tired.",
"Reboot Alert! Your computer needs a quick nap to dream of faster processing speeds.",
"Time to reboot! Your computer promises to come back smarter and faster.",
"Reboot Required: Your computer needs a moment to remember where it left its keys.",
"Your computer needs a reboot. It's time for a quick 'Ctrl+Alt+Del' dance!",
"Reboot Time! Your computer needs a break to clear its digital cobwebs.",
"Heads up! Your computer needs a reboot. It's time for a quick 'brain' reset."
)

# Get a random index from the list
$randomIndex = Get-Random -Minimum 0 -Maximum $stringList.Count

# Load Toast Notification text
$AttributionText = "Monolith IT"
$TitleText = "Your device has not performed a restart in $Uptime days"
#$BodyText1 = "For performance and stability reasons we suggest a reboot at least once a week."
# Pick the string at the random index
$BodyText1 = $stringList[$randomIndex]
$BodyText2 = "Please save your work and restart your device today. Thank you in advance."
$Action1 = "ToastReboot:"

# Check for required entries in registry for when using Powershell as application for the toast
# Register the AppID in the registry for use with the Action Center, if required
$RegPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings'
$AppPWSH = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'

# Creating registry entries if they don't exist
if (-NOT(Test-Path -Path "$RegPath\$AppPWSH")) {
    New-Item -Path "$RegPath\$AppPWSH" -Force
    New-ItemProperty -Path "$RegPath\$AppPWSH" -Name 'ShowInActionCenter' -Value 1 -PropertyType 'DWORD'
}

# Make sure the app used with the action center is enabled
if ((Get-ItemProperty -Path "$RegPath\$AppPWSH" -Name 'ShowInActionCenter' -ErrorAction SilentlyContinue).ShowInActionCenter -ne '1') {
    New-ItemProperty -Path "$RegPath\$AppPWSH" -Name 'ShowInActionCenter' -Value 1 -PropertyType 'DWORD' -Force
}


# Formatting the toast notification XML
$snoozed = Get-ItemProperty -Path $global:RegistryPath -Name Snoozed -ErrorAction Ignore
if ($null -ne $snoozed -or $snoozed -eq 1) {
[xml]$Toast = @"
<toast scenario="$Scenario">
    <visual>
    <binding template="ToastGeneric">
        <image placement="hero" src="$HeroImage"/>
        <image id="1" placement="appLogoOverride" hint-crop="circle" src="$LogoImage"/>
        <text placement="attribution">$AttributionText</text>
        <text>$HeaderText</text>
        <group>
            <subgroup>
                <text hint-style="title" hint-wrap="true" >$TitleText</text>
            </subgroup>
        </group>
        <group>
            <subgroup>     
                <text hint-style="body" hint-wrap="true" >$BodyText1</text>
            </subgroup>
        </group>
        <group>
            <subgroup>     
                <text hint-style="body" hint-wrap="true" >$BodyText2</text>
            </subgroup>
        </group>
    </binding>
    </visual>
    <actions>
        <action activationType="protocol" arguments="$Action1" content="Restart" />
    </actions>
</toast>
"@
}
else {
[xml]$Toast = @"
<toast scenario="$Scenario">
    <visual>
    <binding template="ToastGeneric">
        <image placement="hero" src="$HeroImage"/>
        <image id="1" placement="appLogoOverride" hint-crop="circle" src="$LogoImage"/>
        <text placement="attribution">$AttributionText</text>
        <text>$HeaderText</text>
        <group>
            <subgroup>
                <text hint-style="title" hint-wrap="true" >$TitleText</text>
            </subgroup>
        </group>
        <group>
            <subgroup>     
                <text hint-style="body" hint-wrap="true" >$BodyText1</text>
            </subgroup>
        </group>
        <group>
            <subgroup>     
                <text hint-style="body" hint-wrap="true" >$BodyText2</text>
            </subgroup>
        </group>
    </binding>
    </visual>
    <actions>
        <input id="snoozeTime" type="selection" title="Click snooze to be reminded again in:" defaultInput="240">
            <selection id="240" content="4 Hours"/>
            <selection id="360" content="6 Hours"/>
            <selection id="480" content="8 Hours"/>
        </input>
        <action activationType="protocol" arguments="$Action1" content="Restart" />
        <action activationType="system" arguments="snooze" hint-inputId="snoozeTime" content="Snooze"/>
        <action activationType="system" arguments="dismiss" content="Dismiss"/>
    </actions>
</toast>
"@
}

# This option is able to prevent multiple toast notification from being displayed in a row
$LastRunTimeOutput = Get-NotificationLastRunTime
if (-NOT[string]::IsNullOrEmpty($LastRunTimeOutput)) {
    if ($LastRunTimeOutput -lt $LimitToastToRunEveryMinutesValue) {
        Write-Log -Level Error -Message "Toast notification was displayed too recently"
        Write-Log -Level Error -Message "Toast notification was displayed $LastRunTimeOutput minutes ago and script is configured to allow $LimitToastToRunEveryMinutesValue minutes intervals"
        break
    }
}

# Send the notification
Write-Log -Message "Toast notification is used in regards to pending reboot. Uptime $Uptime days."
Display-ToastNotification
Exit 0
