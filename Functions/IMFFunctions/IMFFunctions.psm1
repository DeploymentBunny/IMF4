Function Update-Log
{
    Param(
    [Parameter(
        Mandatory=$true, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true,
        Position=0
    )]
    [string]$Data,

    [Parameter(
        Mandatory=$false, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true,
        Position=0
    )]
    [string]$Solution = $Solution,

    [Parameter(
        Mandatory=$false, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true,
        Position=1
    )]
    [validateset('Information','Warning','Error')]
    [string]$Class = "Information"

    )
    $global:ScriptLogFilePath = $Log
    $LogString = "$Solution, $Data, $Class, $(Get-Date)"
    $HostString = "$Solution, $Data, $(Get-Date)"

    
    Add-Content -Path $Log -Value $LogString
    switch ($Class)
    {
        'Information'{
            Write-Host $HostString -ForegroundColor Gray
            }
        'Warning'{
            Write-Host $HostString -ForegroundColor Yellow
            }
        'Error'{
            Write-Host $HostString -ForegroundColor Red
            }
        Default {}
    }
}
Function Test-VIAHypervConnection
{
    Param(
        $Computername,
        $ISOFolder,
        $VMFolder,
        $VMSwitchName
    )
    #Verify SMB access
    $Result = Test-NetConnection -ComputerName $Computername -CommonTCPPort SMB
    If ($Result.TcpTestSucceeded -eq $true){Write-Verbose "SMB Connection to $Computername is ok"}else{Write-Warning "SMB Connection to $Computername is NOT ok";Return $False}

    #Verify WinRM access
    $Result = Test-NetConnection -ComputerName $Computername -CommonTCPPort WINRM
    If ($Result.TcpTestSucceeded -eq $true){Write-Verbose "WINRM Connection to $Computername is ok"}else{Write-Warning "WINRM Connection to $Computername is NOT ok";Return $False}

    #Verify that Microsoft-Hyper-V-Management-PowerShell is installed
    Invoke-Command -ComputerName $Computername -ScriptBlock {
        $Result = (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Management-PowerShell)
        Write-Verbose "$($Result.DisplayName) is $($Result.State)"
        If($($Result.State) -ne "Enabled"){Write-Warning "$($Result.DisplayName) is not Enabled";Return $False}
    }

    #Verify that Microsoft-Hyper-V-Management-PowerShell is installed
    Invoke-Command -ComputerName $Computername -ScriptBlock {
        $Result = (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V)
        If($($Result.State) -ne "Enabled"){Write-Warning "$($Result.DisplayName) is not Enabled";Return $False}
    }

    #Verify that Hyper-V is running
    Invoke-Command -ComputerName $Computername -ScriptBlock {
        $Result = (Get-Service -Name vmms)
        Write-Verbose "$($Result.DisplayName) is $($Result.Status)"
        If($($Result.Status) -ne "Running"){Write-Warning "$($Result.DisplayName) is not Running";Return $False}
    }

    #Verify that the ISO Folder is created
    Invoke-Command -ComputerName $Computername -ScriptBlock {
        Param(
        $ISOFolder
        )
        $result = New-Item -Path $ISOFolder -ItemType Directory -Force
    } -ArgumentList $ISOFolder

    #Verify that the VM Folder is created
    Invoke-Command -ComputerName $Computername -ScriptBlock {
        Param(
        $VMFolder
        )
        $result = New-Item -Path $VMFolder -ItemType Directory -Force
    } -ArgumentList $VMFolder

    #Verify that the VMSwitch exists
    Invoke-Command -ComputerName $Computername -ScriptBlock {
        Param(
        $VMSwitchName
        )
        if(((Get-VMSwitch | Where-Object -Property Name -EQ -Value $VMSwitchName).count) -eq "1"){Write-Verbose "Found $VMSwitchName"}else{Write-Warning "No switch with the name $VMSwitchName found";Return $False}
    } -ArgumentList $VMSwitchName
    Return $True
}
Function Start-Log
{
[CmdletBinding()]
    param (
    [ValidateScript({ Split-Path $_ -Parent | Test-Path })]
	[string]$FilePath
    )
	
    try
    {
        if (!(Test-Path $FilePath))
	{
	    ## Create the log file
	    New-Item $FilePath -Type File | Out-Null
	}
		
	## Set the global variable to be used as the FilePath for all subsequent Write-Log
	## calls in this session
	$global:ScriptLogFilePath = $FilePath
    }
    catch
    {
        Write-Error $_.Exception.Message
    }
}
Function Write-Log
{
param (
    [Parameter(Mandatory = $true)]
    [string]$Message,
		
    [Parameter()]
    [ValidateSet(1, 2, 3)]
    [string]$LogLevel = 1
   )

    $TimeGenerated = "$(Get-Date -Format HH:mm:ss).$((Get-Date).Millisecond)+000"
    $Line = '<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="" type="{4}" thread="" file="">'
    $LineFormat = $Message, $TimeGenerated, (Get-Date -Format MM-dd-yyyy), "$($MyInvocation.ScriptName | Split-Path -Leaf):$($MyInvocation.ScriptLineNumber)", $LogLevel
    #$LineFormat = $Message, $TimeGenerated, (Get-Date -Format MM-dd-yyyy), "$($MyInvocation.ScriptName | Split-Path -Leaf)", $LogLevel
    $Line = $Line -f $LineFormat
    Add-Content -Value $Line -Path $ScriptLogFilePath

    if($writetoscreen -eq $true){
        switch ($LogLevel)
        {
            '1'{
                Write-Host $Message -ForegroundColor Gray
                }
            '2'{
                Write-Host $Message -ForegroundColor Yellow
                }
            '3'{
                Write-Host $Message -ForegroundColor Red
                }
            Default {}
        }
    }

    if($writetolistbox -eq $true){
        $result1.Items.Add("$Message")
    }
}
Function Get-VIARefTaskSequence
{
    Param(
    $RefTaskSequenceFolder
    )
    $RefTaskSequences = Get-ChildItem $RefTaskSequenceFolder
    Foreach($RefTaskSequence in $RefTaskSequences){
        New-Object PSObject -Property @{ 
        TaskSequenceID = $RefTaskSequence.ID
        Name = $RefTaskSequence.Name
        Comments = $RefTaskSequence.Comments
        Version = $RefTaskSequence.Version
        Enabled = $RefTaskSequence.enable
        LastModified = $RefTaskSequence.LastModifiedTime
        } 
    }
}
