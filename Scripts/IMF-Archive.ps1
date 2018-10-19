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

#Read Settings from XML
Write-Log -Message "Reading from $XMLFile"
[xml]$Settings = Get-Content $XMLFile -ErrorAction Stop -WarningAction Stop

#Verify Connection to DeploymentRoot
Write-Log -Message "Verify Connection to DeploymentRoot"
$Result = Test-Path -Path $Settings.Settings.MDT.DeploymentShare
If($Result -ne $true){
    Write-Log -Message "Cannot access $($Settings.Settings.MDT.DeploymentShare) , will break"
    break
}

#Creating folder
Write-Log -Message "Creating $($Settings.Settings.MDT.DeploymentShare)\Capture\Archive if needed"
New-Item -ItemType Directory -Path "$($Settings.Settings.MDT.DeploymentShare)\Captures\Archive" -Force

#Moving files
Write-Log -Message "Moving files from $($Settings.Settings.MDT.DeploymentShare)\Captures to $($Settings.Settings.MDT.DeploymentShare)\Captures\Archive"
$WIMs = Get-ChildItem -Path "$($Settings.Settings.MDT.DeploymentShare)\Captures" -Filter *.wim
foreach($wim in $WIMs){
    Write-Log -Message "Moving $($wim.FullName) to $($Settings.Settings.MDT.DeploymentShare)\Captures\Archive"
    Move-Item -Path $wim.FullName -Destination "$($Settings.Settings.MDT.DeploymentShare)\Captures\Archive" -Force
}


Write-Log -Message "Done"
Return "OK"