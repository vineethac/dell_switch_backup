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
	try {
		Show-Message -Message "Collecting secure password"
		$securePassword = Get-Content $LibFolder\key\keyfile.txt | ConvertTo-SecureString
	}
	catch {
		Show-Message -Severity high -Message "Failed to collect encrypted password. Exiting!"
		Write-Verbose -ErrorInfo $PSItem
		Stop-Transcript
		$PSCmdlet.ThrowTerminatingError($PSItem)
	}
	$cred = New-Object System.Management.Automation.PSCredential ('admin', $securePassword)
				
	#Collecting IP address of switches from the list
	try {
		Show-Message -Message "Collecting IP address of Dell switches from switch list"
		$list = Get-Content .\switch_list.txt
	}
	catch {
		Show-Message -Severity high -Message "Failed to collect IP info from the list"
		Write-Verbose -ErrorInfo $PSItem
		Stop-Transcript
		$PSCmdlet.ThrowTerminatingError($PSItem)
	}
}

Process {
	For ($i = 0; $i -lt $list.count; $i++){
		$sw_ip = $list[$i]
		if ($sw_ip) {
			try {
				Show-Message -Message "Creating new SSH session to $sw_ip"
				$SWssh = New-SSHSession -ComputerName $list[$i] -Credential $cred -Force -ConnectionTimeout 300
				Show-Message -Message "Connected to Switch. This will take few seconds."
			}
			catch {
				Show-Message -Severity high -Message "Unable to SSH to switch $sw_ip Quiting!"
				Write-VerboseLog -ErrorInfo $PSItem
				Stop-Transcript
				$PSCmdlet.ThrowTerminatingError($PSItem)
			}
			
			Start-Sleep -s 3

			$filename =(Get-Date).tostring("dd-MM-yyyy-hh-mm-ss")
			$cmd_backup = "copy running-config tftp://100.98.22.33/$sw_ip/$filename.txt"
			Show-Message -Message $cmd_backup
			try {
				$config_backup = invoke-sshcommand -Command $cmd_backup -SSHSession $SWssh
				Show-Message -Message "Running config copied to tftp://100.98.22.33/$sw_ip"	
			}
			catch {
				Show-Message -Severity high -Message "Failed to save running config to TFTP location!"
        		Write-VerboseLog -ErrorInfo $PSItem
        		Stop-Transcript
        		$PSCmdlet.ThrowTerminatingError($PSItem)
			}
			Start-Sleep -s 3
		}
	}
}
