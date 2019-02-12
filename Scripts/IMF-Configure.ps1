<#
.Synopsis
    ImageFactory 3.2
.DESCRIPTION
    ImageFactory 3.2
.EXAMPLE
    ImageFactoryV3-Build.ps1
.NOTES
    Created:	 2016-11-24
    Version:	 3.1

    Updated:	 2017-02-23
    Version:	 3.2


    Author - Mikael Nystrom
    Twitter: @mikael_nystrom
    Blog   : http://deploymentbunny.com

    Disclaimer:
    This script is provided 'AS IS' with no warranties, confers no rights and 
    is not supported by the author.

    This script uses the PsIni module:
    Blog		: http://oliver.lipkau.net/blog/ 
	Source		: https://github.com/lipkau/PsIni
	http://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91

.LINK
    http://www.deploymentbunny.com
#>

[cmdletbinding(SupportsShouldProcess=$True)]
Param(
    [parameter(mandatory=$false)] 
    [string]
    $DeploymentShare = "NA",

    [parameter(mandatory=$false)] 
    [string]
    $Computername = "NA",

    [parameter(mandatory=$false)] 
    [string]
    $SwitchName = "NA",

    [parameter(mandatory=$false)] 
    [string]
    $VLANID = "0",

    [parameter(mandatory=$false)] 
    [string]
    $VMLocation = "NA",

    [parameter(mandatory=$false)] 
    [string]
    $ISOLocation = "",

    [parameter(mandatory=$false)] 
    [string]
    $BuildaccountName = "MDT_BA",

    [parameter(mandatory=$false)] 
    [string]
    $BuildaccountPassword = "P@ssw0rd",

    [parameter(mandatory=$false)] 
    [string]
    $CustomerName = "ViaMonstra",

    [parameter(mandatory=$false)] 
    [string]
    $ConcurrentRunningVMs = "2",

    [parameter(mandatory=$false)] 
    [string]
    $StartUpRAM = "3"
)

#Requires -RunAsAdministrator

#Inititial Settings
$CurrentPath = split-path -parent $MyInvocation.MyCommand.Path
$RootPath = split-path -parent $CurrentPath
#$RootPath = "D:\IMFv3"
$Global:ScriptLogFilePath = "$RootPath\IMF.log"
$XMLFile = "$RootPath\IMF.xml"
$Global:writetoscreen = $true

#Install IMFFuctions
Copy-item -Path "$RootPath\Functions\IMFFunctions" -Destination 'C:\Program Files\WindowsPowerShell\Modules' -ErrorAction Stop -Recurse -Force
Import-Module IMFFunctions -ErrorAction Stop -WarningAction Stop -Force
Write-Log -Message "Module IMFFunctions imported"

#Install PSINI
if((Get-Module PSINI).name -ne "PSINI"){
    Install-Module PSINI -Force -SkipPublisherCheck -ErrorAction Stop
}else{Update-Module PSINI -Force}
Import-Module PsIni -ErrorAction Stop -WarningAction Stop -MinimumVersion 2.0.5
Write-Log -Message "Module PsIni imported"

#Importing ModuleMicrosoftDeploymentToolkit
Import-Module 'C:\Program Files\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1' -ErrorAction Stop -WarningAction Stop
Write-Log -Message "ModuleMicrosoftDeploymentToolkit imported"

#Inititial Settings
Write-Log -Message "Imagefactory 3.2 (Hyper-V)"
Write-Log -Message "Logfile is $ScriptLogFilePath"
Write-Log -Message "XMLfile is $XMLfile"

#Read Settings from XML
Write-Log -Message "Reading from $XMLFile"
[xml]$Settings = Get-Content $XMLFile -ErrorAction Stop -WarningAction Stop

#Update XMLfile
Write-Log -Message "Update XML file"
$Settings.Settings.HyperV.Computername = $Computername
$Settings.Settings.HyperV.VMLocation = $VMLocation
$Settings.Settings.HyperV.ISOLocation = $ISOLocation
$Settings.Settings.HyperV.VLANID = $VLANID
$Settings.Settings.HyperV.StartUpRAM = $StartUpRAM
$Settings.Settings.HyperV.SwitchName = $SwitchName
$settings.Settings.MDT.DeploymentShare = $DeploymentShare
$settings.Settings.ConcurrentRunningVMs = $ConcurrentRunningVMs
$settings.Settings.Security.BuildAccount.Name =  $BuildaccountName
$settings.Settings.Security.BuildAccount.Password =  $BuildaccountPassword
$settings.Settings.CustomerName = $CustomerName

#Save cnfig fie
Write-Log -Message "Save to XML file"
$settings.Save("$XMLFile")
Write-Log -Message "Done"