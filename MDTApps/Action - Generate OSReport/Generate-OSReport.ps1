<#
.Synopsis
    ImageFactory 3.3
.DESCRIPTION
    ImageFactory 3.3
.EXAMPLE
    ImageFactoryV3-Verify-ShowContent.ps1
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

Function Import-SMSTSENV{
    try
    {
        $tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
        Write-Output "$ScriptName - tsenv is $tsenv "
        $MDTIntegration = "YES"
         
        #$tsenv.GetVariables() | % { Write-Output "$ScriptName - $_ = $($tsenv.Value($_))" }
    }
    catch
    {
        Write-Output "$ScriptName - Unable to load Microsoft.SMS.TSEnvironment"
        Write-Output "$ScriptName - Running in standalonemode"
        $MDTIntegration = "NO"
    }
    Finally
    {
    if ($MDTIntegration -eq "YES"){
        $Logpath = $tsenv.Value("LogPath")
        $LogFile = $Logpath + "\" + "$ScriptName.log"
 
    }
    Else{
        $Logpath = $env:TEMP
        $LogFile = $Logpath + "\" + "$ScriptName.log"
    }
    }
}
Function Start-Logging{
    start-transcript -path $LogFile -Force
}
Function Stop-Logging{
    Stop-Transcript
}
Function Invoke-Exe{
    [CmdletBinding(SupportsShouldProcess=$true)]
  
    param(
        [parameter(mandatory=$true,position=0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Executable,
  
        [parameter(mandatory=$false,position=1)]
        [string]
        $Arguments
    )
  
    if($Arguments -eq "")
    {
        Write-Verbose "Running $ReturnFromEXE = Start-Process -FilePath $Executable -ArgumentList $Arguments -NoNewWindow -Wait -Passthru"
        $ReturnFromEXE = Start-Process -FilePath $Executable -NoNewWindow -Wait -Passthru
    }else{
        Write-Verbose "Running $ReturnFromEXE = Start-Process -FilePath $Executable -ArgumentList $Arguments -NoNewWindow -Wait -Passthru"
        $ReturnFromEXE = Start-Process -FilePath $Executable -ArgumentList $Arguments -NoNewWindow -Wait -Passthru
    }
    Write-Verbose "Returncode is $($ReturnFromEXE.ExitCode)"
    Return $ReturnFromEXE.ExitCode
}
 
# Set vars
$SCRIPTDIR = split-path -parent $MyInvocation.MyCommand.Path
$SCRIPTNAME = split-path -leaf $MyInvocation.MyCommand.Path
$SOURCEROOT = "$SCRIPTDIR\Source"
$SettingsFile = $SCRIPTDIR + "\" + $SettingsName
$LANG = (Get-Culture).Name
$OSV = $Null
$ARCHITECTURE = $env:PROCESSOR_ARCHITECTURE
 
#Try to Import SMSTSEnv
. Import-SMSTSENV
 
# Set more vars
$Make = $tsenv.Value("Make")
$Model = $tsenv.Value("Model")
$ModelAlias = $tsenv.Value("ModelAlias")
$MakeAlias = $tsenv.Value("MakeAlias")
$OSDComputername = $tsenv.Value("OSDComputername")
 
#Start Transcript Logging
. Start-Logging
 
#Output base info
Write-Output ""
Write-Output "$ScriptName - ScriptDir: $ScriptDir"
Write-Output "$ScriptName - SourceRoot: $SOURCEROOT"
Write-Output "$ScriptName - ScriptName: $ScriptName"
Write-Output "$ScriptName - Current Culture: $LANG"
Write-Output "$ScriptName - Integration with MDT(LTI/ZTI): $MDTIntegration"
Write-Output "$ScriptName - Log: $LogFile"
Write-Output "$ScriptName - Model (win32_computersystem): $((Get-WmiObject Win32_ComputerSystem).model)"
Write-Output "$ScriptName - Name (Win32_ComputerSystemProduct): $((Get-WmiObject Win32_ComputerSystemProduct).Name)"
Write-Output "$ScriptName - Version (Win32_ComputerSystemProduct): $((Get-WmiObject Win32_ComputerSystemProduct).Version)"
Write-Output "$ScriptName - Model (from TSENV): $Model"
Write-Output "$ScriptName - ModelAlias (from TSENV): $ModelAlias"
Write-Output "$ScriptName - OSDComputername (from TSENV): $OSDComputername"
Write-Output "$ScriptName - ModelAlias (from TSENV): $ModelAlias"
Write-Output "$ScriptName - OSDComputername (from TSENV): $OSDComputername"

$CaptureTaskSequenceID = (Get-WMIObject –Class Microsoft_BDD_Info).CaptureTaskSequenceID
$ReportRootFolderName = $tsenv.Value("ReportFolder")
Write-Output "$ScriptName - ReportFolder (from TSENV): $ReportRootFolderName"
Write-Output "$ScriptName - CaptureTaskSequenceID (from WMI): $CaptureTaskSequenceID"

$ReportFolder = New-Item -Path $($ReportRootFolderName + "\" + $CaptureTaskSequenceID) -ItemType Directory -Force
Write-Output "$ScriptName - $($ReportFolder.FullName)"

Get-WMIObject –Class Microsoft_BDD_Info | ConvertTo-Csv -NoTypeInformation | Out-File -FilePath "$($ReportFolder.FullName)\Microsoft_BDD_Info.csv" -Force
Get-WmiObject -Class Win32_OperatingSystem | ConvertTo-Csv -NoTypeInformation | Out-File -FilePath "$($ReportFolder.FullName)\Win32_OperatingSystem.csv" -Force
Get-WmiObject -class Win32_QuickFixEngineering | ConvertTo-Csv -NoTypeInformation | Out-File -FilePath "$($ReportFolder.FullName)\Win32_QuickFixEngineering.csv" -Force
Get-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |  Where-Object DisplayName -ne $null | ConvertTo-Csv -NoTypeInformation | Out-File -FilePath "$($ReportFolder.FullName)\UninstallKey.csv" -Force
Get-ItemProperty -Path HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object DisplayName -ne $null | ConvertTo-Csv -NoTypeInformation | Out-File -FilePath "$($ReportFolder.FullName)\UninstallKeyWow6432Node.csv" -Force

Get-AppxPackage | Select-Object Name,Version | ConvertTo-Csv -NoTypeInformation | Out-File -FilePath "$($ReportFolder.FullName)\AppxPackage.csv" -Force
Get-WindowsOptionalFeature -Online -LogPath "C:\dismlog.log" | Where-Object State -EQ Enabled | ConvertTo-Csv -NoTypeInformation | Out-File -FilePath "$($ReportFolder.FullName)\WindowsOptionalFeature.csv" -Force
