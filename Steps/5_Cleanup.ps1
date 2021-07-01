If (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $Arguments = "& '" + $MyInvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $Arguments
    Break
}

$WorkDir = "$PSScriptRoot\..\Bin\"
$SunshineDir = "$ENV:ProgramData\sunshine"

Write-Host ""
Write-Host "Performing cleanup of unnecessary install files." -ForegroundColor Yellow
