Set-Location -Path E:\IMF4

#Update Bootimage
.\Scripts\IMF-UpdateBootImage.ps1

#Make sure we are clean
.\Scripts\IMF-VerifyCleanupVMs.ps1

#Start the Image Factory
.\Scripts\IMF-Build.ps1 -EnableWSUS True

# Publish
.\Scripts\IMF-Publish.ps1 -VHDUEFI -VHDBIOS

#Move to Archive
.\Scripts\IMF-Archive.ps1