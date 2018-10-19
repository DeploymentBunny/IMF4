#Configure Imagefactory
D:\IMFv3\Scripts\IMF-Configure.ps1 -DeploymentShare D:\MDTBuildLabdev -StartUpRAM 4 -VLANID 0 -Computername $env:COMPUTERNAME -SwitchName "UplinkSwitchNAT" -VMLocation D:\VMsDEV -ISOLocation D:\ISODEV -ConcurrentRunningVMs 2 -BuildaccountName MDT_BA -BuildaccountPassword Passw0rd

#Install Imagefactory
D:\IMFv3\Scripts\IMF-Install.ps1

#Uninstall Imagefactory
D:\IMFv3\Scripts\IMF-Uninstall.ps1

#Import ISO
D:\IMFv3\Scripts\IMF-ImportISO.ps1 -ISOImage D:\ISO\SW_DVD5_Win_Pro_Ent_Edu_N_10_1709_64BIT_English_MLF_X21-50143.ISO -OSFolder W10x6417091 -OrgName ViaMonstra
#D:\IMFv3\Scripts\Import-ISO.ps1 -ISOImage D:\ISO\SW_DVD5_Win_Pro_Ent_Edu_N_10_1709_64BIT_English_MLF_X21-50143.ISO -OSFolder W10x6417092 -OrgName ViaMonstra

#Update Bootimage
D:\IMFv3\Scripts\IMF-UpdateBootImage.ps1

#Make sure we are clean
D:\IMFv3\Scripts\IMF-VerifyCleanupVMs.ps1

#Start the Image Factory
D:\IMFv3\Scripts\IMF-Build.ps1 -EnableWSUS True

#Start the Image Factory
D:\IMFv3\Scripts\IMF-Build.ps1 -EnableWSUS False

#Verify the build
D:\IMFv3\Scripts\IMF-VerifyBuild.ps1 -KeepVMs False

#Make sure we are clean
D:\IMFv3\Scripts\IMF-VerifyCleanupVMs.ps1

#Generate Report
D:\IMFv3\Scripts\IMF-GenerateReport.ps1

#Generate VHDx
$DateTime = (Get-Date).ToString('yyyyMMdd')
$CaptureFolder = "E:\MDTBuildLab\Captures"
$VHDxFolder = "E:\VHD\$DateTime"
#D:\IMFv3\Scripts\\ImageFactoryV3-ConvertToVHD.ps1 -CaptureFolder $CaptureFolder -VHDxFolder $VHDxFolder -UEFI $True -BIOS $false

#Move to Archive
D:\IMFv3\Scripts\IMF-Archive.ps1

explorer.exe "D:\MDTBuildLabDev\Reports"

#Update Image Class in SCVMM
#Import to SCVMM and build validation Templates

#Update Image Class in SCVMM
#Import to ConfigMgr and build validation TaskSequences

