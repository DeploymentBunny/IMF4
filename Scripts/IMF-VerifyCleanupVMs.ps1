<#
.Synopsis
    ImageFactory 3.3
.DESCRIPTION
    ImageFactory 3.3
.EXAMPLE
    ImageFactoryV3-Verify-CleanupVMs.ps1
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

$CurrentPath = split-path -parent $MyInvocation.MyCommand.Path
$RootPath = split-path -parent $CurrentPath

#Importing modules
Import-Module IMFFunctions -ErrorAction Stop -WarningAction Stop -Force
Write-Log -Message "Module IMFFunctions imported"
Import-Module 'C:\Program Files\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1' -ErrorAction Stop -WarningAction Stop
Write-Log -Message "ModuleMicrosoftDeploymentToolkit imported"

#Inititial Settings
$Log = "$RootPath\log.txt"
$XMLFile = "$RootPath\IMF.xml"
$Solution = "IMF32"
Write-Log -Message "Imagefactory 3.2 (Hyper-V)"
Write-Log -Message "Logfile is $Log"
Write-Log -Message "XMLfile is $XMLfile"

#Read Settings from XML
Write-Log -Message "Reading from $XMLFile"
[xml]$Settings = Get-Content $XMLFile -ErrorAction Stop -WarningAction Stop

#Verify Connection to Hyper-V host
Write-Log -Message "Verify Connection to Hyper-V host"
$Result = Test-VIAHypervConnection -Computername $Settings.Settings.HyperV.Computername -ISOFolder $Settings.Settings.HyperV.ISOLocation -VMFolder $Settings.Settings.HyperV.VMLocation -VMSwitchName $Settings.Settings.HyperV.SwitchName
If($Result -ne $true){Write-Log -Message "$($Settings.Settings.HyperV.Computername) is not ready, will break";break}

#Cleanup Validate VMs
Write-Log -Message "Cleanup Validate VMs"
Invoke-Command -ComputerName $($Settings.Settings.HyperV.Computername) -ScriptBlock {
    $ValVMs = Get-VM | Where-Object -Property Notes -Like -Value "VALIDATE*" 
    Foreach($ValVM in $ValVMs){
        $VM = Get-VM -VMName $ValVM.Name
        Write-Verbose "Stopping $($VM.Name) on $($VM.Computername) at $($VM.ConfigurationLocation)"
        Stop-VM -VM $VM -Force -TurnOff
        Write-Verbose "Deleting $($VM.Name) on $($VM.Computername) at $($VM.ConfigurationLocation)"
        Remove-VM -VM $VM -Force
        Remove-Item -Path $VM.ConfigurationLocation -Recurse -Force
    }
}

#Cleanup Reference VMs
Write-Log -Message "Cleanup Reference VMs"
Invoke-Command -ComputerName $($Settings.Settings.HyperV.Computername) -ScriptBlock {
    $ValVMs = Get-VM | Where-Object -Property Notes -Like -Value "REFIMAGE*" 
    Foreach($ValVM in $ValVMs){
        $VM = Get-VM -VMName $ValVM.Name
        Write-Verbose "Stopping $($VM.Name) on $($VM.Computername) at $($VM.ConfigurationLocation)"
        Stop-VM -VM $VM -Force -TurnOff
        Write-Verbose "Deleting $($VM.Name) on $($VM.Computername) at $($VM.ConfigurationLocation)"
        Remove-VM -VM $VM -Force
        Remove-Item -Path $VM.ConfigurationLocation -Recurse -Force
    }
}


#Cleanup in SCVMM
if($Settings.Settings.SCVMM.InUse -eq $true){

    $SCVMMServerName = $Settings.Settings.SCVMM.SCVMMServerName

    $ScriptBlock = {
        $result = Get-SCVirtualMachine -All | Where-Object Description -EQ REFIMAGE | Where-Object StatusString -EQ Missing | Remove-SCVirtualMachine -Force -RunAsynchronously
        $result | Select Name

        $result = Get-SCVirtualMachine -All | Where-Object Description -EQ Validate | Where-Object StatusString -EQ Missing | Remove-SCVirtualMachine -Force -RunAsynchronously
        $result | Select Name
    }

    Invoke-Command -ComputerName $SCVMMServerName -ScriptBlock $ScriptBlock
}
Return "OK"