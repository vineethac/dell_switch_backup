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

#New SSH session to the Switch
$securePassword = ConvertTo-SecureString 'Dell1234' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ('admin', $securePassword)

$list = Get-Content .\switch_list.txt

For ($i = 0; $i -lt $list.count; $i++){

$sw_ip = $list[$i]
if ($sw_ip) {

Write-Host "Creating new SSH session to $sw_ip"
$SWssh = New-SSHSession -ComputerName $list[$i] -Credential $cred -Force -ConnectionTimeout 300
Write-Host "Connected to Switch. This will take few seconds."
Start-Sleep -s 3

$filename =(Get-Date).tostring("dd-MM-yyyy-hh-mm-ss")

$cmd_backup = "copy running-config tftp://100.98.22.33/$sw_ip/$filename.txt"
write-host $cmd_backup
$config_backup = invoke-sshcommand -Command $cmd_backup -SSHSession $SWssh
Write-Host "Running config copied to tftp://100.98.22.33/$sw_ip"
Start-Sleep -s 3
}
}