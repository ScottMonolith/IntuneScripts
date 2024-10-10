$taskExists = Get-ScheduledTask | Where-Object {$_.TaskName -eq "Clear Snoozed Toasts"}

if($taskExists) {
  Write-Host "Success"
  Exit 0
}
else {
  Write-Host "Task does not exist"
  Exit 1
}