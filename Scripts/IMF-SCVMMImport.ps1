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
    [ValidateSet($True,$False)] 
    $UpdateBootImage = $False,

    [parameter(mandatory=$false)] 
    [ValidateSet($True,$False)] 
    $EnableMDTMonitoring = $True,

    [parameter(mandatory=$false)] 
    [ValidateSet($True,$False)] 
    $EnableWSUS = $True,

    [parameter(mandatory=$false)] 
    [ValidateSet($True,$False)] 
    $TestMode = $False
)

#Set start time
$StartTime = Get-Date

Function Get-VIARefTaskSequence
{
    Param(
    $RefTaskSequenceFolder
    )
    $RefTaskSequences = Get-ChildItem $RefTaskSequenceFolder
    Foreach($RefTaskSequence in $RefTaskSequences){
        New-Object PSObject -Property @{ 
        TaskSequenceID = $RefTaskSequence.ID
        Name = $RefTaskSequence.Name
        Comments = $RefTaskSequence.Comments
        Version = $RefTaskSequence.Version
        Enabled = $RefTaskSequence.enable
        LastModified = $RefTaskSequence.LastModifiedTime
        } 
    }
}
Function Update-Log
{
    Param(
    [Parameter(
        Mandatory=$true, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true,
        Position=0
    )]
    [string]$Data,

    [Parameter(
        Mandatory=$false, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true,
        Position=0
    )]
    [string]$Solution = $Solution,

    [Parameter(
        Mandatory=$false, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true,
        Position=1
    )]
    [validateset('Information','Warning','Error')]
    [string]$Class = "Information"

    )
    $LogString = "$Solution, $Data, $Class, $(Get-Date)"
    $HostString = "$Solution, $Data, $(Get-Date)"
    
    Add-Content -Path $Log -Value $LogString
    switch ($Class)
    {
        'Information'{
            Write-Host $HostString -ForegroundColor Gray
            }
        'Warning'{
            Write-Host $HostString -ForegroundColor Yellow
            }
        'Error'{
            Write-Host $HostString -ForegroundColor Red
            }
        Default {}
    }
}

#Inititial Settings
Clear-Host
$Log = "C:\Setup\ImageFactoryV3ForHyper-V\log.txt"
$XMLFile = "C:\setup\ImageFactoryV3ForHyper-V\ImageFactoryV3.xml"
$Solution = "IMF32"
Update-Log -Data "Imagefactory 3.2 (Hyper-V)"
Update-Log -Data "Logfile is $Log"
Update-Log -Data "XMLfile is $XMLfile"

if($TestMode -eq $True){
    Update-Log -Data "Testmode is now $TestMode"
}

#Importing modules
Update-Log -Data "Importing modules"
Import-Module 'C:\Program Files\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1' -ErrorAction Stop -WarningAction Stop

#Read Settings from XML
Update-Log -Data "Reading from $XMLFile"
[xml]$Settings = Get-Content $XMLFile -ErrorAction Stop -WarningAction Stop

#Verify Connection to DeploymentRoot
Update-Log -Data "Verify Connection to DeploymentRoot"
$Result = Test-Path -Path $Settings.Settings.MDT.DeploymentShare
If($Result -ne $true){Update-Log -Data "Cannot access $($Settings.Settings.MDT.DeploymentShare) , will break";break}

#Connect to MDT
Update-Log -Data "Connect to MDT"
$Root = $Settings.Settings.MDT.DeploymentShare
if((Test-Path -Path MDT:) -eq $false){
    $MDTPSDrive = New-PSDrive -Name MDT -PSProvider MDTProvider -Root $Root -ErrorAction Stop
    Update-Log -Data "Connected to $($MDTPSDrive.Root)"
}

#Get MDT Settings
Update-Log -Data "Get MDT Settings"
$MDTSettings = Get-ItemProperty MDT:


#Get TaskSequences
Update-Log -Data "Get TaskSequences"
$RefTaskSequenceIDs = (Get-VIARefTaskSequence -RefTaskSequenceFolder "MDT:\Task Sequences\$($Settings.Settings.MDT.RefTaskSequenceFolderName)").TasksequenceID
if($RefTaskSequenceIDs.count -eq 0){
    Update-Log -Data "Sorry, could not find any TaskSequences to work with"
    BREAK
    }
Update-Log -Data "Found $($RefTaskSequenceIDs.count) TaskSequences to work on"

#Get detailed info
Update-Log -Data "Get detailed info about the task sequences"
$Result = Get-VIARefTaskSequence -RefTaskSequenceFolder "MDT:\Task Sequences\$($Settings.Settings.MDT.RefTaskSequenceFolderName)"
foreach($obj in ($Result | Select-Object TaskSequenceID,Name,Version)){
    $data = "$($obj.TaskSequenceID) $($obj.Name) $($obj.Version)"
    Update-Log -Data $data
}

foreach ($item in $Result){
    $VHDName = $item.TaskSequenceID + "_UEFI.vhdx"
    $OSName = $item.Name
    $scriptblock = {
        $libraryObject = Get-SCVirtualHardDisk -Name "WS2016-01-2_UEFI.vhdx" | Where-Object Directory -Like "\\SFADEPL01.FABRIC.SEAL-SOFTWARE.CLOUD\VHD*"
        foreach($Item in $libraryObject){
            $os = Get-SCOperatingSystem | Where-Object Name -Like "* 2012 r2 standard"
            Set-SCVirtualHardDisk -VirtualHardDisk $libraryObject -OperatingSystem $os -VirtualizationPlatform "Unknown" -Name "WS2012R2-01-1_UEFI.vhdx" -Description "" -Release "" -FamilyName ""
        }

    }
}
