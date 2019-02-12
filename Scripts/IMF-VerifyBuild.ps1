<#
.Synopsis
    ImageFactory 3.3
.DESCRIPTION
    ImageFactory 3.3
.EXAMPLE
    ImageFactoryV3-Verify-Build.ps1
.NOTES
    Created:	 2016-11-24
    Version:	 3.1

    Updated:	 2017-02-23
    Version:	 3.2

    Updated:	 2017-09-27
    Version:	 3.3


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
    $KeepVMs = $False
)

#Set start time
$StartTime = Get-Date

$CurrentPath = split-path -parent $MyInvocation.MyCommand.Path
$RootPath = split-path -parent $CurrentPath

#Inititial Settings
$CurrentPath = split-path -parent $MyInvocation.MyCommand.Path
$RootPath = split-path -parent $CurrentPath
$Log = "$RootPath\IMF.log"
$Global:ScriptLogFilePath = "$RootPath\IMF.log"
$XMLFile = "$RootPath\IMF.xml"
$Global:writetoscreen = $true

#Importing modules
Import-Module PSINI -ErrorAction Stop -WarningAction Stop -Force -MinimumVersion 2.0.5
Write-Log -Message "Module PSINI imported"
Import-Module IMFFunctions -ErrorAction Stop -WarningAction Stop -Force
Write-Log -Message "Module IMFFunctions imported"
Import-Module 'C:\Program Files\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1' -ErrorAction Stop -WarningAction Stop
Write-Log -Message "Module MicrosoftDeploymentToolkit imported"

#Read Settings from XML
Write-Log -Message "Reading $XMLFile"
[xml]$Settings = Get-Content $XMLFile -ErrorAction Stop -WarningAction Stop

#Verify Connection to DeploymentRoot
$DeployrootPath = $Settings.Settings.MDT.DeploymentShare
Write-Log -Message "Verify path to $DeployrootPath"
$Result = Test-Path -Path $DeployrootPath
If($Result -ne $true){
    Write-Log -Message "Cannot access $DeployrootPath , will break"
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

#Get MDT Settings
Write-Log -Message "Get MDT Settings"
$MDTSettings = Get-ItemProperty MDT:

#Check if we should use MDTmonitoring
Write-Log -Message "Check if we should use MDTmonitoring"
if((Get-ItemProperty -Path MDT:).MonitorHost -ne $env:COMPUTERNAME){
    Write-Log -Message "Not using MDT monitoring"
    $EnableMDTMonitoring = $False
}else{
    Write-Log -Message "Using MDT monitoring"
    $MDTServer = $env:COMPUTERNAME
    $EnableMDTMonitoring = $True
}

#Verify access to boot image
Write-Log -Message "Verify access to boot image"
$MDTImage = $($Settings.Settings.MDT.DeploymentShare) + "\boot\" + $($MDTSettings.'Boot.x86.LiteTouchISOName')
if((Test-Path -Path $MDTImage) -eq $true){Write-Log -Message "Access to $MDTImage is ok"}else{Write-Warning "Could not access $MDTImage";BREAK}

#Import the WIMs and Create TS
$CaptureFolder = "$($Settings.Settings.MDT.DeploymentShare)\Captures"
$wims = Get-ChildItem -Path $CaptureFolder -Filter *.wim
foreach($wim in $wims){
    $ImageName = $wim.BaseName
    $RefTaskSequenceTemplate = Get-ChildItem -Path "MDT:\Task Sequences\$($Settings.Settings.MDT.RefTaskSequenceFolderName)" -Recurse | Where-Object ID -EQ $ImageName
    Write-Log -Message "Using $($RefTaskSequenceTemplate.TaskSequenceTemplate) as template"
    $ImportedOS = Import-MDTOperatingSystem -Path "MDT:\Operating Systems\$($Settings.Settings.MDT.ValidateOSImageFolderName)" -SourceFile $wim.FullName -DestinationFolder $wim.BaseName
    $Return = Import-MDTTaskSequence -Path "MDT:\Task Sequences\$($Settings.Settings.MDT.ValidateTaskSequenceFolderName)" -Name "Validate $($wim.BaseName)" -Template $RefTaskSequenceTemplate.TaskSequenceTemplate -Comments "Validation Tasksequence" -ID ($($wim.BaseName).Replace(($($wim.BaseName).Substring(0,1)),'V')) -Version "1.0" -OperatingSystemPath "MDT:\Operating Systems\$($Settings.Settings.MDT.ValidateOSImageFolderName)\$($ImportedOS.name)" -FullName "ViaMonstra" -OrgName "ViaMonstra" -HomePage "about:blank"
    Write-Log -Message "Created TaskSequence $($return.Name)"
}

#Get TaskSequences
Write-Log -Message "Get TaskSequences"
$TaskSequences = Get-ChildItem -Path "MDT:\Task Sequences\$($Settings.Settings.MDT.ValidateTaskSequenceFolderName)"
if($TaskSequences.count -eq 0){
    Write-Log -Message "Sorry, could not find any TaskSequences to work with"
    Return "Fail"
    Exit
    }else{
        foreach($TaskSequence in $TaskSequences){
            $data = "$($TaskSequence.ID) $($TaskSequence.Name) $($TaskSequence.Version)"
            Write-Log -Message $data
    }
}

#Cleanup MDT Monitoring data
Write-Log -Message "Cleanup MDT Monitoring data"
if($EnableMDTMonitoring -eq $True){
    foreach($TaskSequence in $TaskSequences){
        Write-Log -Message "Cleanup MDT Monitoring data for $($TaskSequence.id)"
        Get-MDTMonitorData -Path MDT: | Where-Object -Property Name -EQ -Value $($TaskSequence.id) | Remove-MDTMonitorData -Path MDT:
    }
}

#Verify Connection to Hyper-V host
Write-Log -Message "Verify Connection to Hyper-V host"
$HyperVHostName = $Settings.Settings.HyperV.Computername
$Result = Test-VIAHypervConnection -Computername $HyperVHostName -ISOFolder $Settings.Settings.HyperV.ISOLocation -VMFolder $Settings.Settings.HyperV.VMLocation -VMSwitchName $Settings.Settings.HyperV.SwitchName
If($Result -ne $true){
    Write-Log -Message "$HyperVHostName is not ready, will break"
    Return "Fail"
    Exit
}
elseIf($Result -eq $true){
    Write-Log -Message "$HyperVHostName is ready, moving on"
}

#Building VM's
Write-Log -Message "Building VM's"
Foreach($TaskSequence in $TaskSequences){
    $VMName = $TaskSequence.id
    $VMMemory = [int]$($Settings.Settings.HyperV.StartUpRAM) * 1GB
    $VMPath = $($Settings.Settings.HyperV.VMLocation)
    $VMBootimage = $($Settings.Settings.HyperV.ISOLocation) + "\" +  $($MDTImage | Split-Path -Leaf)
    $VMVHDSize = [int]$($Settings.Settings.HyperV.VHDSize) * 1GB
    $VMVlanID = $($Settings.Settings.HyperV.VLANID)
    $VMVCPU = $($Settings.Settings.HyperV.NoCPU)
    $VMSwitch = $($Settings.Settings.HyperV.SwitchName)
    Write-Log -Message "Building $VMName"
    Invoke-Command -ComputerName $($Settings.Settings.HyperV.Computername) -ScriptBlock {
    Param(
        $VMName,
        $VMMemory,
        $VMPath,
        $VMBootimage,
        $VMVHDSize,
        $VMVlanID,
        $VMVCPU,
        $VMSwitch
    )        
    #Check if VM exist
    if(!((Get-VM | Where-Object -Property Name -EQ -Value $VMName).count -eq 0)){
        Write-Warning -Message "VM exist"
        Return "Fail"
        Exit
    }

    #Create VM 
    $VM = New-VM -Name $VMName -MemoryStartupBytes $VMMemory -Path $VMPath -NoVHD -Generation 1
    Write-Verbose "$($VM.Name) is created"

    #Disable dynamic memory 
    Set-VMMemory -VM $VM -DynamicMemoryEnabled $false
    Write-Verbose "Dynamic memory is disabled on $($VM.Name)"

    #Connect to VMSwitch 
    Connect-VMNetworkAdapter -VMNetworkAdapter (Get-VMNetworkAdapter -VM $VM) -SwitchName $VMSwitch
    Write-Verbose "$($VM.Name) is connected to $VMSwitch"

    #Set vCPU
    if($VMVCPU -ne "1"){
        $Result = Set-VMProcessor -Count $VMVCPU -VM $VM -Passthru
        Write-Verbose "$($VM.Name) has $($Result.count) vCPU"
    }
    
    #Set VLAN
    If($VMVlanID -ne "0"){
        $Result = Set-VMNetworkAdapterVlan -VlanId $VMVlanID -Access -VM $VM -Passthru
        Write-Verbose "$($VM.Name) is configured for VLANid $($Result.NativeVlanId)"
    }

    #Create empty disk
    $VHD = $VMName + ".vhdx"
    $result = New-VHD -Path "$VMPath\$VMName\Virtual Hard Disks\$VHD" -SizeBytes $VMVHDSize -Dynamic -ErrorAction Stop
    Write-Verbose "$($result.Path) is created for $($VM.Name)"

    #Add VHDx
    $result = Add-VMHardDiskDrive -VMName $VMName -Path "$VMPath\$VMName\Virtual Hard Disks\$VHD" -Passthru
    Write-Verbose "$($result.Path) is attached to $VMName"
    
    #Connect ISO 
    $result = Set-VMDvdDrive -VMName $VMName -Path $VMBootimage -Passthru
    Write-Verbose "$($result.Path) is attached to $VMName"

    #Set Notes
    Set-VM -VMName $VMName -Notes "VALIDATE"

    } -ArgumentList $VMName,$VMMemory,$VMPath,$VMBootimage,$VMVHDSize,$VMVlanID,$VMVCPU,$VMSwitch
}

#Get BIOS Serialnumber from each VM and update the customsettings.ini file
Write-Log -Message "Get BIOS Serialnumber from each VM and update the customsettings.ini file"
$BIOSSerialNumbers = @{}
Foreach($TaskSequence in $TaskSequences){

    #Get BIOS Serailnumber from the VM
    $BIOSSerialNumber = Invoke-Command -ComputerName $($Settings.Settings.HyperV.Computername) -ScriptBlock {
        Param(
        $VMName
        )
        $VMObject = Get-WmiObject -Namespace root\virtualization\v2 -Class Msvm_ComputerSystem -Filter "ElementName = '$VMName'"
        $VMObject.GetRelated('Msvm_VirtualSystemSettingData').BIOSSerialNumber
    } -ArgumentList $TaskSequence.id
    
    #Store serialnumber for the cleanup process
    $BIOSSerialNumbers.Add("$($TaskSequence.id)","$BIOSSerialNumber")
    
    #Get the Report Application
    $ApplicationName = $Settings.Settings.MDT.ReportApplicationName
    $AppGuid = (Get-ChildItem "MDT:\Applications" -Recurse | Where-Object Name -EQ $ApplicationName).guid

    #Update CustomSettings.ini

    $IniFile = "$($Settings.settings.MDT.DeploymentShare)\Control\CustomSettings.ini"
    $CustomSettings = Get-IniContent -FilePath $IniFile -CommentChar ";"

    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$BIOSSerialNumber" -NameValuePairs @{"OSDComputerName"="$($TaskSequence.ID)"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$BIOSSerialNumber" -NameValuePairs @{"TaskSequenceID"="$($TaskSequence.ID)"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$BIOSSerialNumber" -NameValuePairs @{"SkipTaskSequence"="YES"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$BIOSSerialNumber" -NameValuePairs @{"SkipApplications"="YES"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$BIOSSerialNumber" -NameValuePairs @{"SkipCapture"="YES"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$BIOSSerialNumber" -NameValuePairs @{"SkipAdminPassword"="YES"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$BIOSSerialNumber" -NameValuePairs @{"SkipProductKey"="YES"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$BIOSSerialNumber" -NameValuePairs @{"SkipComputerName"="YES"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$BIOSSerialNumber" -NameValuePairs @{"SkipDomainMembership"="YES"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$BIOSSerialNumber" -NameValuePairs @{"SkipUserData"="YES"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$BIOSSerialNumber" -NameValuePairs @{"SkipLocaleSelection"="YES"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$BIOSSerialNumber" -NameValuePairs @{"SkipTimeZone"="YES"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$BIOSSerialNumber" -NameValuePairs @{"SkipBitLocker"="YES"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$BIOSSerialNumber" -NameValuePairs @{"SkipSummary"="YES"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$BIOSSerialNumber" -NameValuePairs @{"SkipRoles"="YES"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$BIOSSerialNumber" -NameValuePairs @{"SkipFinalSummary"="YES"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$BIOSSerialNumber" -NameValuePairs @{"FinishAction"="SHUTDOWN"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$BIOSSerialNumber" -NameValuePairs @{"DoCapture"="NO"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$BIOSSerialNumber" -NameValuePairs @{"Applications001"="$AppGuid"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
    if(($TaskSequence.TaskSequenceID) -eq "VWSB17623"){
        $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$BIOSSerialNumber" -NameValuePairs @{"OverrideProductKey"="6XBNX-4JQGW-QX6QG-74P76-72V67"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
    }
}

#Start VM's on Host
Write-Log -Message "Start VM's on Host"
Write-Log -Message "ConcurrentRunningVMs is set to: $($Settings.Settings.ConcurrentRunningVMs)"
$return = ""
do
{
    $return = Invoke-Command -ComputerName $($Settings.Settings.HyperV.Computername) -ScriptBlock {
    Param(
        $ConcurrentRunningVMs,
        $MDTServer = "",
        $EnableMDTMonitoring
    ) 
    #Import Function
    Function Get-MDTOData{
    <#
    .Synopsis
        Function for getting MDTOdata
    .DESCRIPTION
        Function for getting MDTOdata
    .EXAMPLE
        Get-MDTOData -MDTMonitorServer MDTSERVER01
    .NOTES
        Created:     2016-03-07
        Version:     1.0
 
        Author - Mikael Nystrom
        Twitter: @mikael_nystrom
        Blog   : http://deploymentbunny.com
 
    .LINK
        http://www.deploymentbunny.com
    #>
    Param(
        $MDTMonitorServer
    ) 
    $URL = "http://" + $MDTMonitorServer + ":9801/MDTMonitorData/Computers"
    $Data = Invoke-RestMethod $URL
    foreach($property in ($Data.content.properties) ){
        $Hash =  [ordered]@{ 
            Name = $($property.Name); 
            PercentComplete = $($property.PercentComplete.'#text'); 
            Warnings = $($property.Warnings.'#text'); 
            Errors = $($property.Errors.'#text'); 
            DeploymentStatus = $( 
            Switch($property.DeploymentStatus.'#text'){ 
                1 { "Active/Running"} 
                2 { "Failed"} 
                3 { "Successfully completed"} 
                Default {"Unknown"} 
                }
            );
            StepName = $($property.StepName);
            TotalSteps = $($property.TotalStepS.'#text')
            CurrentStep = $($property.CurrentStep.'#text')
            DartIP = $($property.DartIP);
            DartPort = $($property.DartPort);
            DartTicket = $($property.DartTicket);
            VMHost = $($property.VMHost.'#text');
            VMName = $($property.VMName.'#text');
            LastTime = $($property.LastTime.'#text') -replace "T"," ";
            StartTime = $($property.StartTime.'#text') -replace "T"," "; 
            EndTime = $($property.EndTime.'#text') -replace "T"," "; 
            }
        New-Object PSObject -Property $Hash
        }
    }

    #Get the VMs as Objects
    $ValVMs = Get-VM | Where-Object -Property Notes -Like -Value "VALIDATE*"
    foreach($ValVM in $ValVMs){
        Write-Verbose "REFVM $($ValVM.Name) is deployed on $($ValVM.ComputerName) at $($Valvm.ConfigurationLocation)"
    }

    #Get the VMs as Objects
    $ValVMs = Get-VM | Where-Object -Property Notes -Like -Value "VALIDATE*"
    foreach($ValVM in $ValVMs){
    $StartedVM = Start-VM -VMName $ValVM.Name
    Write-Verbose "Starting $($StartedVM.name)"
    Do
        {
            $RunningVMs = $((Get-VM | Where-Object -Property Notes -Like -Value "VALIDATE*" | Where-Object -Property State -EQ -Value Running))
            foreach($RunningVM in $RunningVMs){
                if($EnableMDTMonitoring -eq $false){
                    Write-Host "Currently running VM's : $($RunningVMs.Name) at $(Get-Date)"
                }
                else{
                    Get-MDTOData -MDTMonitorServer $MDTServer | Where-Object -Property Name -EQ -Value $RunningVM.Name | Select-Object Name,PercentComplete,Warnings,Errors,DeploymentStatus,StartTime,Lasttime | Format-Table
                }
            }
            Start-Sleep -Seconds "30"
        }
    While((Get-VM | Where-Object -Property Notes -Like -Value "VALIDATE*" | Where-Object -Property State -EQ -Value Running).Count -gt ($ConcurrentRunningVMs - 1))
    }
    Return 0
} -ArgumentList $($Settings.Settings.ConcurrentRunningVMs),$env:COMPUTERNAME,$EnableMDTMonitoring
}
until ($return -eq 0)


#Wait until they are done
Write-Log -Message "Wait until they are done"
$return = ""
$return = Invoke-Command -ComputerName $($Settings.Settings.HyperV.Computername) -ScriptBlock {
    Param(
        $MDTServer = "",
        $EnableMDTMonitoring
    )
    #Import Function
    Function Get-MDTOData{
    <#
    .Synopsis
        Function for getting MDTOdata
    .DESCRIPTION
        Function for getting MDTOdata
    .EXAMPLE
        Get-MDTOData -MDTMonitorServer MDTSERVER01
    .NOTES
        Created:     2016-03-07
        Version:     1.0
 
        Author - Mikael Nystrom
        Twitter: @mikael_nystrom
        Blog   : http://deploymentbunny.com
 
    .LINK
        http://www.deploymentbunny.com
    #>
    Param(
    $MDTMonitorServer
    ) 
    $URL = "http://" + $MDTMonitorServer + ":9801/MDTMonitorData/Computers"
    $Data = Invoke-RestMethod $URL
    foreach($property in ($Data.content.properties) ){
        $Hash =  [ordered]@{ 
            Name = $($property.Name); 
            PercentComplete = $($property.PercentComplete.'#text'); 
            Warnings = $($property.Warnings.'#text'); 
            Errors = $($property.Errors.'#text'); 
            DeploymentStatus = $( 
            Switch($property.DeploymentStatus.'#text'){ 
                1 { "Active/Running"} 
                2 { "Failed"} 
                3 { "Successfully completed"} 
                Default {"Unknown"} 
                }
            );
            StepName = $($property.StepName);
            TotalSteps = $($property.TotalStepS.'#text')
            CurrentStep = $($property.CurrentStep.'#text')
            DartIP = $($property.DartIP);
            DartPort = $($property.DartPort);
            DartTicket = $($property.DartTicket);
            VMHost = $($property.VMHost.'#text');
            VMName = $($property.VMName.'#text');
            LastTime = $($property.LastTime.'#text') -replace "T"," ";
            StartTime = $($property.StartTime.'#text') -replace "T"," "; 
            EndTime = $($property.EndTime.'#text') -replace "T"," "; 
            }
        New-Object PSObject -Property $Hash
        }
    }
    Do{
        $RunningVMs = $((Get-VM | Where-Object -Property Notes -Like -Value "VALIDATE*" | Where-Object -Property State -EQ -Value Running))
            foreach($RunningVM in $RunningVMs){
                if($EnableMDTMonitoring -eq $false){
                    Write-Output "Currently running VM's : $($RunningVMs.Name) at $(Get-Date)"
                }
                else{
                    Get-MDTOData -MDTMonitorServer $MDTServer | Where-Object -Property Name -EQ -Value $RunningVM.Name | Select-Object Name,PercentComplete,Warnings,Errors,DeploymentStatus,StartTime,Lasttime | Format-Table
                }
            }
            Start-Sleep -Seconds "30"
    }until((Get-VM | Where-Object -Property Notes -Like -Value "VALIDATE*" | Where-Object -Property State -EQ -Value Running).count -eq '0')
    Return 0
} -ArgumentList $MDTServer,$EnableMDTMonitoring
$return

#Update CustomSettings.ini
Write-Log -Message "Update CustomSettings.ini"
Foreach($Obj in $BIOSSerialNumbers.Values){
    $CSIniUpdate = Remove-IniEntry -FilePath $IniFile -Sections $Obj
    Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
}

#Cleanup MDT Monitoring data
Write-Log -Message "Cleanup MDT Monitoring data"
if($EnableMDTMonitoring -eq $True){
    foreach($ValTaskSequenceID in $ValTaskSequenceIDs){
        Get-MDTMonitorData -Path MDT: | Where-Object -Property Name -EQ -Value $ValTaskSequenceID | Remove-MDTMonitorData -Path MDT:
    }
}

#Remove Validate Tasksequences
Write-Log -Message "Remove Validate Tasksequences"
foreach($Item in (Get-ChildItem -Path "MDT:\Task Sequences\$($Settings.Settings.MDT.ValidateTaskSequenceFolderName)")){
    Remove-Item -Path "MDT:\Task Sequences\$($Settings.Settings.MDT.ValidateTaskSequenceFolderName)\$($Item.Name)" -Force
}

#Remove Validate WIM's
Write-Log -Message "Remove Validate WIM's"
foreach($Item in (Get-ChildItem -Path "MDT:\Operating Systems\$($Settings.Settings.MDT.ValidateOSImageFolderName)")){
    Remove-Item -Path "MDT:\Operating Systems\$($Settings.Settings.MDT.ValidateOSImageFolderName)\$($Item.Name)" -Force
}

#Cleanup Reference VMs
if($KeepVMs -eq $false){
    Write-Log -Message "Cleanup Reference VMs"
    Invoke-Command -ComputerName $($Settings.Settings.HyperV.Computername) -ScriptBlock {
        $ValVMs = Get-VM | Where-Object -Property Notes -Like -Value "VALIDATE*" 
        Foreach($ValVM in $ValVMs){
            $VM = Get-VM -VMName $ValVM.Name
            Write-Verbose "Deleting $($VM.Name) on $($VM.Computername) at $($VM.ConfigurationLocation)"
            Remove-VM -VM $VM -Force
            Remove-Item -Path $VM.ConfigurationLocation -Recurse -Force
        }
    }
}

#Final update
Write-Log -Message "Done"
Exit "OK"