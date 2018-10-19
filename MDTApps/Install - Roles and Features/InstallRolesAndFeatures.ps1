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

$ImageBuild = $tsenv.Value("IMAGEBUILD")
switch ($ImageBuild.Substring(0,3))
{
    '10.' {
        $tsenv.Value("OSRoleIndex") = "10"
    }
    Default {
        $tsenv.Value("OSRoleIndex") = $ImageBuild.Substring(0,3)
    }
}
Write-Output "$ScriptName - OSRoleIndex is now $($tsenv.Value("OSRoleIndex"))"

#Stop Transcript Logging
. Stop-Logging
