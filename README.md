# Overview
This project saves running configuration of Dell switches to a TFTP server. 
Note: I tested it on Dell EMC S4048-ON switches.
# Prerequisites
1. TFTP server should be configured and running.
2. SSH should be enabled on the switch.
3. All the switches should have same user name and password.
4. Password should be encrypted and written to a text file called "keyfile.txt" under "/lib/key" location.
5. After logging in, the switch should be in "Enable" mode.
# How to use?
Once the project is cloned to your local machine, follow the steps below.
1. Edit "switch_list.txt" and provide IP of the switches that you want to backup.
2. Next step is to edit "invoke_switch_config_backup.ps1" and provide TFTP server location.
3. If user name to login to your switch is not "admin", you need to edit it in "invoke_switch_config_backup.ps1". 
4. Encrypt the password and save it in "keyfile.txt" under "/lib/key" location. Example: "Pass1234" | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString | Out-File "C:\keyfile.txt" . Here "Pass1234" will be encrypted and stored in "C:\keyfile.txt". Copy this "keyfile.txt" and replace it with key file under "/lib/key".
5. Once the above steps are complete, PS > .\invoke_switch_config_backup.ps1
# Use case
You can schedule this PS script using a task scheduler, so that the running configuration of switches can be backed up automatically on a daily basis or as per requirements. 
# References
Encrypting creds with PowerShell: https://www.pdq.com/blog/secure-password-with-powershell-encrypting-credentials-part-1/
Setting up a TFTP server: http://www.tricksguide.com/how-to-setup-a-tftp-server-tftpd32-windows.html
