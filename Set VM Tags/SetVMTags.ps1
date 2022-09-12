#####################################################################################################
#																									#
#Created By:	Martin Aides-Klok																	#
#Purpose:		Set tags on a list of VMs (e.g for backup purposes, vROPS groups, etc.)				#
#Explanation:	Line 18 - Read the user credentials to log in to vCenter Server;					#
#				Change to your credential file's location and name (must be created before using)	#
#				Lines 20-21 - Disconnect from any already connected vCenter Server to clear the		#
#				session; if there's no current	connections, omit the error message and continue	#
#				Lines 23-24 - Connect to the vCenter Server specified on the $vCenter variable;		#
#				use the credentials previously loaded												#
#				Line 26 - Import the list of VMs and the tag that needs to be assigned to each;		#
#				Exact VM name must be specified; Tags need to be pre-existing; If more than one tag	#
#				needs to be assigned, it must be on separate lines for said VM						#
#				Lines 28-30 - Run for each VM on the loaded list and assign the tag from said list	#
#																									#
#################################MAY THE SCRIPTING FORCE BE WITH YOU#################################

$credentials = Import-CliXml -Path "C:\Users\918842605\Downloads\Scripts\SFSU\pscred.xml"

try {Disconnect-VIServer * -Confirm:$false}
catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.VimException]{}

$vCenter = "vc01.ops.sfsu.edu"
Connect-VIServer $vCenter -Credential $credentials

$vmList = Import-Csv "C:\Users\918842605\Downloads\Scripts\SFSU\Set VM Tags\vmTagging.csv"

foreach ($singleVM in $vmList){
    Get-VM $singleVM.Name | New-TagAssignment -Tag $singleVM.Backup
}