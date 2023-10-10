
## Step 1
[Net.ServicePointManager]::SecurityProtocol
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-Module PowershellGet -RequiredVersion 2.2.4 -SkipPublisherCheck
(Get-ItemProperty ‘HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full’ -Name Release).Release

## Step 2 
[Net.ServicePointManager]::securityProtocol = [Net.ServicePointManager]::SecurityProtocol 
Register-PSRepository -Default -Verbose
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted

##Step 3 
## install NetworkingDSC
Install-Module -Name NetworkingDsc -RequiredVersion 7.0.0.0

## install SqlServerDSC
Install-Module -Name SqlServerDsc -RequiredVersion 12.3.0.0

##Step 4 Check is NetworkingDSC got installed with correct version
get-installedmodule -name *dsc
