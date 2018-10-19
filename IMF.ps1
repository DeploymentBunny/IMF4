$DLL = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
Add-Type -MemberDefinition $DLL -name NativeMethods -namespace Win32
$Process = (Get-Process PowerShell | Where-Object MainWindowTitle -like '*Image Factory*').MainWindowHandle
# Minimize window
[Win32.NativeMethods]::ShowWindowAsync($Process, 2)

#Pick up the logs
$Global:writetolistbox = $true

#region Constructor

[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

#endregion

#Set Font
$Font = "Consolas"

#Set base values
#Inititial Settings
$CurrentPath = Split-Path -parent $MyInvocation.MyCommand.Path
$RootPath = Split-Path -parent $CurrentPath
$Global:ScriptLogFilePath = "$RootPath\IMF.log"
$XMLFile = "$CurrentPath\IMF.xml"
$Global:writetoscreen = $true

#ReadData from XML
[xml]$XMLdata = Get-Content -Path $XMLFile

#region Form Creation
#~~< Form1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Form1 = New-Object System.Windows.Forms.Form
$Form1.ClientSize = New-Object System.Drawing.Size(1300, 600)
$Form1.Text = "IMF 4.0"
$Form1.Icon = "$CurrentPath\deploymentbunny-w175.ico"
#~~< Button1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Button1 = New-Object System.Windows.Forms.Button
$Button1.Location = New-Object System.Drawing.Point(1150, 550)
$Button1.Size = New-Object System.Drawing.Size(100, 23)
$Button1.TabIndex = 1
$Button1.Text = "Close"
$Button1.UseVisualStyleBackColor = $true
$Button1.add_Click({Button1Click($Button1)})
#~~< result1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

$Global:Result1 = New-Object System.Windows.Forms.ListBox
$Global:Result1.Size = New-Object System.Drawing.Size(1260, 150)
$Global:Result1.Location = New-Object System.Drawing.Point(20, 380)
$Global:Result1.Font = New-Object System.Drawing.Font($font, 10)
$Global:Result1.Items.Add("IMF 4.0 is ready.")

#~~< PictureBox1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$PictureBox1 = New-Object system.Windows.Forms.PictureBox
$PictureBox1.width = 90
$PictureBox1.height  = 90
$PictureBox1.location  = New-Object System.Drawing.Point(20,515)
$PictureBox1.imageLocation  = "$CurrentPath\image.png"
$PictureBox1.SizeMode  = [System.Windows.Forms.PictureBoxSizeMode]::zoom

#~~< TabControl1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TabControl1 = New-Object System.Windows.Forms.TabControl
$TabControl1.Font = New-Object System.Drawing.Font($font, 12)
$TabControl1.Location = New-Object System.Drawing.Point(20, 20)
$TabControl1.Size = New-Object System.Drawing.Size(1260, 350)
$TabControl1.TabIndex = 0
$TabControl1.Text = ""

#region begin GUI{ 
#~~< TabPage1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TabPage1 = New-Object System.Windows.Forms.TabPage
$TabPage1.Font = New-Object System.Drawing.Font($font, 10)
$TabPage1.Location = New-Object System.Drawing.Point(4, 22)
$TabPage1.Padding = New-Object System.Windows.Forms.Padding(3)
$TabPage1.Size = New-Object System.Drawing.Size(100, 400)
$TabPage1.TabIndex = 0
$TabPage1.Text = "Main"
$TabPage1.UseVisualStyleBackColor = $true
#~~< Label1Tab1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Label1Tab1 = New-Object System.Windows.Forms.Label
$Label1Tab1.Location = New-Object System.Drawing.Point(20, 30)
$Label1Tab1.Size = New-Object System.Drawing.Size(500, 23)
$Label1Tab1.Text = "Update and distribute the bootimage"
#~~< Label2Tab1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Label2Tab1 = New-Object System.Windows.Forms.Label
$Label2Tab1.Location = New-Object System.Drawing.Point(20, 60)
$Label2Tab1.Size = New-Object System.Drawing.Size(500, 23)
$Label2Tab1.Text = "Remove Reference/Validation VMs"
#~~< Label3Tab1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Label3Tab1 = New-Object System.Windows.Forms.Label
$Label3Tab1.Location = New-Object System.Drawing.Point(20, 90)
$Label3Tab1.Size = New-Object System.Drawing.Size(500, 23)
$Label3Tab1.Text = "Create reference image(s) WU Enable"
#~~< Label4Tab1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Label4Tab1 = New-Object System.Windows.Forms.Label
$Label4Tab1.Location = New-Object System.Drawing.Point(20, 120)
$Label4Tab1.Size = New-Object System.Drawing.Size(500, 23)
$Label4Tab1.Text = "Create reference image(s) WU Disabled"
#~~< Label4Tab1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Label5Tab1 = New-Object System.Windows.Forms.Label
$Label5Tab1.Location = New-Object System.Drawing.Point(20, 150)
$Label5Tab1.Size = New-Object System.Drawing.Size(500, 23)
$Label5Tab1.Text = "Validate reference image(s)"
#~~< Label5Tab1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Label6Tab1 = New-Object System.Windows.Forms.Label
$Label6Tab1.Location = New-Object System.Drawing.Point(20, 180)
$Label6Tab1.Size = New-Object System.Drawing.Size(500, 23)
$Label6Tab1.Text = "Generate OS reports"
#~~< Label7Tab1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Label7Tab1 = New-Object System.Windows.Forms.Label
$Label7Tab1.Location = New-Object System.Drawing.Point(20, 210)
$Label7Tab1.Size = New-Object System.Drawing.Size(500, 23)
$Label7Tab1.Text = "Archive WIM files"
#~~< Button1Tab1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Button1Tab1 = New-Object System.Windows.Forms.Button
$Button1Tab1.Location = New-Object System.Drawing.Point(410, 30)
$Button1Tab1.Size = New-Object System.Drawing.Size(100, 23)
$Button1Tab1.TabIndex = 1
$Button1Tab1.Text = "Run"
$Button1Tab1.UseVisualStyleBackColor = $true
$Button1Tab1.add_Click({Button1Tab1Click($Button1Tab1)})
#~~< Button2Tab1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Button2Tab1 = New-Object System.Windows.Forms.Button
$Button2Tab1.Location = New-Object System.Drawing.Point(410, 60)
$Button2Tab1.Size = New-Object System.Drawing.Size(100, 23)
$Button2Tab1.TabIndex = 2
$Button2Tab1.Text = "Run"
$Button2Tab1.UseVisualStyleBackColor = $true
$Button2Tab1.add_Click({Button2Tab1Click($Button2Tab1)})
#~~< Button3Tab1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Button3Tab1 = New-Object System.Windows.Forms.Button
$Button3Tab1.Location = New-Object System.Drawing.Point(410, 90)
$Button3Tab1.Size = New-Object System.Drawing.Size(100, 23)
$Button3Tab1.TabIndex = 3
$Button3Tab1.Text = "Run"
$Button3Tab1.UseVisualStyleBackColor = $true
$Button3Tab1.add_Click({Button3Tab1Click($Button3Tab1)})
#~~< Button4Tab1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Button4Tab1 = New-Object System.Windows.Forms.Button
$Button4Tab1.Location = New-Object System.Drawing.Point(410, 120)
$Button4Tab1.Size = New-Object System.Drawing.Size(100, 23)
$Button4Tab1.TabIndex = 3
$Button4Tab1.Text = "Run"
$Button4Tab1.UseVisualStyleBackColor = $true
$Button4Tab1.add_Click({Button4Tab1Click($Button4Tab1)})
#~~< Button5Tab1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Button5Tab1 = New-Object System.Windows.Forms.Button
$Button5Tab1.Location = New-Object System.Drawing.Point(410, 150)
$Button5Tab1.Size = New-Object System.Drawing.Size(100, 23)
$Button5Tab1.TabIndex = 4
$Button5Tab1.Text = "Run"
$Button5Tab1.UseVisualStyleBackColor = $true
$Button5Tab1.add_Click({Button5Tab1Click($Button5Tab1)})
#~~< Button6Tab1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Button6Tab1 = New-Object System.Windows.Forms.Button
$Button6Tab1.Location = New-Object System.Drawing.Point(410, 180)
$Button6Tab1.Size = New-Object System.Drawing.Size(100, 23)
$Button6Tab1.TabIndex = 4
$Button6Tab1.Text = "Run"
$Button6Tab1.UseVisualStyleBackColor = $true
$Button6Tab1.add_Click({Button6Tab1Click($Button6Tab1)})
#~~< Button7Tab1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Button7Tab1 = New-Object System.Windows.Forms.Button
$Button7Tab1.Location = New-Object System.Drawing.Point(410, 210)
$Button7Tab1.Size = New-Object System.Drawing.Size(100, 23)
$Button7Tab1.TabIndex = 4
$Button7Tab1.Text = "Run"
$Button7Tab1.UseVisualStyleBackColor = $true
$Button7Tab1.add_Click({Button7Tab1Click($Button7Tab1)})


$TabPage1.Controls.Add($Button1Tab1)
$TabPage1.Controls.Add($Button2Tab1)
$TabPage1.Controls.Add($Button3Tab1)
$TabPage1.Controls.Add($Button4Tab1)
$TabPage1.Controls.Add($Button5Tab1)
$TabPage1.Controls.Add($Button6Tab1)
$TabPage1.Controls.Add($Button7Tab1)
$TabPage1.Controls.Add($Label1Tab1)
$TabPage1.Controls.Add($Label2Tab1)
$TabPage1.Controls.Add($Label3Tab1)
$TabPage1.Controls.Add($Label4Tab1)
$TabPage1.Controls.Add($Label5Tab1)
$TabPage1.Controls.Add($Label6Tab1)
$TabPage1.Controls.Add($Label7Tab1)
$TabPage1.add_Click({TabPage1Click($TabPage1)})

#endregion GUI }

#region begin GUI{ 
#~~< TabPage2 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TabPage2 = New-Object System.Windows.Forms.TabPage
$TabPage2.Font = New-Object System.Drawing.Font($font, 10)
$TabPage2.Location = New-Object System.Drawing.Point(4, 22)
$TabPage2.Padding = New-Object System.Windows.Forms.Padding(3)
$TabPage2.Size = New-Object System.Drawing.Size(100, 400)
$TabPage2.TabIndex = 1
$TabPage2.Text = "Import OS"
$TabPage2.UseVisualStyleBackColor = $true
#~~< Label1Tab2 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Label1Tab2 = New-Object System.Windows.Forms.Label
$Label1Tab2.Location = New-Object System.Drawing.Point(20, 30)
$Label1Tab2.Size = New-Object System.Drawing.Size(180, 23)
$Label1Tab2.Text = "ISO Image"
#~~< Label2Tab2 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Label2Tab2 = New-Object System.Windows.Forms.Label
$Label2Tab2.Location = New-Object System.Drawing.Point(20, 60)
$Label2Tab2.Size = New-Object System.Drawing.Size(180, 23)
$Label2Tab2.Text = "MDT Folder name"
#~~< TextBox1Tab2 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TextBox1Tab2 = New-Object System.Windows.Forms.TextBox
$TextBox1Tab2.Location = New-Object System.Drawing.Point(200, 30)
$TextBox1Tab2.Size = New-Object System.Drawing.Size(600, 20)
$TextBox1Tab2.TabIndex = 1
$TextBox1Tab2.Text = "ISO File Name and path"
#~~< TextBox2Tab2 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TextBox2Tab2 = New-Object System.Windows.Forms.TextBox
$TextBox2Tab2.Location = New-Object System.Drawing.Point(200, 60)
$TextBox2Tab2.Size = New-Object System.Drawing.Size(600, 20)
$TextBox2Tab2.TabIndex = 3
$TextBox2Tab2.Text = "Foldername"
#~~< Button1Tab2 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Button1Tab2 = New-Object System.Windows.Forms.Button
$Button1Tab2.Location = New-Object System.Drawing.Point(820, 30)
$Button1Tab2.Size = New-Object System.Drawing.Size(100, 23)
$Button1Tab2.TabIndex = 2
$Button1Tab2.Text = "Browse"
$Button1Tab2.UseVisualStyleBackColor = $true
$Button1Tab2.add_Click({Button1Tab2Click($Button1Tab2)})
#~~< Button2Tab2 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Button2Tab2 = New-Object System.Windows.Forms.Button
$Button2Tab2.Location = New-Object System.Drawing.Point(1120, 280)
$Button2Tab2.Size = New-Object System.Drawing.Size(100, 23)
$Button2Tab2.TabIndex = 17
$Button2Tab2.Text = "Import"
$Button2Tab2.UseVisualStyleBackColor = $true
$Button2Tab2.add_Click({Button2Tab2Click($Button2Tab2)})

$TabPage2.Controls.Add($Button2Tab2)
$TabPage2.Controls.Add($Button1Tab2)
$TabPage2.Controls.Add($TextBox1Tab2)
$TabPage2.Controls.Add($TextBox2Tab2)
$TabPage2.Controls.Add($Label1Tab2)
$TabPage2.Controls.Add($Label2Tab2)
$TabPage2.add_Click({TabPage2Click($TabPage2)})
#endregion GUI }

#region begin GUI{ 

#~~< TabPage3 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TabPage3 = New-Object System.Windows.Forms.TabPage
$TabPage3.Font = New-Object System.Drawing.Font($font, 10)
$TabPage3.Location = New-Object System.Drawing.Point(4, 22)
$TabPage3.Padding = New-Object System.Windows.Forms.Padding(3)
$TabPage3.Size = New-Object System.Drawing.Size(100, 400)
$TabPage3.TabIndex = 2
$TabPage3.Text = "Configuration"
$TabPage3.UseVisualStyleBackColor = $true
#~~< Label1Tab3 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Label1Tab3 = New-Object System.Windows.Forms.Label
$Label1Tab3.Location = New-Object System.Drawing.Point(20, 30)
$Label1Tab3.Size = New-Object System.Drawing.Size(180, 23)
$Label1Tab3.Text = "MDT DeploymentShare"
#~~< Label2Tab3 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Label2Tab3 = New-Object System.Windows.Forms.Label
$Label2Tab3.Location = New-Object System.Drawing.Point(20, 60)
$Label2Tab3.Size = New-Object System.Drawing.Size(180, 23)
$Label2Tab3.Text = "Hyper-V Computername"
#~~< Label3Tab3 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Label3Tab3 = New-Object System.Windows.Forms.Label
$Label3Tab3.Location = New-Object System.Drawing.Point(20, 90)
$Label3Tab3.Size = New-Object System.Drawing.Size(180, 23)
$Label3Tab3.Text = "Hyper-V Switch name"
#~~< Label4Tab3 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Label4Tab3 = New-Object System.Windows.Forms.Label
$Label4Tab3.Location = New-Object System.Drawing.Point(20, 120)
$Label4Tab3.Size = New-Object System.Drawing.Size(180, 23)
$Label4Tab3.Text = "VLAN ID"
#~~< Label4Tab2 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Label5Tab3 = New-Object System.Windows.Forms.Label
$Label5Tab3.Location = New-Object System.Drawing.Point(20, 150)
$Label5Tab3.Size = New-Object System.Drawing.Size(180, 23)
$Label5Tab3.Text = "VM Location"
#~~< Label5Tab3 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Label6Tab3 = New-Object System.Windows.Forms.Label
$Label6Tab3.Location = New-Object System.Drawing.Point(20, 180)
$Label6Tab3.Size = New-Object System.Drawing.Size(180, 23)
$Label6Tab3.Text = "ISO Location"
#~~< Label6Tab3 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Label7Tab3 = New-Object System.Windows.Forms.Label
$Label7Tab3.Location = New-Object System.Drawing.Point(20, 210)
$Label7Tab3.Size = New-Object System.Drawing.Size(180, 23)
$Label7Tab3.Text = "BuildAccount Name"
#~~< Label7Tab3 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Label8Tab3 = New-Object System.Windows.Forms.Label
$Label8Tab3.Location = New-Object System.Drawing.Point(20, 240)
$Label8Tab3.Size = New-Object System.Drawing.Size(180, 23)
$Label8Tab3.Text = "BuildAccount Password"
#~~< Label9Tab3 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Label9Tab3 = New-Object System.Windows.Forms.Label
$Label9Tab3.Location = New-Object System.Drawing.Point(20, 270)
$Label9Tab3.Size = New-Object System.Drawing.Size(180, 23)
$Label9Tab3.Text = "Customer Name"
#~~< TextBox1Tab3 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TextBox1Tab3 = New-Object System.Windows.Forms.TextBox
$TextBox1Tab3.Location = New-Object System.Drawing.Point(200, 30)
$TextBox1Tab3.Size = New-Object System.Drawing.Size(600, 20)
$TextBox1Tab3.TabIndex = 15
$TextBox1Tab3.Text = "$($XMLdata.Settings.MDT.DeploymentShare)"
#~~< TextBox2Tab3 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TextBox2Tab3 = New-Object System.Windows.Forms.TextBox
$TextBox2Tab3.Location = New-Object System.Drawing.Point(200, 60)
$TextBox2Tab3.Size = New-Object System.Drawing.Size(600, 20)
$TextBox2Tab3.TabIndex = 14
$TextBox2Tab3.Text = $XMLdata.Settings.HyperV.Computername
#~~< TextBox3Tab3 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TextBox3Tab3 = New-Object System.Windows.Forms.TextBox
$TextBox3Tab3.Location = New-Object System.Drawing.Point(200, 90)
$TextBox3Tab3.Size = New-Object System.Drawing.Size(600, 20)
$TextBox3Tab3.TabIndex = 13
$TextBox3Tab3.Text = $XMLdata.Settings.HyperV.SwitchName
#~~< TextBox4Tab3 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TextBox4Tab3 = New-Object System.Windows.Forms.TextBox
$TextBox4Tab3.Location = New-Object System.Drawing.Point(200, 120)
$TextBox4Tab3.Size = New-Object System.Drawing.Size(600, 20)
$TextBox4Tab3.TabIndex = 9
$TextBox4Tab3.Text = $XMLdata.Settings.HyperV.VLANID
#~~< TextBox5Tab3 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TextBox5Tab3 = New-Object System.Windows.Forms.TextBox
$TextBox5Tab3.Location = New-Object System.Drawing.Point(200, 150)
$TextBox5Tab3.Size = New-Object System.Drawing.Size(600, 20)
$TextBox5Tab3.TabIndex = 9
$TextBox5Tab3.Text = $XMLdata.Settings.HyperV.VMLocation
#~~< TextBox6Tab3 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TextBox6Tab3 = New-Object System.Windows.Forms.TextBox
$TextBox6Tab3.Location = New-Object System.Drawing.Point(200, 180)
$TextBox6Tab3.Size = New-Object System.Drawing.Size(600, 20)
$TextBox6Tab3.TabIndex = 9
$TextBox6Tab3.Text = $XMLdata.Settings.HyperV.ISOLocation
#~~< TextBox7Tab3 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TextBox7Tab3 = New-Object System.Windows.Forms.TextBox
$TextBox7Tab3.Location = New-Object System.Drawing.Point(200, 210)
$TextBox7Tab3.Size = New-Object System.Drawing.Size(600, 20)
$TextBox7Tab3.TabIndex = 9
$TextBox7Tab3.Text = $XMLdata.Settings.Security.BuildAccount.Name
#~~< TextBox8Tab3 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TextBox8Tab3 = New-Object System.Windows.Forms.TextBox
$TextBox8Tab3.Location = New-Object System.Drawing.Point(200, 240)
$TextBox8Tab3.Size = New-Object System.Drawing.Size(600, 20)
$TextBox8Tab3.TabIndex = 9
$TextBox8Tab3.Text = $XMLdata.Settings.Security.BuildAccount.Password
#~~< TextBox9Tab3 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TextBox9Tab3 = New-Object System.Windows.Forms.TextBox
$TextBox9Tab3.Location = New-Object System.Drawing.Point(200, 270)
$TextBox9Tab3.Size = New-Object System.Drawing.Size(600, 20)
$TextBox9Tab3.TabIndex = 9
$TextBox9Tab3.Text = $XMLdata.Settings.CustomerName


#~~< Button1Tab3 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Button1Tab3 = New-Object System.Windows.Forms.Button
$Button1Tab3.Location = New-Object System.Drawing.Point(1000, 30)
$Button1Tab3.Size = New-Object System.Drawing.Size(200, 50)
$Button1Tab3.TabIndex = 17
$Button1Tab3.Text = "Save configuration"
$Button1Tab3.UseVisualStyleBackColor = $true
$Button1Tab3.add_Click({Button1Tab3Click($Button1Tab3)})

#~~< Button2Tab3 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Button2Tab3 = New-Object System.Windows.Forms.Button
$Button2Tab3.Location = New-Object System.Drawing.Point(1000, 120)
$Button2Tab3.Size = New-Object System.Drawing.Size(200, 50)
$Button2Tab3.TabIndex = 17
$Button2Tab3.Text = "Install IMF"
$Button2Tab3.UseVisualStyleBackColor = $true
$Button2Tab3.add_Click({Button2Tab3Click($Button2Tab3)})

#~~< Button3Tab3 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Button3Tab3 = New-Object System.Windows.Forms.Button
$Button3Tab3.Location = New-Object System.Drawing.Point(1000, 210)
$Button3Tab3.Size = New-Object System.Drawing.Size(200, 50)
$Button3Tab3.TabIndex = 17
$Button3Tab3.Text = "Uninstall IMF"
$Button3Tab3.UseVisualStyleBackColor = $true
$Button3Tab3.add_Click({Button3Tab3Click($Button3Tab3)})


$TabPage3.Controls.Add($Label1Tab3)
$TabPage3.Controls.Add($Label2Tab3)
$TabPage3.Controls.Add($Label3Tab3)
$TabPage3.Controls.Add($Label4Tab3)
$TabPage3.Controls.Add($Label4Tab3)
$TabPage3.Controls.Add($Label5Tab3)
$TabPage3.Controls.Add($Label6Tab3)
$TabPage3.Controls.Add($Label7Tab3)
$TabPage3.Controls.Add($Label8Tab3)
$TabPage3.Controls.Add($Label9Tab3)
$TabPage3.Controls.Add($TextBox1Tab3)
$TabPage3.Controls.Add($TextBox2Tab3)
$TabPage3.Controls.Add($TextBox3Tab3)
$TabPage3.Controls.Add($TextBox4Tab3)
$TabPage3.Controls.Add($TextBox5Tab3)
$TabPage3.Controls.Add($TextBox6Tab3)
$TabPage3.Controls.Add($TextBox7Tab3)
$TabPage3.Controls.Add($TextBox8Tab3)
$TabPage3.Controls.Add($TextBox9Tab3)
$TabPage3.Controls.Add($Button1Tab3)
$TabPage3.Controls.Add($Button2Tab3)
$TabPage3.Controls.Add($Button3Tab3)
$TabPage3.add_Click({TabPage3Click($TabPage3)})

#endregion GUI}

#region begin GUI{ 
$TabControl1.Controls.Add($TabPage1)
$TabControl1.Controls.Add($TabPage2)
$TabControl1.Controls.Add($TabPage3)
$TabControl1.SelectedIndex = 0
$Form1.Controls.Add($Button1)
$Form1.Controls.Add($TabControl1)
$Form1.Controls.Add($result1)
$Form1.Controls.Add($PictureBox1)

#endregion GUI}

#~~< OpenFileDialog1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$OpenFileDialog1 = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog1.Filter = "ISO Images (*.iso)|*.iso|All files (*.*)|*.*"
$OpenFileDialog1.CheckFileExists

#~~< FolderBrowserDialog1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$FolderBrowserDialog1 = New-Object System.Windows.Forms.FolderBrowserDialog

function Main{
	[System.Windows.Forms.Application]::EnableVisualStyles()
	[System.Windows.Forms.Application]::Run($Form1)
}

#region Event Handlers

function TabPage1Click( $object ){

}

function TabPage2Click( $object ){

}

function TabPage3Click( $object ){

}

function Button1Click( $object ){
    #Close
    $Form1.Close()
}

function Button1Tab1Click( $object ){
    $result1.Items.Clear()
    $result1.Items.Add("Update and distribute the bootimage")
    Start-Sleep -Seconds 1
    $ScriptBlock = [ScriptBlock]::Create("$CurrentPath\Scripts\IMF-UpdateBootImage.ps1")
    Invoke-Command -ScriptBlock $ScriptBlock
}

function Button2Tab1Click( $object ){
    $result1.Items.Clear()
    $result1.Items.Add("Remove Reference/Validation VMs")
    Start-Sleep -Seconds 1
    $ScriptBlock = [ScriptBlock]::Create("$CurrentPath\Scripts\IMF-VerifyCleanupVMs.ps1")
    Invoke-Command -ScriptBlock $ScriptBlock
}

function Button3Tab1Click( $object ){
    $result1.Items.Clear()
    $result1.Items.Add("Create reference image(s) with patches")
    Start-Sleep -Seconds 1
    $ScriptBlock = [ScriptBlock]::Create("$CurrentPath\Scripts\IMF-Build.ps1 -EnableWSUS True")
    Invoke-Command -ScriptBlock $ScriptBlock
}

function Button4Tab1Click( $object ){
    $result1.Items.Clear()
    $result1.Items.Add("Create reference image(s) without patches")
    Start-Sleep -Seconds 1
    $ScriptBlock = [ScriptBlock]::Create("$CurrentPath\Scripts\IMF-Build.ps1 -EnableWSUS False")
    Invoke-Command -ScriptBlock $ScriptBlock
}

function Button5Tab1Click( $object ){
    $result1.Items.Clear()
    $result1.Items.Add("building validation VM(s)")
    Start-Sleep -Seconds 1
    $ScriptBlock = [ScriptBlock]::Create("$CurrentPath\Scripts\IMF-VerifyBuild.ps1 -KeepVMs False")
    Invoke-Command -ScriptBlock $ScriptBlock
}

function Button6Tab1Click( $object ){
    $result1.Items.Clear()
    $result1.Items.Add("Generate OS reports")
    Start-Sleep -Seconds 1
    $ScriptBlock = [ScriptBlock]::Create("$CurrentPath\Scripts\IMF-GenerateReport.ps1")
    Invoke-Command -ScriptBlock $ScriptBlock
}

function Button7Tab1Click( $object ){
    $result1.Items.Clear()
    $result1.Items.Add("Archive WIM files")
    Start-Sleep -Seconds 1
    $ScriptBlock = [ScriptBlock]::Create("$CurrentPath\Scripts\IMF-Archive.ps1")
    Invoke-Command -ScriptBlock $ScriptBlock
}

function Button1Tab2Click( $object ){
    $result = $OpenFileDialog1.ShowDialog()
    if($result -eq "ok"){
        $TextBox1Tab2.Text = $OpenFileDialog1.FileName
    }
}

function Button2Tab2Click( $object ){
    $result1.Items.Clear()
    $result1.Items.Add("Import")
    Start-Sleep -Seconds 1
    $ScriptBlock = [ScriptBlock]::Create("$CurrentPath\Scripts\IMF-ImportISO.ps1 -ISOImage $($TextBox1Tab2.Text) -OSFolder $($TextBox2Tab2.Text) -OrgName $($Settings.Settings.CustomerName)")
    Invoke-Command -ScriptBlock $ScriptBlock
}

function Button1Tab3Click( $object ){
    $result1.Items.Clear()
    $result1.Items.Add("Saving configuration")
    Start-Sleep -Seconds 1
    $ScriptBlock = [ScriptBlock]::Create("$CurrentPath\Scripts\IMF-Configure.ps1 -DeploymentShare $($TextBox1Tab3.Text) -StartUpRAM 3 -VLANID $($TextBox4Tab3.Text) -Computername $($TextBox2Tab3.Text) -SwitchName $($TextBox3Tab3.Text) -VMLocation $($TextBox5Tab3.Text) -ISOLocation $($TextBox6Tab3.Text) -BuildaccountName $($TextBox7Tab3.Text) -BuildaccountPassword $($TextBox8Tab3.Text) -CustomerName $($TextBox9Tab3.Text)")
    Invoke-Command -ScriptBlock $ScriptBlock
}

function Button2Tab3Click( $object ){
    $result1.Items.Clear()
    $result1.Items.Add("Installing")
    Start-Sleep -Seconds 1
    $ScriptBlock = [ScriptBlock]::Create("$CurrentPath\Scripts\IMF-Install.ps1")
    Invoke-Command -ScriptBlock $ScriptBlock
}

function Button3Tab3Click( $object ){
    $result1.Items.Clear()
    $result1.Items.Add("Uninstalling")
    Start-Sleep -Seconds 1
    $ScriptBlock = [ScriptBlock]::Create("$CurrentPath\Scripts\IMF-UnInstall.ps1")
    Invoke-Command -ScriptBlock $ScriptBlock

}

Main # This call must remain below all other event functions

#endregion


