Prerequisites:
--------------

- Create vCenter XML pscredentials and adjust their location on the ssh.ps1 file (4th line). 	To do so, run the following commands from a powershell window:
$credential = Get-Credential
$credential | Export-CliXml -Path 'C:\My\Path\cred.xml'

- Adjust the path of the ssh.ps1 script on the ssh.bat file

- Copy ssh.bat and putty.exe to System32 folder


Usage:
------

- From the Run window: ssh HOST_NAME


