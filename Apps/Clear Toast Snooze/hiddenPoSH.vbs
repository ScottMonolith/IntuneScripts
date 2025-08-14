Dim shell,command
command = "powershell.exe -windowstyle hidden -noprofile -executionpolicy bypass -file ""%appdata%\ToastNotificationScript\Scripts\Clear-SnoozedToasts.ps1"""
set objShell = CreateObject("wscript.shell")
objShell.Run command,0