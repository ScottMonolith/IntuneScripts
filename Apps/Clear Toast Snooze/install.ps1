<#
if (!(Test-Path C:\temp)) {
    New-Item -Path C:\temp -ItemType Directory
}
# Copy the XML file
Copy-Item ".\Clear Snoozed Toasts.xml" "C:\temp"
#>

if (!(Test-Path $env:APPDATA\ToastNotificationScript\Scripts)) {
    New-Item -Path $env:APPDATA\ToastNotificationScript\Scripts -ItemType Directory
}
Copy-Item ".\Clear-SnoozedToasts.ps1" $env:APPDATA\ToastNotificationScript\Scripts\
# Register a new Scheduled Task using the XML
Register-ScheduledTask -xml (Get-Content .\ClearSnoozedToastsTask.xml | Out-String) -TaskName "Clear Snoozed Toasts" -TaskPath "\"
