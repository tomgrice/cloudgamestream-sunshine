# Cloud GameStream (sunshine fork)

## Fork objectives
This fork is intended to install dependencies, tweaks and software to enable the sunshine cloud streaming server on cloud instances.
Sunshine is an open-source implementation of NVIDIA GameStream, compatible with Moonlight streaming client and also AMD-based GPUs.
Read more about sunshine here: https://github.com/loki-47-6F-64/sunshine
This project is based on the fantastic work of [acceleration3](https://github.com/acceleration3).

## What is it?
A Powershell one-click solution to enable NVIDIA GeForce Experience GameStream on a cloud machine with a vGaming supporting GPU. This is powered by sunshine, which is an open source implementation of NVIDIA GameStream.  
&nbsp;  

## Installation
Copy and paste these commands in the machine's Powershell prompt (requires Administrator permissions):
```
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls";Set-ExecutionPolicy Unrestricted;Invoke-WebRequest -Uri https://github.com/tomgrice/cloudgamestream-sunshine/releases/download/June2021a/cloudgamestream-sunshine.zip -OutFile arch.zip;Add-Type -Assembly "System.IO.Compression.Filesystem";$dir = [string](Get-Location);rmdir -r cloudgamestream-master -ErrorAction Ignore;[System.IO.Compression.ZipFile]::ExtractToDirectory($dir + "\arch.zip", $dir);cd cloudgamestream;./Setup.ps1
```
Or you can download the script and binaries from [here](https://github.com/tomgrice/cloudgamestream-sunshine/releases/download/June2021a/cloudgamestream-sunshine.zip).  
&nbsp;  
&nbsp;  

## Compatibility
Tested and working on the following:

* OS:
	* Windows Server 2019

* Platforms:
	* Amazon AWS EC2 g4dn.xlarge Tesla T4

&nbsp;  
## FAQ
### Will this work on \<insert platform and instance name here\>?
Focus is currently being put on just AWS EC2 g4dn.xlarge instances during development. As development continues, more platforms and Windows versions will be tested.

### I can't connect to my VM using Moonlight.
  You need to forward the ports on your machine. The ports you need to forward are 47984, 47989, 48010, 47990 TCP and 47998, 47999, 48000, 48010 UDP. If you're having more problems try downloading the [Moonlight Internet Streaming Tool](https://github.com/moonlight-stream/Internet-Hosting-Tool/releases) and troubleshooting it. The latest release of sunshine (0.8.0) now also supports UPnP which may forward required ports automatically if supported by your network adapter.

### How do
  You can visit the web control panel via the desktop shortcut once installed. You will need your login credentials which you are prompted for during installation.

&nbsp;  
&nbsp;
## Many thanks to
### Installing on AWS
  [acceleration3](https://reddit.com/u/acceleration3)

  [TechGuru on YouTube](https://www.youtube.com/channel/UCPmCidEAN9JrG1OwahlAkIQ)

### Contact me on Reddit
  [u/gricey91](https://reddit.com/u/gricey91)
