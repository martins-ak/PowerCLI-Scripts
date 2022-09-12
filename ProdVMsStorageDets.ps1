#####################################################################################################
#																									#
#Created By:	Martin Aides-Klok																	#
#Purpose:		Get production VM's	storage related data											#
#Explanation:	Line 19 - Read the user credentials to log in to vCenter Server;					#
#				Change to your credential file's location and name (must be created before using)	#
#				Lines 21-22 - Disconnect from any already connected vCenter Server to clear the		#
#				session; if there's no current	connections, omit the error message and continue	#
#				Lines 24-25 - Connect to the vCenter Server specified on the $vCenter variable;		#
#				use the credentials previously loaded												#
#				Line 27 - Get all the prod VMs, except the veeam related ones						#
#				Line 29 - Get the VM's name, power state and used/provisioned space; Export the data#
#				to a different csv file; Change the file name and path accordingly					#
#				Lines 31-33 - Run for each VM and retrieve each hard disk location and size; Export	#
#				the data to a different csv file; Change the file name and path accordingly			#
#																									#
#################################MAY THE SCRIPTING FORCE BE WITH YOU#################################

$credentials = Import-CliXml -Path "C:\Users\918842605\Downloads\Scripts\SFSU\pscred.xml"

try {Disconnect-VIServer * -Confirm:$false}
catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.VimException]{}

$vCenter = "vc01.ops.sfsu.edu"
Connect-VIServer $vCenter -Credential $credentials

$prodVMs = Get-Cluster | where {($_.Name -like "SFSU_Production_Cluster") -or ($_.Name -like "SFSU_Snowflakes_Cluster")} | Get-VM | where {$_.Name -notlike "*veeam*"}

$prodVMs | select Name,PowerState,@{N="UsedSpaceGB";E={[int]$_.UsedSpaceGB}},@{N="ProvisionedSpaceGB";E={[int]$_.ProvisionedSpaceGB}} | Export-Csv -NoTypeInformation "C:\Users\918842605\Downloads\Scripts\SFSU\prodVMsDiskSpace.csv"

foreach ($onevm in $prodVMs){
    $onevm | Get-HardDisk | Select @{N="VM Name";E={$onevm.Name}},@{N="Disk Number";E={$_.Name}},CapacityGB,StorageFormat | Export-Csv -NoTypeInformation "C:\Users\918842605\Downloads\Scripts\SFSU\prodVMsDisksFormat.csv" -Append
}