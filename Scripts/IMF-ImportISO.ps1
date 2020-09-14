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
    $ISOImage,
    $OSFolder,
    $OrgName
)

#Inititial Settings
$CurrentPath = split-path -parent $MyInvocation.MyCommand.Path
$RootPath = split-path -parent $CurrentPath
#$RootPath = "D:\IMFv3"
$Global:ScriptLogFilePath = "$RootPath\IMF.log"
$XMLFile = "$RootPath\IMF.xml"
$Global:writetoscreen = $true

#Importing modules
Import-Module IMFFunctions -ErrorAction Stop -WarningAction Stop -Force
Write-Log -Message "Module IMFFunctions imported"
Import-Module 'C:\Program Files\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1' -ErrorAction Stop -WarningAction Stop
Write-Log -Message "ModuleMicrosoftDeploymentToolkit imported"

#Read Settings from XML
Write-Log -Message "Reading from $XMLFile"
[xml]$Settings = Get-Content $XMLFile -ErrorAction Stop -WarningAction Stop

#Verify path to ISO
Write-Log -Message "Verify path to $ISOImage"
$Result = Test-Path -Path $ISOImage
If($Result -ne $true){
    Write-Log -Message "Cannot access $ISOImage , will break" -LogLevel 3
    Return "Fail"
    break
}

#Verify Connection to DeploymentRoot
Write-Log -Message "Verify Connection to DeploymentRoot"
$Result = Test-Path -Path $Settings.Settings.MDT.DeploymentShare
If($Result -ne $true){
    Write-Log -Message "Cannot access $($Settings.Settings.MDT.DeploymentShare) , will break" -LogLevel 3
    Return "Fail"
    Exit
}

#Connect to MDT
Write-Log -Message "Connect to MDT"
$Root = $Settings.Settings.MDT.DeploymentShare
if((Test-Path -Path MDT:) -eq $false){
    $MDTPSDrive = New-PSDrive -Name MDT -PSProvider MDTProvider -Root $Root -ErrorAction Stop
    Write-Log -Message "Connected to $($MDTPSDrive.Root)"
}

#Check if folder already exists
Write-Log -Message "Checking if $OSFolder already exists"
$Result = Test-Path -Path "$($MDTPSDrive.Root)\Operating Systems\$OSFolder"
If($Result -eq $true){
    Write-Log -Message "$OSFolder already exists , will break" -LogLevel 3
    Return "Fail"
    Exit
}

#Import ISO
Write-Log -Message "Working on $ISOImage"
    
$DiskImage = Mount-DiskImage -ImagePath $ISOImage -PassThru -ErrorAction Stop
Write-Log -Message "Succesfully mounted $($DiskImage.imagepath)"

$Result = Import-MDTOperatingSystem -Path "MDT:\Operating Systems\Msft" -SourcePath "$(($DiskImage | Get-Volume).DriveLetter):\" -DestinationFolder $OSFolder
Write-Log -Message "Succesfully imported $($item.name) in $($item.source)"
    
$Return = Dismount-DiskImage -ImagePath $DiskImage.ImagePath
Write-Log -Message "Succesfully dismounted $($Return.Imagepath)"

$Return = New-Item -Path "MDT:\Packages" -enable "True" -Name $OSFolder -Comments "" -ItemType "folder"
Write-Log -Message "Succesfully created $($Return.name) in $($Return.NodeType)"

$Return = New-Item -path "MDT:\Selection Profiles" -enable "True" -Name $OSFolder -Comments "" -Definition "<SelectionProfile><Include path=`"Packages\$($OSFolder)`" /></SelectionProfile>" -ReadOnly "False"
Write-Log -Message "Succesfully created $($Return.name) in $($Return.NodeType)"

    
foreach($item in $Result){
    if($item.Description -like "*Windows Server*"){
        $Template = "Server.xml"
    }
    else{
        $Template = "Client.xml"
    }
        
    $item | select *
    $Name = "Ref $($item.ImageName) for $($OSFolder)"
    $ID = "$OSFolder-$($item.ImageIndex)"
    $OperatingSystemPath = "MDT:\Operating Systems\Msft\$($item.name)"
    Import-MDTTaskSequence -path "MDT:\Task Sequences\Reference" -Name $Name -Template $Template -Comments "" -ID $ID -Version "1.0" -OperatingSystemPath $OperatingSystemPath -FullName $item.OrgName -OrgName $item.OrgName -HomePage "about:blank"
    Import-MDTApplication -path "MDT:\Applications\Bundles" -enable "True" -Name "Install - Bundle used by $Name" -ShortName "Install - Bundle used by $Name" -Version "" -Publisher "" -Language "" -Bundle
}


$TSFolders = Get-ChildItem "$($Settings.Settings.MDT.DeploymentShare)\Control" -Filter *.
foreach($TSFolder in $TSFolders){
    $TSXML = [xml](Get-Content -Path "$($TSFolder.FullName)\ts.xml")
    $StateRestore = $TSXML.sequence.group | Where-Object Name -EQ 'State Restore'
    ($StateRestore.step | Where-Object Name -EQ 'Windows Update (Post-Application Installation)').disable = 'false'
    ($StateRestore.step | Where-Object Name -EQ 'Windows Update (Pre-Application Installation)').disable = 'false'
    $TSXML.Save("$($TSFolder.FullName)\ts.xml")
}

$TSFolders = Get-ChildItem "$($Settings.Settings.MDT.DeploymentShare)\Control" -Filter *.
foreach($TSFolder in $TSFolders){
    $TSXML = [xml](Get-Content -Path "$($TSFolder.FullName)\ts.xml")
    $BaseName = $($TSFolder.Name).Split("-")[0]
    $SelectionProfileName = Get-ChildItem -Path "mdt:\Selection Profiles" | Where-Object name -Like $BaseName*
    $PreInstall = $TSXML.sequence.group | Where-Object Name -EQ 'PreInstall'
    (($PreInstall.step| Where-Object Name -EQ 'Apply Patches').defaultVarList.variable | Where-Object name -EQ PackageSelectionProfile | Where-Object Property -EQ PackageSelectionProfile).'#text' = $SelectionProfileName.Name
    $TSXML.Save("$($TSFolder.FullName)\ts.xml")
}
Return "OK"
