#####################################################################################################
#																									#
#Created By:	Martin Aides-Klok																	#
#Purpose:		Export a list of VMs by OS type (Windows and Non Windows = Linux Distros)			#
#Explanation:	Line 20 - Read the user credentials to log in to vCenter Server;					#
#				Change to your credential file's location and name (must be created before using)	#
#				Lines 22-23 - Disconnect from any already connected vCenter Server to clear the		#
#				session; if there's no current	connections, omit the error message and continue	#
#				Lines 25-26 - Connect to the vCenter Server specified on the $vCenter variable;		#
#				use the credentials previously loaded												#
#				Line 28 - Get all Windows VMs and ...												#
#				Line 30 - Get all Non-Windows VMs (various Linux distributions) and ...				#
#																									#
#				...export them to a	csv file including the VM's Name, Power State, Guest OS and		#
#				IP Address (last one will work only if VMware Tools	is installed and running on the	#
#				VM); Adjust the file name and path accordingly										#
#																									#
#################################MAY THE SCRIPTING FORCE BE WITH YOU#################################

$credentials = Import-CliXml -Path "C:\Users\918842605\Downloads\Scripts\SFSU\pscred.xml"

try {Disconnect-VIServer * -Confirm:$false}
catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.VimException]{}

$vCenter = "vc01.ops.sfsu.edu"
Connect-VIServer $vCenter -Credential $credentials

Get-VM | where {$_.ExtensionData.config.GuestFullName -like "*windows*"} | select Name,PowerState,@{N="OS";E={$_.ExtensionData.config.GuestFullName}},@{N="IPAddresses";E={$_.guest.IPAddress}} | Export-Csv -NoTypeInformation "C:\Users\918842605\Downloads\WindowsVMs.csv"

Get-VM | where {($_.ExtensionData.config.GuestFullName -notlike "*windows*") -and ($_.ExtensionData.config.GuestFullName -notlike "*photon*")} | select Name,PowerState,@{N="OS";E={$_.ExtensionData.config.GuestFullName}},@{N="IPAddresses";E={$_.guest.IPAddress}} | Export-Csv -NoTypeInformation "C:\Users\918842605\Downloads\LinuxVMs.csv"