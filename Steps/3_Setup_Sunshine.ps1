If (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $Arguments = "& '" + $MyInvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $Arguments
    Break
}

Write-Host "Enabling NVIDIA FrameBufferCopy..."
$ExitCode = (Start-Process -FilePath "$WorkDir\NvFBCEnable.exe" -ArgumentList "-enable" -NoNewWindow -Wait -PassThru).ExitCode
if($ExitCode -ne 0) {
    throw "Failed to enable NvFBC. (Error: $ExitCode)"
} else {
    Write-Host "Enabled NvFBC successfully." -ForegroundColor DarkGreen
}

Write-Host "Adding startup task for Sunshine." -ForegroundColor Green

if (!(Get-ScheduledTask -TaskName "StartSunshine" -ErrorAction SilentlyContinue)) {
    $action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c start /min sunshine.exe" -WorkingDirectory "$SunshineDir"
    $trigger = New-ScheduledTaskTrigger -AtLogon -RandomDelay "00:00:20"
    $principal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Administrators" -RunLevel Highest
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "StartSunshine" -Principal $principal -Description "Runs Sunshine at startup" | Out-Null
}

Start-Sleep -Seconds 2
Write-Host "Startup task added successfully." -ForegroundColor Green
Write-Host ""
Write-Host "Please choose a username and pasword to configure Sunshine."
$NewUsername = Read-Host "Username"
$NewPassword = Read-Host "Password"

$NewSalt = (([char[]]([char]'a'..[char]'z') + 0..9 | sort {get-random})[0..16] -join '')

$NewHash = $NewPassword + $NewSalt
$NewHash = new-object System.Security.Cryptography.SHA256Managed | ForEach-Object {$_.ComputeHash([System.Text.Encoding]::UTF8.GetBytes("$NewHash"))} | ForEach-Object {$_.ToString("x2")}
[array]::Reverse($NewHash)
$NewHash = ($NewHash -join '').ToUpper()

@{username="$NewUsername";salt="$NewSalt";password="$NewHash"} | ConvertTo-Json | Out-File "$SunshineDir\sunshine_state.json" -Encoding ascii

Write-Host ""
Write-Host "Starting Sunshine for the first time..."
Write-Host ""

Start-Process -FilePath "$SunshineDir\sunshine.exe"

Write-Host ""
Write-Host "Adding Desktop shortcuts" -ForegroundColor Green
Copy-Item "$WorkDir\settings.ico" -Destination "$SunshineDir"
Copy-Item "$WorkDir\sun.ico" -Destination "$SunshineDir"
$TargetFile = "cmd.exe"
$ShortcutFile = "$env:Public\Desktop\Start Sunshine.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Arguments = "/c start sunshine.exe"
$Shortcut.WorkingDirectory = $SunshineDir
$Shortcut.IconLocation = "$WorkDir\sun.ico"
$Shortcut.Save()

$TargetFile = "$ENV:windir\explorer.exe"
$ShortcutFile = "$env:Public\Desktop\Sunshine Settings.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.IconLocation = "$WorkDir\settings.ico"
$Shortcut.Arguments = "https://localhost:47990"

$Shortcut.Save()

Write-Host "Adding GameStream rules to Windows Firewall..."
New-NetFirewallRule -DisplayName "NVIDIA GameStream TCP" -Direction inbound -LocalPort 47984,47989,48010,47990 -Protocol TCP -Action Allow | Out-Null
New-NetFirewallRule -DisplayName "NVIDIA GameStream UDP" -Direction inbound -LocalPort 47998,47999,48000,48010,47990 -Protocol UDP -Action Allow | Out-Null
