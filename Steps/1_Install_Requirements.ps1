Param([Parameter(Mandatory=$false)] [Switch]$Main)

If (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $Arguments = "& '" + $MyInvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $Arguments
    Break
}

$WorkDir = "$PSScriptRoot\..\Bin"

Function Download-File([string]$Url, [string]$Path, [string]$Name) {
    try {
        if(![System.IO.File]::Exists($Path)) {
	        Write-Host "Downloading `"$Name`"..."
	        Start-BitsTransfer $Url $Path
        }
    } catch {
        throw "`"$Name`" download failed."
    }
}

Import-Module BitsTransfer

$InstallAudio = (Read-Host "You need to have an audio interface installed for GameStream to work. Install VBCABLE? (y/n)").ToLower() -eq "y"
$InstallVideo = (Read-Host "You also need the NVIDIA vGaming Drivers installed. Installing will reboot your machine. Install the tested and recommended ones? (y/n)").ToLower() -eq "y"

Download-File "https://github.com/loki-47-6F-64/sunshine/releases/download/v0.7.7/Sunshine-Windows.zip" "$WorkDir\Sunshine-Windows.zip" "Sunshine Moonlight Host v0.7.7"
Download-File "https://aka.ms/vs/16/release/vc_redist.x86.exe" "$WorkDir\redist_x86.exe" "Visual C++ Redist 2015-19 x86"
if($ENV:PROCESSOR_ARCHITECTURE -eq 'AMD64') { Download-File "https://aka.ms/vs/16/release/vc_redist.x64.exe" "$WorkDir\redist_x64.exe" "Visual C++ Redist 2015-19 x64" }
if($InstallAudio) { Download-File "https://download.vb-audio.com/Download_CABLE/VBCABLE_Driver_Pack43.zip" "$WorkDir\vbcable.zip" "VBCABLE" }
if($InstallVideo) {
    $WebContent = Invoke-WebRequest -Uri 'https://nvidia-gaming.s3.amazonaws.com/?list-type=2&prefix=windows/latest&encoding-type=url&max-keys=1&start-after=windows/latest/'
    [xml]$xmlVideoDriverS3 = $WebContent.Content
    $VideoDriverURL = "https://nvidia-gaming.s3.amazonaws.com/" + $xmlVideoDriverS3.ListBucketResult.Contents.Key
    Download-File "$VideoDriverURL" "$WorkDir\Drivers.zip" "NVIDIA vGaming Drivers"
}

# Replace below with Apollo/sunshine install
Write-Host "Extracting Sunshine v0.7.7..."

Expand-Archive -Path "$WorkDir\Sunshine-Windows.zip" -DestinationPath "$ENV:HOMEDRIVE\sunshine" -Force

# Below to be updated with AIO redist install
Write-Host "Installing Visual C++ Redist 2015-19 x86..."

$ExitCode = (Start-Process -FilePath "$WorkDir\redist_x86.exe" -ArgumentList "/install","/q","/norestart" -NoNewWindow -Wait -Passthru).ExitCode
if($ExitCode -eq 0) { Write-Host "Installed." -ForegroundColor Green }
elseif($ExitCode -eq 1638) { Write-Host "Newer version already installed." -ForegroundColor Green }
else {
    throw "Visual C++ Redist 2015-19 x86 installation failed (Error: $ExitCode)."
}

if($ENV:PROCESSOR_ARCHITECTURE -eq 'AMD64') {
    Write-Host "Installing Visual C++ Redist 2015-19 x64..."

    $ExitCode = (Start-Process -FilePath "$WorkDir\redist_x64.exe" -ArgumentList "/install","/q","/norestart" -NoNewWindow -Wait -Passthru).ExitCode
    if($ExitCode -eq 0) { Write-Host "Installed." -ForegroundColor Green }
    elseif($ExitCode -eq 1638) { Write-Host "Newer version already installed." -ForegroundColor Green }
    else {
         throw "Visual C++ Redist 2015-19 x64 installation failed (Error: $ExitCode)."
    }
}

if($InstallAudio) {
    Write-Host "Installing VBCABLE..."
    Expand-Archive -Path "$WorkDir\vbcable.zip" -DestinationPath "$WorkDir\vbcable"
    Start-Process -FilePath "$WorkDir\vbcable\VBCABLE_Setup_x64.exe" -ArgumentList "-i","-h" -NoNewWindow -Wait

    $osType = Get-CimInstance -ClassName Win32_OperatingSystem

    if($osType.ProductType -eq 3) {
        Write-Host "Applying Audio service fix for Windows Server..."
        New-ItemProperty "hklm:\SYSTEM\CurrentControlSet\Control" -Name "ServicesPipeTimeout" -Value 600000 -PropertyType "DWord" | Out-Null
        Set-Service -Name Audiosrv -StartupType Automatic | Out-Null
    }
}

if($InstallVideo) {
    if($Main) {
        Write-Host "Installing NVIDIA vGaming GPU drivers... Your machine will reboot after installing."
        $script = "-Command `"Set-ExecutionPolicy Unrestricted; & '$PSScriptRoot\..\Setup.ps1'`" -RebootSkip";
        $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $script
        $trigger = New-ScheduledTaskTrigger -AtLogon -RandomDelay "00:00:30"
        $principal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Administrators" -RunLevel Highest
        Register-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -TaskName "GSSetup" -Description "GSSetup" | Out-Null
    }
    Expand-Archive -Path "$WorkDir\Drivers.zip" -DestinationPath "$WorkDir\Drivers"
    $InstallPath = Resolve-Path "$WorkDir\Drivers\*server2019_64bit_international.exe"
    $ExitCode = (Start-Process -FilePath "$InstallPath" -ArgumentList "/s","/clean" -NoNewWindow -Wait -PassThru).ExitCode
    if($ExitCode -eq 0) {
        if($Main) {
            Write-Host "Adding required registry entries." -ForegroundColor Green
            New-ItemProperty -Path "HKLM:\SOFTWARE\NVIDIA Corporation\Global" -Name "vGamingMarketplace" -PropertyType "DWord" -Value "2"
            Write-Host "Acquiring NVIDIA vGaming activation certificate" -ForegroundColor Green
            Download-File "https://nvidia-gaming.s3.amazonaws.com/GridSwCert-Archive/GridSwCertWindows_2021_10_2.cert" "$ENV:PUBLIC\Documents\GridSwCert.txt" "NVIDIA vGaming Certificate"
            Write-Host "NVIDIA vGaming GPU drivers installed. The script will now restart the machine." -ForegroundColor Green
            Start-Sleep -Seconds 3
            Restart-Computer -Force
            Start-Sleep -Seconds 10
            throw "Failed to restart after 10 seconds. Please restart manually."
        } else {
            Write-Host "NVIDIA vGaming GPU drivers installed." -ForegroundColor Green
        }
    } else {
        if($Main) {
            Unregister-ScheduledTask -TaskName "GSSetup" -Confirm:$false
        }

        Write-Host "Failed to install the recommended NVIDIA vGaming driver due to possible incompatibility." -ForegroundColor Red
        $UseExternalScript = (Read-Host "Would you like to use the Cloud GPU Updater script by jamesstringerparsec? The driver the script will install may or may not be compatible with this patch. A shortcut will be created in the Desktop to continue this installation after finishing the script. (y/n)").ToLower() -eq "y"
        if($UseExternalScript) {
            $Shell = New-Object -comObject WScript.Shell
            $Shortcut = $Shell.CreateShortcut("$Home\Desktop\Continue GFE Patching.lnk")
            $Shortcut.TargetPath = "powershell.exe"
            $Shortcut.Arguments = "-Command `"Set-ExecutionPolicy Unrestricted; & '$PSScriptRoot\..\Setup.ps1'`" -RebootSkip"
            $Shortcut.Save()
            Download-File "https://github.com/jamesstringerparsec/Cloud-GPU-Updater/archive/master.zip" "$WorkDir\updater.zip" "Cloud GPU Updater"

            if(![System.IO.File]::Exists("$WorkDir\Updater")) {
                Expand-Archive -Path "$WorkDir\updater.zip" -DestinationPath "$WorkDir\Updater"
            }

            Start-Process -FilePath "powershell.exe" -ArgumentList "-Command `"$WorkDir\Updater\Cloud-GPU-Updater-master\GPUUpdaterTool.ps1`""
            [Environment]::Exit(0)
        }
    }
}
