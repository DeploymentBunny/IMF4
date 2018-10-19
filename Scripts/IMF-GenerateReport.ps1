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

[cmdletbinding(SupportsShouldProcess=$True)]
Param(
)

#Inititial Settings
$CurrentPath = Split-Path -parent $MyInvocation.MyCommand.Path
$RootPath = Split-Path -parent $CurrentPath
$Global:ScriptLogFilePath = "$RootPath\IMF.log"
$XMLFile = "$RootPath\IMF.xml"
$Global:writetoscreen = $true

#Inititial Settings
Write-Log -Message "Imagefactory 3.2 (Hyper-V)"
Write-Log -Message "Logfile is $ScriptLogFilePath"
Write-Log -Message "XMLfile is $XMLfile"

#Importing modules
Import-Module IMFFunctions -ErrorAction Stop -WarningAction Stop -Force
Write-Log -Message "Module IMFFunctions imported"

#Read Settings from XML
Write-Log -Message "Reading from $XMLFile"
[xml]$Settings = Get-Content $XMLFile -ErrorAction Stop -WarningAction Stop

#Verify Connection to DeploymentRoot
Write-Log -Message "Verify Connection to DeploymentRoot"
$Result = Test-Path -Path $Settings.Settings.MDT.DeploymentShare
If($Result -ne $true){
    Write-Log -Message "Cannot access $($Settings.Settings.MDT.DeploymentShare) , will break" -LogLevel 3
    Return "Cannot access $($Settings.Settings.MDT.DeploymentShare) , will break"
    Exit
}

$reportfolders = Get-ChildItem -Path "$($Settings.Settings.MDT.DeploymentShare)\Reports" -Filter *.
foreach($reportfolder in $reportfolders){
    # Set the basic's
    $htmlreport = @()
    $htmlbody = @()
    $spacer = "<br />"
    

    #OS Info
    Write-Log -Message "Begin generating OS Info"
    Try {
        $subhead = "<h3>Operating System Information</h3>"
        $htmlbody += $subhead

        $Comment = "<p>Data from the Win32_OperatingSystem WMI class<p>"
        $htmlbody += $Comment

        $Win32_OperatingSystem = Import-Csv -Path "$($reportfolder.FullName)\Win32_OperatingSystem.csv" | 
            Select-Object Caption,BuildNumber,CountryCode,OSLanguage,Locale,
                @{Name='CurrentTimeZone';Expression={Convert-TSxMinutesToHours -minutes $($_.CurrentTimeZone)}}, 
                @{Name='InstallDate';Expression={Convert-TSxWMITimeToStandardDate -WMITime $($_.InstallDate)}}
        
        $htmlbody += $Win32_OperatingSystem | ConvertTo-Html -Fragment
        $htmlbody += $spacer
    }
    Catch {
        Write-Log -Message $_.Exception.Message -LogLevel 2
        $htmlbody += "<p>An error was encountered. $($_.Exception.Message)</p>"
        $htmlbody += $spacer
    }
    Write-Log -Message "Done generating OS Info"

    #TaskSequence
    Write-Log -Message "Begin generating TaskSequence Info"
    Try {
        $subhead = "<h3>Task Sequence information</h3>"
        $htmlbody += $subhead

        $Comment = "<p>Data from the Microsoft_BDD_Info WMI Class<p>"
        $htmlbody += $Comment

        $Microsoft_BDD_Info = Import-Csv -Path "$($reportfolder.FullName)\Microsoft_BDD_Info.csv" | 
            Select-Object CaptureTaskSequenceID,CaptureTaskSequenceName,CaptureTaskSequenceVersion,
                @{Name='CaptureTimestamp';Expression={Convert-TSxWMITimeToStandardDate -WMITime $($_.CaptureTimestamp)}},
                @{Name='DeploymentTimestamp';Expression={Convert-TSxWMITimeToStandardDate -WMITime $($_.DeploymentTimestamp)}}
        
        $htmlbody += $Microsoft_BDD_Info | ConvertTo-Html -Fragment
        $htmlbody += $spacer
    }
    Catch {
        Write-Log -Message $_.Exception.Message -LogLevel 2
        $htmlbody += "<p>An error was encountered. $($_.Exception.Message)</p>"
        $htmlbody += $spacer
    }
    Write-Log -Message "Done generating TaskSequence Info"
    
    #Roles and Features
    Write-Log -Message "Begin generating Roles and Features Info"
    Try {
        $subhead = "<h3>Windows Roles and Festures</h3>"
        $htmlbody += $subhead

        $Comment = "<p>Data from the WindowsOptionalFeature cmdlet<p>"
        $htmlbody += $Comment

        $WindowsOptionalFeature = Import-Csv -Path "$($reportfolder.FullName)\WindowsOptionalFeature.csv" | Where-Object State -EQ Enabled | Select-Object FeatureName,State | Sort-Object FeatureName
        
        $htmlbody += $WindowsOptionalFeature | ConvertTo-Html -Fragment
        $htmlbody += $spacer
    }
    Catch {
        Write-Log -Message $_.Exception.Message -LogLevel 2
        $htmlbody += "<p>An error was encountered. $($_.Exception.Message)</p>"
        $htmlbody += $spacer
    }
    Write-Log -Message "Done generating Roles and Features Info"

    #Hotfixes
    Write-Log -Message "Begin generating Hotfixes Info"
    Try {
        $subhead = "<h3>Patches and Hotfix infrmation</h3>"
        $htmlbody += $subhead

        $Comment = "<p>Data from Win32_QuickFixEngineering cmdlet<p>"
        $htmlbody += $Comment

        $Win32_QuickFixEngineering = Import-Csv -Path "$($reportfolder.FullName)\Win32_QuickFixEngineering.csv"

        if((Test-NetConnection -WarningAction SilentlyContinue).PingSucceeded -eq $true){
            $InternetAccess = $True
        }else{
            $InternetAccess = $false
        }

        $KBs = foreach($Item in $Win32_QuickFixEngineering){
            $Hash =  [ordered]@{ 
                HotfixID = $($Item.HotFixID);
                Description = $($Item.Description);
                URL = $($Item.Caption);
                
            } 
            New-Object PSObject -Property $Hash
        }

        $htmlbody += $KBs | ConvertTo-Html -Fragment
        $htmlbody += $spacer
        }
    Catch {
        Write-Log -Message $($_.Exception.Message)
        $htmlbody += "<p>An error was encountered. $($_.Exception.Message)</p>"
        $htmlbody += $spacer
    }
    Write-Log -Message "Done generating Hotfixes Info"

    #Legacy Apps
    Write-Log -Message "Begin generating Legacy Apps Info"
    Try {
        $subhead = "<h3>Installed legacy applications</h3>"
        $htmlbody += $subhead

        $Comment = "<p>Data from UnInstallKey and UninstallKeyWow6432Node<p>"
        $htmlbody += $Comment

        $UnInstallKey = Import-Csv -Path "$($reportfolder.FullName)\UninstallKey.csv" -ErrorAction SilentlyContinue
        $UninstallKeyWow6432Node = Import-Csv -Path "$($reportfolder.FullName)\UninstallKeyWow6432Node.csv" -ErrorAction SilentlyContinue
        if($UnInstallKeys -eq $null){
        }else{
            $UnInstallKeys = $UnInstallKey + $UninstallKeyWow6432Node
            $Apps = foreach($Item in $UnInstallKeys){
                $Hash =  [ordered]@{ 
                    DisplayName = $($Item.DisplayName);
                    Publisher = $($Item.Publisher);
                    DisplayVersion = $($Item.DisplayVersion);
                    UninstallKey = $($Item.PSChildName);
                    Architechture = $(
                        If($Item.PSPath -like "*Wow*"){"x86"}else{"x64"}
                    )
                } 
            
                New-Object PSObject -Property $Hash
            }
        }
        
        $htmlbody += $Apps | Sort-Object DisplayName | ConvertTo-Html -Fragment
        $htmlbody += $spacer
    }
    Catch {
        Write-Log -Message $_.Exception.Message -LogLevel 2
        $htmlbody += "<p>An error was encountered. $($_.Exception.Message)</p>"
        $htmlbody += $spacer
    }
    Write-Log -Message "Done generating Legacy Apps Info"

    #Modern Applications
    Write-Log -Message "Begin generating Modern Applications Info"
    Try {
        $subhead = "<h3>Modern Applications</h3>"
        $htmlbody += $subhead

        $Comment = "<p>Data from the AppxPackage cmdlet<p>"
        $htmlbody += $Comment

        $AppxPackage = Import-Csv -Path "$($reportfolder.FullName)\AppxPackage.csv" | Select-Object Name,Version | Sort-Object Name
        
        $htmlbody += $AppxPackage | ConvertTo-Html -Fragment
        $htmlbody += $spacer
    }
    Catch {
        Write-Log -Message $_.Exception.Message -LogLevel 2
        $htmlbody += "<p>An error was encountered. $($_.Exception.Message)</p>"
        $htmlbody += $spacer
    }
    Write-Log -Message "Done generating Modern Applications Info"

    #------------------------------------------------------------------------------
    # Generate the HTML report and output to file
    Write-Log -Message "Begin generating Report"

    $reportime = Get-Date

    #Common HTML head and styles
    $htmlhead="<html>
			    <style>
			    BODY{font-family: Arial; font-size: 8pt;}
			    H1{font-size: 20px;}
			    H2{font-size: 18px;}
			    H3{font-size: 16px;}
                H4{font-size: 14px;}
			    TABLE{border: 1px solid black; border-collapse: collapse; font-size: 8pt;}
			    TH{border: 1px solid black; background: #dddddd; padding: 5px; color: #000000;}
			    TD{border: 1px solid black; background: #ADD8E6; padding: 5px; color: #000000;}
			    td.pass{background: #7FFF00;}
			    td.warn{background: #FFE600;}
			    td.fail{background: #FF0000; color: #ffffff;}
                td.info{background: #85D4FF;}
			    </style>
			    <body>
			    <h1 align=""center"">Report - $($reportfolder.Name)</h1>
			    <h3 align=""center"">Generated: $reportime</h3>"
    $htmltail = "</body>
		    </html>"

    $htmlreport = $htmlhead + $htmlbody + $htmltail

    $htmlfile = "$ReportPath" + "\Report_ActiveDirectory.html"
    $HTMLReport | Out-File -FilePath "$($reportfolder.FullName).html" -Encoding utf8  -Force
    Write-Log -Message "Done generating Report"

}
Write-Log -Message "Done"