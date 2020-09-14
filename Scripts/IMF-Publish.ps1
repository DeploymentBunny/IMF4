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
    [switch]$VHDBIOS,
    [switch]$VHDUEFI
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

Write-Log -Message "Import Module"
Import-Module 'C:\Program Files\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1' -ErrorAction Stop -WarningAction Stop

$Root = $Settings.Settings.MDT.DeploymentShare
if((Test-Path -Path MDT:) -eq $false){
    $MDTPSDrive = New-PSDrive -Name MDT -PSProvider MDTProvider -Root $Root -ErrorAction Stop
    Write-Log -Message "Connected to $($MDTPSDrive.Root)"
}

#Verify Connection to DeploymentRoot
Write-Log -Message "Verify Connection to DeploymentRoot"
$Result = Test-Path -Path $Settings.Settings.MDT.DeploymentShare
If($Result -ne $true){
    Write-Log -Message "Cannot access $($Settings.Settings.MDT.DeploymentShare) , will break"
    break
}

# Make Sure destination exists
Write-Log -Message "Creating $($Settings.Settings.PublishingFolder)"
New-Item  -Path "$($Settings.Settings.PublishingFolder)" -Force -ItemType Directory

# Get all capture images
Write-Log -Message "Enumarating .WIM files in $($Settings.Settings.MDT.DeploymentShare)\Captures"
$Items = Get-ChildItem -Path "$($Settings.Settings.MDT.DeploymentShare)\Captures" -Filter *.wim

# Match wim with ts
foreach($item in $items){
    Write-Log -Message "Working on $($Item.BaseName)"
    $TSInfo = Get-ChildItem -Path "MDT:\Task Sequences\Reference" -Recurse | Where-Object ID -EQ $Item.BaseName
    $WIMInfo = Get-WindowsImage -ImagePath $item.FullName -Index 1

    # Copy the WIM file
    Write-Log -Message "Copy $($item.FullName) to $($Settings.Settings.PublishingFolder)"
    Copy-Item -Path $item.FullName -Destination "$($Settings.Settings.PublishingFolder)\$($item.Name)" -Force

    $VHDBIOSFileName = "NA"
    $VHDUEFIFileName = "NA"

    if($VHDBIOS){
        Write-Log -Message "Creating $($item.Basename + "_BIOS.vhdx")"
        if(Test-Path -Path "$($Settings.Settings.PublishingFolder)\$($item.Basename + "_BIOS.vhdx")"){
            Remove-Item -Path "$($Settings.Settings.PublishingFolder)\$($item.Basename + "_BIOS.vhdx")" -Force
        }
        
        .\Scripts\Convert-VIAWIM2VHD.ps1 -Sourcefile $item.FullName -DestinationFile "$($Settings.Settings.PublishingFolder)\$($item.Basename + "_BIOS.vhdx")" -SizeInMB 100000 -Disklayout BIOS -Index 1
        $VHDBIOSFileName = $($item.Basename + "_BIOS.vhdx")
    }

    if($VHDUEFI){
        Write-Log -Message "Creating $($item.Basename + "_UEFI.vhdx")"
        if(Test-Path -Path "$($Settings.Settings.PublishingFolder)\$($item.Basename + "_UEFI.vhdx")"){
            Remove-Item -Path "$($Settings.Settings.PublishingFolder)\$($item.Basename + "_UEFI.vhdx")" -Force
        }
        
        .\Scripts\Convert-VIAWIM2VHD.ps1 -Sourcefile $item.FullName -DestinationFile "$($Settings.Settings.PublishingFolder)\$($item.Basename + "_UEFI.vhdx")" -SizeInMB 100000 -Disklayout UEFI -Index 1
        $VHDUEFIFileName = $($item.Basename + "_UEFI.vhdx")
    }

    $CustomData = [pscustomobject]@{
    Name = $item.Name
    Location = "/"
    FileName = $item.Name
    FileCreationTime = $item.Name
    FileLength = $item.Length
    TSID = $TSInfo.ID
    TSName = $TSInfo.Name
    TSVersion = $TSInfo.Version
    WIMVersion = $WIMInfo.Version
    WIMCreatedTime = $WIMInfo.CreatedTime
    WIMImageName = $WIMInfo.ImageName
    WIMImageSize = $WIMInfo.ImageSize
    WIMArchitecture = $WIMInfo.Architecture
    WIMEditionID = $WIMInfo.EditionId
    WIMProductType = $WIMInfo.ProductType
    WIMInstallationType = $WIMInfo.InstallationType
    WIMMajorVersion = $WIMInfo.MajorVersion
    WIMMinorVersion = $WIMInfo.MinorVersion
    WIMBuild = $WIMInfo.Build
    WIMSPBuild = $WIMInfo.SPBuild
    WIMLanguages = $WIMInfo.Languages
    }

    
    $FilePath = "$($Settings.Settings.PublishingJsonFolder)" + "\$($item.Name)" + ".json"
    Write-Log -Message "Creating $FilePath"
    $CustomData | ConvertTo-Json | Out-File -FilePath $FilePath -Force

    if($VHDBIOSFileName -ne "NA"){
        $CustomData = [pscustomobject]@{
        Name = $VHDBIOSFileName
        Location = "/"
        FileName = $VHDBIOSFileName
        FileCreationTime = $item.Name
        FileLength = $item.Length
        TSID = $TSInfo.ID
        TSName = $TSInfo.Name
        TSVersion = $TSInfo.Version
        WIMVersion = $WIMInfo.Version
        WIMCreatedTime = $WIMInfo.CreatedTime
        WIMImageName = $WIMInfo.ImageName
        WIMImageSize = $WIMInfo.ImageSize
        WIMArchitecture = $WIMInfo.Architecture
        WIMEditionID = $WIMInfo.EditionId
        WIMProductType = $WIMInfo.ProductType
        WIMInstallationType = $WIMInfo.InstallationType
        WIMMajorVersion = $WIMInfo.MajorVersion
        WIMMinorVersion = $WIMInfo.MinorVersion
        WIMBuild = $WIMInfo.Build
        WIMSPBuild = $WIMInfo.SPBuild
        WIMLanguages = $WIMInfo.Languages
        }

        $FilePath = "$($Settings.Settings.PublishingJsonFolder)" + "\$($VHDBIOSFileName)" + ".json"
        Write-Log -Message "Creating $FilePath"
        $CustomData | ConvertTo-Json | Out-File -FilePath $FilePath -Force
    }

    if($VHDUEFIFileName -ne "NA"){
        $CustomData = [pscustomobject]@{
        Name = $VHDUEFIFileName
        Location = "/"
        FileName = $VHDUEFIFileName
        FileCreationTime = $item.Name
        FileLength = $item.Length
        TSID = $TSInfo.ID
        TSName = $TSInfo.Name
        TSVersion = $TSInfo.Version
        WIMVersion = $WIMInfo.Version
        WIMCreatedTime = $WIMInfo.CreatedTime
        WIMImageName = $WIMInfo.ImageName
        WIMImageSize = $WIMInfo.ImageSize
        WIMArchitecture = $WIMInfo.Architecture
        WIMEditionID = $WIMInfo.EditionId
        WIMProductType = $WIMInfo.ProductType
        WIMInstallationType = $WIMInfo.InstallationType
        WIMMajorVersion = $WIMInfo.MajorVersion
        WIMMinorVersion = $WIMInfo.MinorVersion
        WIMBuild = $WIMInfo.Build
        WIMSPBuild = $WIMInfo.SPBuild
        WIMLanguages = $WIMInfo.Languages
        }
        $FilePath = "$($Settings.Settings.PublishingJsonFolder)" + "\$($VHDUEFIFileName)" + ".json"
        Write-Log -Message "Creating $FilePath"
        $CustomData | ConvertTo-Json | Out-File -FilePath $FilePath -Force
    }

}

# Create CatalogFile

$JItems = Get-ChildItem -Path "$($Settings.Settings.PublishingJsonFolder)" -Filter *.json | Where-Object Name -NE catalog.json
$Catalog = foreach($JItem in $JItems){
    Get-Content -Path $JItem.FullName | ConvertFrom-Json
}
$CatalogFilePath = "$($Settings.Settings.PublishingJsonFolder)" + "\catalog.json"
if(Test-Path -Path $CatalogFilePath){Remove-Item -Path $CatalogFilePath -Force}
Write-Log -Message "Creating $CatalogFilePath"
$Catalog | ConvertTo-Json > $CatalogFilePath

Write-Log -Message "Done"
Return "OK"