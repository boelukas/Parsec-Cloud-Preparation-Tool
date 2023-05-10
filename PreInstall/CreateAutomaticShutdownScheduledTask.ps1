# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
  if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
   $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
   Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
   Exit
  }
 }
 
 Write-Host "This sets your machine to shutdown if it is idle for X minutes. Idle means there is no user input(e.g keyboard, mouse, gamepads).
 This is intended to save you money if you ever forget to shut your machine down.
 You will get a warning message pop up 10 minutes before shutdown"
 
 Do {[int]$read = read-host "How much time should the system idle for before shutting down? Time in Minutes - Minimum 10"}
 while ($read -lt "10")
 $read | Out-File $env:Programdata\ParsecLoader\Autoshutdown.txt
 
 try {Get-ScheduledTask -TaskName "Automatically Shutdown on Idle" -ErrorAction Stop | Out-Null
 Unregister-ScheduledTask -TaskName "Automatically Shutdown on Idle" -Confirm:$false
 }
 catch {}

 $idleShutdownTask = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>This script runs at startup and monitors for idle</Description>
    <URI>\Automatically Shutdown on Idle</URI>
  </RegistrationInfo>
  <Triggers>
    <LogonTrigger>
      <Enabled>true</Enabled>
    </LogonTrigger>
    <EventTrigger>
      <Enabled>true</Enabled>
      <Subscription>&lt;QueryList&gt;&lt;Query Id="0" Path="Microsoft-Windows-TaskScheduler/Operational"&gt;&lt;Select Path="Microsoft-Windows-TaskScheduler/Operational"&gt;*[EventData
[@Name='TaskSuccessEvent'][Data[@Name='TaskName']='\Automatically Shutdown on Idle']]&lt;/Select&gt;&lt;/Query&gt;&lt;/QueryList&gt;</Subscription>
    </EventTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>false</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT72H</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>C:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe</Command>
      <Arguments>-executionpolicy bypass -windowstyle hidden -file %programdata%\ParsecLoader\automatic-shutdown.ps1</Arguments>
    </Exec>
  </Actions>
</Task>
"@

 # Enable all Task History to restart the task once it finised
 wevtutil set-log Microsoft-Windows-TaskScheduler/Operational /enabled:true

 Register-ScheduledTask -TaskName "Automatically Shutdown on Idle" -Xml $idleShutdownTask -Force
 Start-ScheduledTask -TaskName "Automatically Shutdown on Idle"

 Write-Output "Successfully Created"
 pause