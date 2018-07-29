###########################################################################
# Module Name  : Dell_Switch_Configuration_Backup
# Script Name  : invoke_switch_config_backup.ps1
# Author       : Vineeth A.C.
# Version      : 0.1
# Last Modified: 28/07/2018 (ddMMyyyy)
###########################################################################
<#
.SYNOPSIS
This script invokes Dell switch configuration using SSH
.EXAMPLE
PS>.\invoke_switch_config_backup.ps1
#>

Begin {
	$LibFolder = "$PSScriptRoot\Lib"
	$LogFolder = "$PSScriptRoot\logs"
    
    try {
		Import-Module $LibFolder\helpers\helpers.psm1 -Force  -ErrorAction Stop
		Show-Message -Message "[Region] Prerequisite - helpers loaded."
    }
    catch {
		Show-Message -Severity high -Message "[EndRegion] Failed - Prerequisite of loading modules"
		Write-VerboseLog -ErrorInfo $PSItem
		$PSCmdlet.ThrowTerminatingError($PSItem)
	}
	
	#region generate the transcript log
	#Modifying the VerbosePreference in the Function Scope
	$Start = Get-Date
	$VerbosePreference = 'Continue'
	$TranscriptName = '{0}_{1}.log' -f $(($MyInvocation.MyCommand.Name.split('.'))[0]),$(Get-Date -Format ddMMyyyyhhmmss)
	Start-Transcript -Path "$LogFolder\$TranscriptName"
	#endregion generate the transcript log

	#region log the current Script version in use
	Write-VerboseLog -Message "[Region] log the current script version in use"
	$ParseError = $null
	$Tokens = $null
	$null = [System.Management.Automation.Language.Parser]::ParseInput($($MyInvocation.MyCommand.ScriptContents),[ref]$Tokens,[ref]$ParseError)
	$VersionComment = $Tokens | Where-Object -filterScript { ($PSitem.Kind -eq "Comment") -and ($PSitem.Text -like '*version*')}
	#Put the version in the verbose messages for the log to cpature it
	Write-VerboseLog -Message "Script -> $($MyInvocation.MyCommand.Name) ; Version -> $(($VersionComment -split ':')[1])"
	#Remove the variables used above
	Remove-Variable	-Name ParseError,Tokens,VersionComment
	Write-VerboseLog -Verbose -Message "[EndRegion] log the current script version in use"
	#endregion log the current script version in use
				
	#Collecting creds to SSH
	$securePassword = Get-Content $LibFolder\key\keyfile.txt | ConvertTo-SecureString
	$cred = New-Object System.Management.Automation.PSCredential ('admin', $securePassword)
				
	#Collecting IP address of switches from the list
	list = Get-Content .\switch_list.txt
}

Process {
	For ($i = 0; $i -lt $list.count; $i++){
		$sw_ip = $list[$i]
		if ($sw_ip) {
			Show-Message "Creating new SSH session to $sw_ip"
			$SWssh = New-SSHSession -ComputerName $list[$i] -Credential $cred -Force -ConnectionTimeout 300
			Show-Message "Connected to Switch. This will take few seconds."
			Start-Sleep -s 3

			$filename =(Get-Date).tostring("dd-MM-yyyy-hh-mm-ss")
			$cmd_backup = "copy running-config tftp://100.98.22.33/$sw_ip/$filename.txt"
			Show-Message $cmd_backup
			$config_backup = invoke-sshcommand -Command $cmd_backup -SSHSession $SWssh
			Show-Message "Running config copied to tftp://100.98.22.33/$sw_ip"
			Start-Sleep -s 3
		}
	}
}
