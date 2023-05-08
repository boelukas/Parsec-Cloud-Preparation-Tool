# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
 if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
  $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
  Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
  Exit
 }
}

Write-Host "This sets your machine to shutdown if Windows detects it as idle for X minutes.
This is intended to save you money if you ever forget to shut your machine down.
You will get a warning message pop up 10 minutes before shutdown"

$taskFileName = $env:ProgramData+"\ParsecLoader\ShutdownTask.xml" 
Register-ScheduledTask -TaskName "IdleShutdownTask" -Xml (Get-Content $taskFileName | Out-String) -Force


Write-Output "Successfully Created"

pause
