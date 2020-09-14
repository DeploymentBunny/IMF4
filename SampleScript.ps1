#Configure Imagefactory
.\Scripts\IMF-Configure.ps1 -DeploymentShare E:\MDTBuildLab -StartUpRAM 4 -VLANID 0 -Computername HYPERVHOST01 -SwitchName "SwitchName" -VMLocation E:\VMs -ISOLocation E:\ISO -ConcurrentRunningVMs 2 -BuildaccountName MDT_BA -BuildaccountPassword Passw0rd!#

#Install Imagefactory
.\Scripts\IMF-Install.ps1

#Uninstall Imagefactory
.\Scripts\IMF-Uninstall.ps1

#Import ISO
.\Scripts\IMF-ImportISO.ps1 -ISOImage D:\ISO\SW_DVD5_Win_Pro_Ent_Edu_N_10_1709_64BIT_English_MLF_X21-50143.ISO -OSFolder W10x6417091 -OrgName ViaMonstra
#.\Scripts\Import-ISO.ps1 -ISOImage D:\ISO\SW_DVD5_Win_Pro_Ent_Edu_N_10_1709_64BIT_English_MLF_X21-50143.ISO -OSFolder W10x6417092 -OrgName ViaMonstra

#Update Bootimage
.\Scripts\IMF-UpdateBootImage.ps1

#Make sure we are clean
.\Scripts\IMF-VerifyCleanupVMs.ps1

#Start the Image Factory
.\Scripts\IMF-Build.ps1 -EnableWSUS True

#Start the Image Factory
.\Scripts\IMF-Build.ps1 -EnableWSUS False

#Verify the build
.\Scripts\IMF-VerifyBuild.ps1 -KeepVMs False

#Make sure we are clean
.\Scripts\IMF-VerifyCleanupVMs.ps1

#Generate Report
.\Scripts\IMF-GenerateReport.ps1

#Generate VHDx
$DateTime = (Get-Date).ToString('yyyyMMdd')
$CaptureFolder = "E:\MDTBuildLab\Captures"
$VHDxFolder = "E:\VHD\$DateTime"
#.\Scripts\\ImageFactoryV3-ConvertToVHD.ps1 -CaptureFolder $CaptureFolder -VHDxFolder $VHDxFolder -UEFI $True -BIOS $false

# Publish
.\Scripts\IMF-Publish.ps1 -VHDUEFI -VHDBIOS

#Move to Archive
.\Scripts\IMF-Archive.ps1