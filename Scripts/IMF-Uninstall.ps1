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

#Inititial Settings
$CurrentPath = split-path -parent $MyInvocation.MyCommand.Path
$RootPath = split-path -parent $CurrentPath
$Global:ScriptLogFilePath = "$RootPath\IMF.log"
$XMLFile = "$RootPath\IMF.xml"
$Global:writetoscreen = $true

#Importing modules
Import-Module IMFFunctions -ErrorAction Stop -WarningAction Stop -Force
Write-Log -Message "Module IMFFunctions imported"
Import-Module 'C:\Program Files\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1' -ErrorAction Stop -WarningAction Stop
Write-Log -Message "Module MicrosoftDeploymentToolkit imported"

Write-Log -Message "Imagefactory 3.2 (Hyper-V)"
Write-Log -Message "Logfile is $Log"
Write-Log -Message "XMLfile is $XMLfile"

#Read Settings from XML
Write-Log -Message "Reading from $XMLFile"
[xml]$Settings = Get-Content $XMLFile -ErrorAction Stop -WarningAction Stop

#Get deploymentshare folder
Write-Log -Message "Get Deploymentshare settings"
$DeploymentShare = $settings.Settings.MDT.DeploymentShare

#Verify Connection to DeploymentRoot
Write-Log -Message "Verify Connection to DeploymentRoot"
$Result = Test-Path -Path $Settings.Settings.MDT.DeploymentShare
If($Result -ne $true){
    Write-Log -Message "Cannot access $($Settings.Settings.MDT.DeploymentShare) , will break" -LogLevel 2
    Return "Fail"
    break
}

#Connect to MDT
Write-Log -Message "Connect to MDT"
$Root = $Settings.Settings.MDT.DeploymentShare
if((Test-Path -Path MDT:) -eq $false){
    $MDTPSDrive = New-PSDrive -Name MDT -PSProvider MDTProvider -Root $Root -ErrorAction Stop
    Write-Log -Message "Connected to $($MDTPSDrive.Root)"
}

#Get MDT Settings
Write-Log -Message "Get MDT Settings"
$MDTSettings = Get-ItemProperty MDT:

#Get SMB Share
Write-Log -Message "Get SMB Share"
$result = Get-SmbShare | Where-Object Path -EQ $MDTSettings.PhysicalPath | Remove-SmbShare -Force -PassThru
Write-Log -Message "Removed file share"

#Get MDT Settings
Write-Log -Message "Get Folder"
$result = Get-Item -Path $MDTSettings.PhysicalPath | Remove-Item -Recurse -Force
Write-Log -Message "Removed Folder"
Return "OK"