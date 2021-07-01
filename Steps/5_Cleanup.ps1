If (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $Arguments = "& '" + $MyInvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $Arguments
    Break
}

Write-Host ""
Write-Host "Performing cleanup of unnecessary install files." -ForegroundColor Yellow
Remove-Item "$PSScriptRoot\..\Bin\Drivers" -Recurse -Force
Remove-Item "$PSScriptRoot\..\Bin\vbcable" -Recurse -Force
Remove-Item "$PSScriptRoot\..\Drivers.zip" -Force
Remove-Item "$PSScriptRoot\..\redist_x64.exe" -Force
Remove-Item "$PSScriptRoot\..\redist_x86.exe" -Force
Remove-Item "$PSScriptRoot\..\Sunshine-Windows.zip" -Force
Remove-Item "$PSScriptRoot\..\vbcable.zip" -Force
Remove-Item "$PSScriptRoot\..\ViGEmBus.exe" -Force
Write-Host "Clean up complete!" -ForegroundColor Yellow
