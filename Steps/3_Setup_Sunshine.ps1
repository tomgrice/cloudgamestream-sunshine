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

Start-ScheduledTask -TaskName "StartSunshine" | Out-Null

Start-Sleep -Seconds 2
Write-Host "Startup task added successfully." -ForegroundColor Green
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

<#
$objShell = New-Object -ComObject WScript.Shell
$explorerFile = "C:\Windows\explorer.exe"

$URL = "https://localhost:47990"

$webLink = $objShell.SpecialFolders("AllUsersPrograms") + "\Sunshine\Web Control Panel.lnk"
If (Test-Path $webLink){
    Remove-Item $webLink
}

$objShortcut = $objShell.CreateShortcut($webLink)
$objShortcut.IconLocation = "explorer.exe,12"
$objShortcut.TargetPath = $explorerFile
$objShortcut.Arguments = $URL
$objShortcut.Save()

$cmdFile = "cmd.exe"

$exePath = "$SunshineDir\sunshine.exe"

$exeShortcut = $objShell.SpecialFolders("AllUsersPrograms") + "\Sunshine\Start Sunshine.lnk"
If (Test-Path $exeShortcut){
    Remove-Item $exeShortcut
}

$objShortcut = $objShell.CreateShortcut($exeShortcut)
$objShortcut.IconLocation = "explorer.exe,12"
$objShortcut.TargetPath = $cmdFile
$objShortcut.Arguments = "/c start $exePath"
$objShortcut.Save() #>



Write-Host "Adding a GameStream rule to the Windows Firewall..."
New-NetFirewallRule -DisplayName "NVIDIA GameStream TCP" -Direction inbound -LocalPort 47984,47989,48010,47990 -Protocol TCP -Action Allow | Out-Null
New-NetFirewallRule -DisplayName "NVIDIA GameStream UDP" -Direction inbound -LocalPort 47998,47999,48000,48010,47990 -Protocol UDP -Action Allow | Out-Null
