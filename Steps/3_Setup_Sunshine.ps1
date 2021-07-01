If (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $Arguments = "& '" + $MyInvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $Arguments
    Break
}

$WorkDir = "$PSScriptRoot\..\Bin\"
$SunshineDir = "$ENV:HOMEDRIVE\sunshine"

Write-Host "Enabling NVIDIA FrameBufferCopy..."
$ExitCode = (Start-Process -FilePath "$WorkDir\NvFBCEnable.exe" -ArgumentList "-enable" -NoNewWindow -Wait -PassThru).ExitCode
if($ExitCode -ne 0) {
    throw "Failed to enable NvFBC. (Error: $ExitCode)"
} else {
    Write-Host "Enabled NvFBC successfully." -ForegroundColor DarkGreen
}

Write-Host "Adding startup task for Sunshine." -ForegroundColor Green

if (!(Get-ScheduledTask -TaskName "StartSunshine")) {
    $action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c start /min sunshine.exe" -WorkingDirectory "$SunshineDir"
    $trigger = New-ScheduledTaskTrigger -AtLogon -RandomDelay "00:00:20"
    $principal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Administrators" -RunLevel Highest
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "StartSunshine" -Principal $principal -Description "Runs Sunshine at startup" | Out-Null
}

Start-Sleep -Seconds 2
Write-Host "Startup task added successfully." -ForegroundColor Green

Write-Host ""
Write-Host "Starting Sunshine for the first time..."
Write-Host ""
Write-Host "You MUST make note of the username and password generated in the Sunshine application." -ForegroundColor White -BackgroundColor White
Write-Host "You will need this to configure Sunshine. You can change these credentials later." -ForegroundColor White -BackgroundColor White

Start-Process -FilePath "$SunshineDir\sunshine.exe"

Write-Host "Adding Desktop shortcuts" -ForegroundColor Green

$TargetFile = "$SunshineDir\sunshine.exe"
$ShortcutFile = "$env:Public\Desktop\Start Sunshine.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Save()

$TargetFile = "$ENV:windir/explorer.exe"
$ShortcutFile = "$env:Public\Desktop\Sunshine Settings.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Arguments = "https://localhost:47990"
$Shortcut.Save()

Write-Host "Adding GameStream rules to Windows Firewall..."
New-NetFirewallRule -DisplayName "NVIDIA GameStream TCP" -Direction inbound -LocalPort 47984,47989,48010,47990 -Protocol TCP -Action Allow | Out-Null
New-NetFirewallRule -DisplayName "NVIDIA GameStream UDP" -Direction inbound -LocalPort 47998,47999,48000,48010,47990 -Protocol UDP -Action Allow | Out-Null
