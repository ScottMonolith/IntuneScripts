Function Get-LoggedInUser {
	try {
		$SessionList = quser 2>$null
		if ($SessionList) {
			$UserInfo = foreach ($Session in ($SessionList | Select-Object -Skip 1)) {
				$Session = $Session.ToString().trim() -replace '\s+', ' ' -replace '>', ''
				if ($Session.Split(' ')[3] -eq 'Active') {
					[PSCustomObject]@{
						UserName     = $session.Split(' ')[0]
						SessionName  = $session.Split(' ')[1]
						SessionID    = $Session.Split(' ')[2]
						SessionState = $Session.Split(' ')[3]
						IdleTime     = $Session.Split(' ')[4]
						LogonTime    = $session.Split(' ')[5, 6, 7] -as [string] -as [datetime]
					}
				} else {
					[PSCustomObject]@{
						UserName     = $session.Split(' ')[0]
						SessionName  = $null
						SessionID    = $Session.Split(' ')[1]
						SessionState = 'Disconnected'
						IdleTime     = $Session.Split(' ')[3]
						LogonTime    = $session.Split(' ')[4, 5, 6] -as [string] -as [datetime]
					}
				}
			}
			$UserInfo | Sort-Object LogonTime
		}
	} catch {
		Write-Error $_.Exception.Message
	}
}

$taskExists = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {$_.TaskName -eq "Clear Snoozed Toasts v1.0.3"}

if ($taskExists) {
	Write-Host "Task exists"
	$User = (Get-LoggedInUser).UserName
	if (Test-Path "C:\Users\$User\AppData\Roaming\ToastNotificationScript\Scripts\hiddenPoSH.vbs") {
		Write-Host "VBS script exists"
		if (Test-Path "C:\Users\$User\AppData\Roaming\ToastNotificationScript\Scripts\Clear-SnoozedToasts.ps1") {
			Write-Host "Clear Toasts PoSH script exists"
			Exit 0
		}
		else {
			Write-Host "Clear Toasts PoSH script does NOT exist, run installer."
			Exit 1
		}
	}
	else {
		Write-Host "VBS script does NOT exist, run installer."
		Exit 1
	}
}
else {
	Write-Host "Task does not exist"
	Exit 1
}