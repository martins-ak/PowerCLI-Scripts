#Read the user credentials to log in to vCenter	Server;	Change to your credential file's location and name (must be created before using)
$credentials = Import-CliXml -Path "C:\Users\918842605\Downloads\Scripts\SFSU\pscred.xml"

#Connect to the vCenter Server specified on the $vCenter variable; use the credentials previously loaded
$vCenter = "vc01.ops.sfsu.edu"
Connect-VIServer $vCenter -Credential $credentials

#Get the ESXi host name passed on from the "Run" line and enable the SSH Service on it
Get-VMHost -Name $args[0] | Get-VMHostService | Where {$_.Key -eq "TSM-SSH"} | Start-VMHostService

#Open a putty session to said host and wait for the window to be closed before continuing the script
putty $args[0] | Out-Null

#When the putty window is clossed, disable the SSH Service on the host
Get-VMHost -Name $args[0] | Get-VMHostService | Where {$_.Key -eq "TSM-SSH"} | Stop-VMHostService -Confirm:$false

#Disconnect from the vCenter Server session
Disconnect-VIServer * -Confirm:$false