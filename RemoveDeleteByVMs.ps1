#####################################################################################################
#																									#
#Created By:	Martin Aides-Klok																	#
#Purpose:		Get all powered off VMs with tag "delete" on their names and delete what's relevant	#
#Explanation:	Line 24 - Read the user credentials to log in to vCenter Server;					#
#				Change to your credential file's location and name (must be created before using)	#
#				Lines 26-27 - Disconnect from any already connected vCenter Server to clear the		#
#				session; if there's no current	connections, omit the error message and continue	#
#				Lines 29-30 - Connect to the vCenter Server specified on the $vCenter variable;		#
#				use the credentials previously loaded												#
#				Lines 32-33 - Get all powered off VMs with "delete" in their name; Export the list	#
#				of VM Names to a text file for review; Change the file name and path accordingly	#
#				REVIEW THE TEXT FILE BEFORE CONTINUING, LEAVE ONLY THE VMS THAT NEED TO BE DELETED	#
#				Line 37 - Reload the text file (after manual manipulation) containing the VMs to be	#
#				deleted permanently																	#
#				Lines 39-44 - Calculate the amount of space that will be reclaimed after deleting	#
#				the VMS and write the output (number of VMs and total space) for review				#
#				Lines 46-49 - Delete all the VMs on the list; command will promt for each one before#
#				actually deleting; if no prompt is needed, append the flag "-confirm:$false" to the	#
#				end of line 48																		#
#																									#
#################################MAY THE SCRIPTING FORCE BE WITH YOU#################################

$credentials = Import-CliXml -Path "C:\Users\918842605\Downloads\Scripts\SFSU\pscred.xml"

try {Disconnect-VIServer * -Confirm:$false}
catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.VimException]{}

$vCenter = "vc01.ops.sfsu.edu"
Connect-VIServer $vCenter -Credential $credentials

$taggedVMs = Get-VM | Where {($_.name -like "*delete*") -and ($_.PowerState -like "PoweredOff")}
$taggedVMs.Name | Out-File "C:\Users\918842605\Downloads\Scripts\SFSU\DeleteByVMs.ps1"

###MANUAL MANIPULATION OF THE FILE BEFORE CONTINUING###

$vms2delete = Get-Content "C:\Users\918842605\Downloads\Scripts\SFSU\DeleteByVMs.ps1"

$reclamableSpace = 0
foreach ($vm in $vms2delete){
    $reclamableSpace += [int](Get-VM $vm | foreach {$_.UsedSpaceGB})
}

Write-Host "Number of VMs that will be deleted:"$vms2delete.Count"`nTotal space that will be reclaimed:"$reclamableSpace"GB"

foreach ($vm in $vms2delete){
    Write-Host "Deleting:"$vm
    $vm | Remove-VM -DeletePermanently
}