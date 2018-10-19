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
)

#Requires -RunAsAdministrator

#Inititial Settings
$CurrentPath = Split-Path -parent $MyInvocation.MyCommand.Path
$RootPath = Split-Path -parent $CurrentPath
$Global:ScriptLogFilePath = "$RootPath\IMF.log"
$XMLFile = "$RootPath\IMF.xml"
$Global:writetoscreen = $true

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

#Connect to MDT
Write-Log -Message "Connect to MDT"
$Root = $Settings.Settings.MDT.DeploymentShare
if((Test-Path -Path MDT:) -eq $false){
    $MDTPSDrive = New-PSDrive -Name MDT -PSProvider MDTProvider -Root $Root -ErrorAction Stop
    Write-Log -Message "Connected to $($MDTPSDrive.Root)"
}

#Update bootimage
Write-Log -Message "Updating boot image, please wait"
Update-MDTDeploymentShare -Path MDT: -ErrorAction Stop
Write-Log -Message "Done"
Return "OK"
