$OS = Get-CimInstance Win32_OperatingSystem
$Uptime = (Get-Date) - ($OS.LastBootUpTime)
$appId = 'Toast.Custom.App' # This should match whichever AppId you're using to create the toasts
$searchText = '*' # A text string that exists only in the toasts that you're trying to match. Or set to '*' if you want to match anything.

$Load = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
$toastNotifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId)
$scheduled = $toastNotifier.getScheduledToastNotifications()

$scheduled.ForEach({
    if ($_.Content.InnerText -like $searchText)
    {
        $toastNotifier.RemoveFromSchedule($_)
    }
})
if ($Uptime.TotalHours -lt 1) {
    $RegistryPath = "HKCU:\SOFTWARE\ToastNotificationScript"
    if ((Get-ItemProperty -Path $RegistryPath -Name Snoozed -ErrorAction Ignore)) {
        Set-ItemProperty -Path $RegistryPath -Name Snoozed -Value 0 -Force | Out-Null
    }
}