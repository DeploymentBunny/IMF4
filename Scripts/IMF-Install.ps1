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

#Requires -RunAsAdministrator

#Inititial Settings
$CurrentPath = split-path -parent $MyInvocation.MyCommand.Path
$RootPath = split-path -parent $CurrentPath
#$RootPath = "D:\IMFv3"
$Global:ScriptLogFilePath = "$RootPath\IMF.log"
$XMLFile = "$RootPath\IMF.xml"
$Global:writetoscreen = $true

#Install IMFFuctions
Import-Module IMFFunctions -ErrorAction Stop -WarningAction Stop -Force
Write-Log -Message "Module IMFFunctions imported"

#Install PSINI
Import-Module PsIni -ErrorAction Stop -WarningAction Stop -RequiredVersion 2.0.5
Write-Log -Message "Module PsIni imported"

#Importing ModuleMicrosoftDeploymentToolkit
Import-Module 'C:\Program Files\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1' -ErrorAction Stop -WarningAction Stop
Write-Log -Message "Module Microsoft Deployment Toolkit imported"

#Inititial Settings
Write-Log -Message "Imagefactory 3.2 (Hyper-V)"
Write-Log -Message "Logfile is $ScriptLogFilePath"
Write-Log -Message "XMLfile is $XMLfile"

#Read Settings from XML
Write-Log -Message "Reading from $XMLFile"
[xml]$Settings = Get-Content $XMLFile -ErrorAction Stop -WarningAction Stop

#Check for deployshare
if((Test-Path -Path $Settings.Settings.MDT.DeploymentShare) -eq $True){
    Write-Log -Message "$($Settings.Settings.MDT.DeploymentShare) already exists, will abort" -LogLevel 2
    Return "Fail"
    Break
}

#Test
Write-Log -Message "Verifying access to objects"
if((Test-VIAHypervConnection -Computername $Settings.Settings.HyperV.Computername -ISOFolder $Settings.Settings.HyperV.ISOLocation -VMFolder $Settings.Settings.HyperV.VMLocation -VMSwitchName $Settings.Settings.HyperV.SwitchName) -ne $true){
    Write-Log -Message "could not access hyper-v host, hyper-v iso folder, hyper-v vm folder or hyper-v switch" -LogLevel 3
    Return "Fail"
    Break
}

$path = ($settings.Settings.MDT.DeploymentShare | Split-Path)
if((Test-Path $path) -ne $true){
    Write-Log -Message "could not access rootfolder for deploymentshare, make sure you have access to $path" -LogLevel 2
    Return "Fail"
    Break
}

$DeploymentShare = $($Settings.Settings.MDT.DeploymentShare)
$DeploymentShareName = $($DeploymentShare | Split-Path -Leaf) + "$"

$Return = New-Item -Path $DeploymentShare -ItemType Directory
Write-Log "Folder $($Return.FullName) was created"

$Return = New-SmbShare -Name $DeploymentShareName -Path $DeploymentShare -FullAccess Everyone
Write-Log "$($Return.Path) was shared as $($Return.Name)"

$Return = New-PSDrive -Name MDT -PSProvider "MDTProvider" -Root $DeploymentShare -Description "MDT Build LAB" -NetworkPath "\\$env:COMPUTERNAME\$DeploymentShareName" | Add-MDTPersistentDrive
Write-Log "Successfully created a $($Return.Provider.Name) named $($Return.Name) in $($Return.Root)"

$Return = New-Item -Path "MDT:\Operating Systems" -enable "True" -Name "Msft" -ItemType "folder"
Write-Log "Created folder $($Return.name) in $($Return.NodeType)"

$Return = New-Item -Path "MDT:\Operating Systems" -enable "True" -Name $($Settings.Settings.MDT.ValidateOSImageFolderName) -ItemType "folder"
Write-Log "Created folder $($Return.name) in $($Return.NodeType)"

$Return = New-Item -Path "MDT:\Operating Systems" -enable "True" -Name "Retired" -ItemType "folder"
Write-Log "Created folder $($Return.name) in $($Return.NodeType)"

$Return = New-Item -Path "MDT:\Applications" -enable "True" -Name "Active" -ItemType "folder"
Write-Log "Created folder $($Return.name) in $($Return.NodeType)"

$Return = New-Item -Path "MDT:\Applications" -enable "True" -Name "Bundles" -ItemType "folder"
Write-Log "Created folder $($Return.name) in $($Return.NodeType)"

$Return = New-Item -Path "MDT:\Task Sequences" -enable "True" -Name $($Settings.Settings.MDT.RefTaskSequenceFolderName) -ItemType "folder"
Write-Log "Created folder $($Return.name) in $($Return.NodeType)"

$Return = New-Item -Path "MDT:\Task Sequences" -enable "True" -Name $($Settings.Settings.MDT.ValidateTaskSequenceFolderName) -ItemType "folder"
Write-Log "Created folder $($Return.name) in $($Return.NodeType)"

$Return = New-Item -Path "MDT:\Task Sequences" -enable "True" -Name "Retired" -ItemType "folder"
Write-Log "Created folder $($Return.name) in $($Return.NodeType)"

#Configure customsettings.ini
$IniFile = "$($Settings.settings.MDT.DeploymentShare)\Control\CustomSettings.ini"
Write-Log "Infile is $IniFile" 

Write-Log "Reading $IniFile" 
$CustomSettings = Get-IniContent -FilePath $IniFile -CommentChar ";"

Write-Log "Update customsettings.ini"
Write-Log "Adding SerialNumber,Default to Priority"
$CustomSettings.Settings.Priority = 'SerialNumber,Default'

Write-Log "Adding WSUS,ReportFolder,Suspendas custom properties"
$CustomSettings.Settings.Properties = 'WSUS,ReportFolder,Suspend'

Write-Log "updating $IniFile"
Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CustomSettings

$CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "Default" -NameValuePairs @{"_SMSTSORGNAME"="%TaskSequenceName%"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
$CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "Default" -NameValuePairs @{"UserDataLocation"="NONE"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
$CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "Default" -NameValuePairs @{"OSInstall"="Y"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
$CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "Default" -NameValuePairs @{"AdminPassword"="P@ssw0rd"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
$CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "Default" -NameValuePairs @{"TimeZoneName"="Pacific Standard Time"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
$CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "Default" -NameValuePairs @{"JoinWorkgroup"="WORKGROUP"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
$CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "Default" -NameValuePairs @{"ApplyGPOPack"="NO"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
$CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "Default" -NameValuePairs @{"SLShare"="%DeployRoot%\Logs"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
$CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "Default" -NameValuePairs @{"ReportFolder"="%DeployRoot%\Reports"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
$CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "Default" -NameValuePairs @{"HideShell"="YES"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate

Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
Write-Log "$IniFile is updated"

If((Get-LocalUser | Where-Object Name -EQ $Settings.settings.Security.BuildAccount.Name).count -eq "1"){
    Write-Log -Message "MDTBA Account already exists" -LogLevel 2
}else{
    New-LocalUser -AccountNeverExpires -Description $Settings.settings.Security.BuildAccount.Name -Name $Settings.settings.Security.BuildAccount.Name -UserMayNotChangePassword -PasswordNeverExpires -Password ($Settings.settings.Security.BuildAccount.Password | ConvertTo-SecureString -AsPlainText -Force)
}

Write-Log -Message "Creating folders"
$FolderNames = "Logs","Reports"
foreach($Item in $FolderNames){

    $FolderName = "$($Settings.settings.MDT.DeploymentShare)\$Item"
    $return = New-Item -Path $FolderName -ItemType Directory -Force
    Write-Log -Message "$($return.FullName) was created"

    Write-Log -Message "Setting permissions on $($return.FullName)"
    $Acl = Get-Acl $FolderName
    $Ar = New-Object  system.security.accesscontrol.filesystemaccessrule("$($Settings.settings.Security.BuildAccount.Name)","Modify","Allow")
    $Acl.SetAccessRule($Ar)
    Set-Acl $FolderName $Acl

    $Acl = Get-Acl $FolderName
    $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("$($Settings.settings.Security.BuildAccount.Name)","Modify", "ContainerInherit, ObjectInherit", "InheritOnly", "Allow")))
    Set-Acl $FolderName $Acl
}

#Configure bootstrap.ini
$IniFile = "$($Settings.settings.MDT.DeploymentShare)\Control\Bootstrap.ini"
$Bootstrap = Get-IniContent -FilePath $IniFile -CommentChar ";"
Write-Log -Message "Modifying $IniFile"

$CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "Default" -NameValuePairs @{"UserDomain"="$env:COMPUTERNAME"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
$CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "Default" -NameValuePairs @{"UserID"="$($Settings.settings.Security.BuildAccount.Name)"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
$CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "Default" -NameValuePairs @{"UserPassword"="$($Settings.settings.Security.BuildAccount.Password)"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
$CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "Default" -NameValuePairs @{"SkipBDDWelcome"="YES"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate

if((Get-IniContent -FilePath $IniFile)["Default"]["DeployRoot"] -ne "\\$env:COMPUTERNAME\$DeploymentShareName"){
    Write-Log -Message "Adding deployroot path, since it was missing..."
    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "Default" -NameValuePairs @{"Deployroot"="\\$env:COMPUTERNAME\$DeploymentShareName"};Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
}

Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
Write-Log -Message "Saved $IniFile"

$AppName = "Configure - Enable Remote Desktop (Windows Server)"
$Return = Import-MDTApplication -Path "MDT:\Applications\Active" -enable "True" -Name $Appname -ShortName $Appname -Version "" -Publisher "" -Language "" -CommandLine 'cscript.exe c:\windows\system32\scregedit.wsf /AR 0' -WorkingDirectory "" -NoSource
Write-Log -Message "Added $($Return.Name)"

$AppName = "Configure - Enable Previous Client Connection to Remote Desktop (Windows Server)"
$Return = Import-MDTApplication -Path "MDT:\Applications\Active" -enable "True" -Name $Appname -ShortName $Appname -Version "" -Publisher "" -Language "" -CommandLine 'cscript.exe c:\windows\system32\scregedit.wsf /CS 0' -WorkingDirectory "" -NoSource
Write-Log -Message "Added $($Return.Name)"

$AppName = "Configure - Enable Firewall for Remote Desktop (Windows Server)"
$Return = Import-MDTApplication -Path "MDT:\Applications\Active" -enable "True" -Name $Appname -ShortName $appname -Version "" -Publisher "" -Language "" -CommandLine 'PowerShell.exe -Command """Get-NetFirewallRule -Group "@FirewallAPI.dll,-28752" | Enable-NetFirewallRule"""' -WorkingDirectory "" -NoSource
Write-Log -Message "Added $($Return.Name)"

$AppName = "Install - Microsoft Visual C++"
$Return = Import-MDTApplication -Path "MDT:\Applications\Active" -enable "True" -Name $Appname -ShortName $appname -Version "" -Publisher "" -Language "" -CommandLine "cscript.exe Install-MicrosoftVisualC++x86x64.wsf" -WorkingDirectory ".\Applications\Install - Microsoft Visual C++" -ApplicationSourcePath "$RootPath\MDTApps\Install - Microsoft Visual C++" -DestinationFolder "Install - Microsoft Visual C++"
Write-Log -Message "Added $($Return.Name)"

$AppName = "Configure - Disable Services in Windows Server 2016 Desktop Edition"
$Return = Import-MDTApplication -Path "MDT:\Applications\Active" -enable "True" -Name $Appname -ShortName $Appname -Version "" -Publisher "" -Language "" -CommandLine "PowerShell.exe -ExecutionPolicy Bypass -File Configure-DisableServicesforWindowsServer.ps1" -WorkingDirectory ".\Applications\Configure - Disable Services in Windows Server 2016 Desktop Edition" -ApplicationSourcePath "$RootPath\MDTApps\Configure - Disable Services in Windows Server 2016 Desktop Edition" -DestinationFolder "Configure - Disable Services in Windows Server 2016 Desktop Edition"
Write-Log -Message "Added $($Return.Name)"

$AppName = $($Settings.Settings.MDT.ReportApplicationName)
$Return = Import-MDTApplication -Path "MDT:\Applications\Active" -enable "True" -Name $AppName -ShortName $AppName -CommandLine "PowerShell.exe -ExecutionPolicy Bypass -File Generate-OSReport.ps1" -WorkingDirectory ".\Applications\$($Settings.Settings.MDT.ReportApplicationName)" -ApplicationSourcePath "$RootPath\MDTApps\Action - Generate OSReport" -DestinationFolder $($Settings.Settings.MDT.ReportApplicationName)
Write-Log -Message "Added $($Return.Name)"

$AppName = "Install - Microsoft BGInfo - x86-x64"
$Return = Import-MDTApplication -Path "MDT:\Applications\Active" -enable "True" -Name $AppName -ShortName $AppName -CommandLine "cscript.exe Install-MicrosoftBGInfox86x64.wsf" -WorkingDirectory ".\Applications\Install - Microsoft BGInfo - x86-x64" -ApplicationSourcePath "$RootPath\MDTApps\Install - Microsoft BGInfo - x86-x64" -DestinationFolder "Install - Microsoft BGInfo - x86-x64"
Write-Log -Message "Added $($Return.Name)"

$AppName = "Install - Roles and Features"
$Return = Import-MDTApplication -Path "MDT:\Applications\Active" -enable "True" -Name $AppName -ShortName $AppName -Version "" -Publisher "" -Language "" -CommandLine "PowerShell.exe -ExecutionPolicy ByPass -File InstallRolesAndFeatures.ps1" -WorkingDirectory ".\Applications\Install - Roles and Features" -ApplicationSourcePath "$RootPath\MDTApps\Install - Roles and Features" -DestinationFolder "Install - Roles and Features"
Write-Log -Message "Added $($Return.Name)"

Return "OK"