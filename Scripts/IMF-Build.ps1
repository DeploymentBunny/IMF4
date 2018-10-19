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
    $EnableWSUS = $True,

    [parameter(mandatory=$false)] 
    [ValidateSet($True,$False)] 
    $TestMode = $False
)

#Inititial Settings
$CurrentPath = split-path -parent $MyInvocation.MyCommand.Path
$RootPath = split-path -parent $CurrentPath
$Global:ScriptLogFilePath = "$RootPath\IMF.log"
$XMLFile = "$RootPath\IMF.xml"
$Global:writetoscreen = $true

#Importing modules
Import-Module PSINI -ErrorAction Stop -WarningAction Stop -Force
Write-Log -Message "Module IMFFunctions imported"
Import-Module IMFFunctions -ErrorAction Stop -WarningAction Stop -Force
Write-Log -Message "Module IMFFunctions imported"
Import-Module 'C:\Program Files\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1' -ErrorAction Stop -WarningAction Stop
Write-Log -Message "Module MicrosoftDeploymentToolkit imported"

if($TestMode -eq $True){
    Write-Log -Message "Testmode is now $TestMode"
}

#Read Settings from XML
Write-Log -Message "Reading from $XMLFile"
[xml]$Settings = Get-Content $XMLFile -ErrorAction Stop -WarningAction Stop

#Verify Connection to DeploymentRoot
Write-Log -Message "Verify Connection to DeploymentRoot"
$Result = Test-Path -Path $Settings.Settings.MDT.DeploymentShare
If($Result -ne $true){Write-Log -Message "Cannot access $($Settings.Settings.MDT.DeploymentShare) , will break";break}

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

#Get TaskSequences
Write-Log -Message "Get TaskSequences"
$RefTaskSequenceIDs = (Get-ChildItem -Path "MDT:\Task Sequences\$($Settings.Settings.MDT.RefTaskSequenceFolderName)" | where Enable -EQ $true).ID
if($RefTaskSequenceIDs.count -eq 0){
    Write-Log -Message "Sorry, could not find any TaskSequences to work with"
    Return "Fail"
    Exit
}
Write-Log -Message "Found $($RefTaskSequenceIDs.count) TaskSequences to work on"

#Get detailed info
Write-Log -Message "Get detailed info about the task sequences"
$Result = (Get-ChildItem -Path "MDT:\Task Sequences\$($Settings.Settings.MDT.RefTaskSequenceFolderName)" | where Enable -EQ $true)
foreach($obj in ($Result | Select-Object ID,Name,Version)){
    $data = "$($obj.ID) $($obj.Name) $($obj.Version)"
    Write-Log -Message $data
}

#Verify Connection to Hyper-V host
Write-Log -Message "Verify Connection to Hyper-V host"
$Result = Test-VIAHypervConnection -Computername $Settings.Settings.HyperV.Computername -ISOFolder $Settings.Settings.HyperV.ISOLocation -VMFolder $Settings.Settings.HyperV.VMLocation -VMSwitchName $Settings.Settings.HyperV.SwitchName
If($Result -ne $true){Write-Log -Message "$($Settings.Settings.HyperV.Computername) is not ready, will break";break}

#Upload boot image to Hyper-V host
Write-Log -Message "Upload boot image to Hyper-V host"
$DestinationFolder = "\\" + $($Settings.Settings.HyperV.Computername) + "\" + $($Settings.Settings.HyperV.ISOLocation -replace ":","$")
Copy-Item -Path $MDTImage -Destination $DestinationFolder -Force

#Check if we have enough memory to do this
$NoOfVMsToBuild = [int]$($RefTaskSequenceIDs.count)
$ConcurrentRunningVM = [int]($Settings.Settings.ConcurrentRunningVMs)
$MemReqForeachVM = [int]($Settings.Settings.HyperV.StartupRam)
if([int]$ConcurrentRunningVM -le [int]$NoOfVMsToBuild){$NoConcurrentVMs = $ConcurrentRunningVM}else{$NoConcurrentVMs = $NoOfVMsToBuild}
[int]$MemReq= [int]$NoConcurrentVMs * [int]$MemReqForeachVM

$scriptBlock = {[math]::round((Get-Ciminstance Win32_OperatingSystem).FreePhysicalMemory/1mb,2)}
$MemFree =Invoke-Command -ComputerName $($Settings.Settings.HyperV.Computername) -ScriptBlock $ScriptBlock
if($MemFree -le $MemReq){
    Write-Log -Message "Not enough memory to build the VM's, do something"
    Return "Not enough memory to build the VM's"
    Break
}

#Remove old WIM files in the capture folder
Write-Log -Message "Remove old WIM files in the capture folder"
Foreach($Ref in $RefTaskSequenceIDs){
    $FullRefPath = $(("$Root\Captures\$ref") + ".wim")
    if((Test-Path -Path $FullRefPath) -eq $true){
        Write-Log -Message "trying to remove $FullRefPath"
        Remove-Item -Path $FullRefPath -Force -ErrorAction Stop
    }
}

#Cleanup MDT Monitoring data
if($EnableMDTMonitoring -eq $True){
    foreach($RefTaskSequenceID in $RefTaskSequenceIDs){
        Write-Log -Message "Cleanup MDT Monitoring data"
        Get-MDTMonitorData -Path MDT: | Where-Object -Property Name -EQ -Value $RefTaskSequenceID | Remove-MDTMonitorData -Path MDT:
    }
}

#Create the VM's on Host
Write-Log -Message "Create the VM's on Host"
Foreach($Ref in $RefTaskSequenceIDs){
    $VMName = $ref
    $VMMemory = [int]$($Settings.Settings.HyperV.StartUpRAM) * 1GB
    $VMPath = $($Settings.Settings.HyperV.VMLocation)
    $VMBootimage = $($Settings.Settings.HyperV.ISOLocation) + "\" +  $($MDTImage | Split-Path -Leaf)
    $VMVHDSize = [int]$($Settings.Settings.HyperV.VHDSize) * 1GB
    $VMVlanID = $($Settings.Settings.HyperV.VLANID)
    $VMVCPU = $($Settings.Settings.HyperV.NoCPU)
    $VMSwitch = $($Settings.Settings.HyperV.SwitchName)
    Write-Log -Message "Building $VMName at $VMPath connected to $VMSwitch using VLAN $VMVlanID on host $($Settings.Settings.HyperV.Computername)"
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
    if(!((Get-VM | Where-Object -Property Name -EQ -Value $VMName).count -eq 0)){Write-Warning -Message "VM exist";Break}

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
    Set-VM -VMName $VMName -Notes "REFIMAGE"

    } -ArgumentList $VMName,$VMMemory,$VMPath,$VMBootimage,$VMVHDSize,$VMVlanID,$VMVCPU,$VMSwitch
}

#Get BIOS Serialnumber from each VM and update the customsettings.ini file
Write-Log -Message "Get BIOS Serialnumber from each VM and update the customsettings.ini file"
$BIOSSerialNumbers = @{}
Foreach($Ref in $RefTaskSequenceIDs){

    #Get BIOS Serailnumber from the VM
    $BIOSSerialNumber = Invoke-Command -ComputerName $($Settings.Settings.HyperV.Computername) -ScriptBlock {
        Param(
        $VMName
        )
        $VMObject = Get-WmiObject -Namespace root\virtualization\v2 -Class Msvm_ComputerSystem -Filter "ElementName = '$VMName'"
        $VMObject.GetRelated('Msvm_VirtualSystemSettingData').BIOSSerialNumber
    } -ArgumentList $Ref
    
    #Store serialnumber for the cleanup process
    $BIOSSerialNumbers.Add("$Ref","$BIOSSerialNumber")
    
    #Update CustomSettings.ini
    #$Result = (Get-ChildItem -Path "MDT:\Task Sequences\$($Settings.Settings.MDT.RefTaskSequenceFolderName)" | where Enable -EQ $true)
    $TaskSequence = Get-ChildItem -Path "MDT:\Task Sequences\$($Settings.Settings.MDT.RefTaskSequenceFolderName)" | Where-Object ID -EQ $Ref
    $AppGuid = (Get-ChildItem "MDT:\Applications" -Recurse | Where-Object Name -like "Install - Bundle used by $($TaskSequence.name)").guid

    #"Install - Bundle for"
    #"Install - Bundle used by $Name"
    
    $IniFile = "$($Settings.settings.MDT.DeploymentShare)\Control\CustomSettings.ini"
    $CustomSettings = Get-IniContent -FilePath $IniFile -CommentChar ";"

    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$BIOSSerialNumber" -NameValuePairs @{"OSDComputerName"="$Ref"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$BIOSSerialNumber" -NameValuePairs @{"TaskSequenceID"="$Ref"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$BIOSSerialNumber" -NameValuePairs @{"BackupFile"="$Ref.wim"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
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
    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$BIOSSerialNumber" -NameValuePairs @{"ComputerBackupLocation"="NETWORK"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$BIOSSerialNumber" -NameValuePairs @{"BackupShare"="$($MDTSettings.UNCPath)"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$BIOSSerialNumber" -NameValuePairs @{"BackupDir"="Captures"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$BIOSSerialNumber" -NameValuePairs @{"Applications001"="$AppGuid"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$BIOSSerialNumber" -NameValuePairs @{"OSFeatures"="NetFx3"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
    

    if($TestMode -eq $True){
        $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$BIOSSerialNumber" -NameValuePairs @{"DoCapture"="NO"}
        Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
    }
    else{
        $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$BIOSSerialNumber" -NameValuePairs @{"DoCapture"="YES"}
        Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
    }
}

if($EnableWSUS -eq $True){
    Write-Log -Message "Windows Update is set to True, updating TaskSequences"
    $TSFolders = Get-ChildItem "$($Settings.Settings.MDT.DeploymentShare)\Control" -Filter *.
    foreach($TSFolder in $TSFolders){
        $TSXML = [xml](Get-Content -Path "$($TSFolder.FullName)\ts.xml")
        $StateRestore = $TSXML.sequence.group | Where-Object Name -EQ 'State Restore'
        ($StateRestore.step | Where-Object Name -EQ 'Windows Update (Post-Application Installation)').disable = 'false'
        ($StateRestore.step | Where-Object Name -EQ 'Windows Update (Pre-Application Installation)').disable = 'false'
        $TSXML.Save("$($TSFolder.FullName)\ts.xml")
    }
}

if($EnableWSUS -eq $False){
    Write-Log -Message "Windows Update is set to False, updating TaskSequences"
    $TSFolders = Get-ChildItem "$($Settings.Settings.MDT.DeploymentShare)\Control" -Filter *.
    foreach($TSFolder in $TSFolders){
        $TSXML = [xml](Get-Content -Path "$($TSFolder.FullName)\ts.xml")
        $StateRestore = $TSXML.sequence.group | Where-Object Name -EQ 'State Restore'
        ($StateRestore.step | Where-Object Name -EQ 'Windows Update (Post-Application Installation)').disable = 'true'
        ($StateRestore.step | Where-Object Name -EQ 'Windows Update (Pre-Application Installation)').disable = 'true'
        $TSXML.Save("$($TSFolder.FullName)\ts.xml")
    }
}

#Start VM's on Host
Write-Log -Message "Start VM's on Host"
Write-Log -Message "ConcurrentRunningVMs is set to: $($Settings.Settings.ConcurrentRunningVMs)"
Invoke-Command -ComputerName $($Settings.Settings.HyperV.Computername) -ScriptBlock {
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
            PercentComplete = $($property.PercentComplete.’#text’); 
            Warnings = $($property.Warnings.’#text’); 
            Errors = $($property.Errors.’#text’); 
            DeploymentStatus = $( 
            Switch($property.DeploymentStatus.’#text’){ 
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
            StartTime = $($property.StartTime.’#text’) -replace "T"," "; 
            EndTime = $($property.EndTime.’#text’) -replace "T"," "; 
            }
        New-Object PSObject -Property $Hash
        }
    }

    #Get the VMs as Objects
    $RefVMs = Get-VM | Where-Object -Property Notes -Like -Value "REFIMAGE*"
    foreach($RefVM in $RefVMs){
        Write-Verbose "REFVM $($RefVM.Name) is deployed on $($RefVM.ComputerName) at $($refvm.ConfigurationLocation)"
    }

    #Get the VMs as Objects
    $RefVMs = Get-VM | Where-Object -Property Notes -Like -Value "REFIMAGE*"
    foreach($RefVM in $RefVMs){
    $StartedVM = Start-VM -VMName $RefVM.Name
    Write-Verbose "Starting $($StartedVM.name)"
    Do
        {
            $RunningVMs = $((Get-VM | Where-Object -Property Notes -Like -Value "REFIMAGE*" | Where-Object -Property State -EQ -Value Running))
            foreach($RunningVM in $RunningVMs){
                if($EnableMDTMonitoring -eq $false){
                    Write-Output "Currently running VM's : $($RunningVMs.Name) at $(Get-Date)"
                }
                else{
                    Get-MDTOData -MDTMonitorServer $MDTServer | Where-Object -Property Name -EQ -Value $RunningVM.Name | Select-Object Name,PercentComplete,Warnings,Errors,DeploymentStatus,StartTime,Lasttime | FT
                }
            }
            Start-Sleep -Seconds "30"
        }
    While((Get-VM | Where-Object -Property Notes -Like -Value "REFIMAGE*" | Where-Object -Property State -EQ -Value Running).Count -gt ($ConcurrentRunningVMs - 1))
    }
} -ArgumentList $($Settings.Settings.ConcurrentRunningVMs),$env:COMPUTERNAME,$EnableMDTMonitoring

#Wait until they are done
Write-Log -Message "Wait until they are done"
Invoke-Command -ComputerName $($Settings.Settings.HyperV.Computername) -ScriptBlock {
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
            PercentComplete = $($property.PercentComplete.’#text’); 
            Warnings = $($property.Warnings.’#text’); 
            Errors = $($property.Errors.’#text’); 
            DeploymentStatus = $( 
            Switch($property.DeploymentStatus.’#text’){ 
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
            StartTime = $($property.StartTime.’#text’) -replace "T"," "; 
            EndTime = $($property.EndTime.’#text’) -replace "T"," "; 
            }
        New-Object PSObject -Property $Hash
        }
    }
    Do{
        $RunningVMs = $((Get-VM | Where-Object -Property Notes -Like -Value "REFIMAGE*" | Where-Object -Property State -EQ -Value Running))
            foreach($RunningVM in $RunningVMs){
                if($EnableMDTMonitoring -eq $false){
                    Write-Output "Currently running VM's : $($RunningVMs.Name) at $(Get-Date)"
                }
                else{
                    Get-MDTOData -MDTMonitorServer $MDTServer | Where-Object -Property Name -EQ -Value $RunningVM.Name | Select-Object Name,PercentComplete,Warnings,Errors,DeploymentStatus,StartTime,Lasttime | FT
                }
            }
            Start-Sleep -Seconds "30"
    }until((Get-VM | Where-Object -Property Notes -Like -Value "REFIMAGE*" | Where-Object -Property State -EQ -Value Running).count -eq '0')
} -ArgumentList $MDTServer,$EnableMDTMonitoring

#Update CustomSettings.ini
Write-Log -Message "Update CustomSettings.ini"
Foreach($Obj in $BIOSSerialNumbers.Values){
    $CSIniUpdate = Remove-IniEntry -FilePath $IniFile -Sections $Obj
    Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
}

#Cleanup MDT Monitoring data
Write-Log -Message "Cleanup MDT Monitoring data"
if($EnableMDTMonitoring -eq $True){
    foreach($RefTaskSequenceID in $RefTaskSequenceIDs){
        Get-MDTMonitorData -Path MDT: | Where-Object -Property Name -EQ -Value $RefTaskSequenceID | Remove-MDTMonitorData -Path MDT:
    }
}

if($TestMode -ne $True){
    #Cleanup VMs
    Write-Log -Message "Cleanup VMs"
    Invoke-Command -ComputerName $($Settings.Settings.HyperV.Computername) -ScriptBlock {
        $RefVMs = Get-VM | Where-Object -Property Notes -Like -Value "REFIMAGE*" 
        Foreach($RefVM in $RefVMs){
            $VM = Get-VM -VMName $RefVM.Name
            Write-Verbose "Deleting $($VM.Name) on $($VM.Computername) at $($VM.ConfigurationLocation)"
            Remove-VM -VM $VM -Force
            Remove-Item -Path $VM.ConfigurationLocation -Recurse -Force
        }
    }
}

#Final update
Write-Log -Message "Done"
Return "OK"