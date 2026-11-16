# Keeps Windows from going to sleep while it runs. Nothing is changed in the power settings: when
# this process ends, normal sleep comes back by itself.
# The screen stays on too. This laptop uses Modern Standby, where turning the screen off puts the
# whole machine into standby; asking only for the system to stay awake didn't prevent that on
# 2026-10-22, and the downloads and tunnels froze for 40 minutes while the pods billed.
# Closing the lid can still sleep the laptop, depending on the lid setting.
#   powershell -NoProfile -ExecutionPolicy Bypass -File keep_awake.ps1 [-Hours 12]
param([double]$Hours = 12)

Add-Type -Namespace Win32 -Name Power -MemberDefinition @'
[DllImport("kernel32.dll", SetLastError = true)]
public static extern uint SetThreadExecutionState(uint esFlags);
'@
$ES_CONTINUOUS = [uint32]"0x80000000"
$ES_SYSTEM_REQUIRED = [uint32]"0x00000001"
$ES_DISPLAY_REQUIRED = [uint32]"0x00000002"

$until = (Get-Date).AddHours($Hours)
Write-Output "keep-awake on until $($until.ToString('HH:mm')) (close this to allow sleep again)"
while ((Get-Date) -lt $until) {
    [void][Win32.Power]::SetThreadExecutionState($ES_CONTINUOUS -bor $ES_SYSTEM_REQUIRED -bor $ES_DISPLAY_REQUIRED)
    Start-Sleep -Seconds 60
}
[void][Win32.Power]::SetThreadExecutionState($ES_CONTINUOUS)
Write-Output "keep-awake off"
