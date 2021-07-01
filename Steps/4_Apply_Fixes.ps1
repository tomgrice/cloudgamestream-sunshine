If (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $Arguments = "& '" + $MyInvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $Arguments
    Break
}

$osType = Get-CimInstance -ClassName Win32_OperatingSystem

if($osType.ProductType -eq 3) {
    Write-Host "Installing Wireless Networking."
    Install-WindowsFeature -Name Wireless-Networking | Out-Null
}


Start-Sleep -Seconds 2

Write-Host "Applying AWS Windows Licencing fix."
Import-Module "$ENV:ProgramData\Amazon\EC2-Windows\Launch\Module\Ec2Launch.psd1"
Add-Routes
Set-ActivationSettings
slmgr //B /ato

Write-Host "Setting resolution to 1080p."
displayswitch.exe /internal
Start-Sleep -Seconds 6
Set-DisplayResolution -Width 1920 -Height 1080 -Force
