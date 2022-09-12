#####################################################################################################
#																									#
#Created By:	Martin Aides-Klok																	#
#Purpose:		Retrieve all the VMs with some/all annotations missing and set values accordingly	#
#Explanation:	Line 23 - Read the user credentials to log in to vCenter Server;					#
#				Change to your credential file's location and name (must be created before using)	#
#				Lines 25-26 - Disconnect from any already connected vCenter Server to clear the		#
#				session; if there's no current	connections, omit the error message and continue	#
#				Lines 28-29 - Connect to the vCenter Server specified on the $vCenter variable;		#
#				use the credentials previously loaded												#
#				Lines 31 - Get the list of all VMs on the vCenter									#
#				Lines 33-46 - Run for each VM and retrieve the value of each attribute; If any of	#
#				the attributes is empty, export the VM Name and all the attribute values to a csv	#
#				file; Adjust the file name and path accordingly on each line 37-39					#
#				BE SURE TO FILL THE CSV FILE VALUES BEFORE CONTINUING AND RELOADING IT WITH THE 	#
#				RELEVANT DATA; DO NOT CHANGE THE FORMAT OF THE FILE'S CONTENT; IF THERE'S AND/OR	#
#				VALUES YOU DON'T WANT TO UPDATE, REMOVE THE RELEVANT LINES FROM THE FILE			#
#				Line 50 - Reload the csv file with the updated values for each VM					#
#				Lines 52-57 - Run for each VM and update the values for each attribute from the file#
#																									#
#################################MAY THE SCRIPTING FORCE BE WITH YOU#################################

$credentials = Import-CliXml -Path "C:\Users\918842605\Downloads\Scripts\SFSU\pscred.xml"

try {Disconnect-VIServer * -Confirm:$false}
catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.VimException]{}

$vCenter = "vc01.ops.sfsu.edu"
Connect-VIServer $vCenter -Credential $credentials

$vmList = Get-VM

foreach ($singleVM in $vmList){
    
    $attr1 = ($singleVM | Get-Annotation | where {$_.name -like "Contact(s)"}).Value
    $attr2 = ($singleVM | Get-Annotation | where {$_.name -like "Description"}).Value
    $attr3 = ($singleVM | Get-Annotation | where {$_.name -like "Team"}).Value

    if (($attr1 -eq "") -or ($attr2 -eq "") -or ($attr3 -eq "")){

        $singleVM | Get-Annotation | where {$_.name -like "Contact(s)"} | Select @{N="VM Name";E={$_.AnnotatedEntity}},@{N="Attribute";E={$_.Name}},Value | Export-Csv "C:\Users\918842605\Downloads\Scripts\SFSU\Missing Details VM List.csv" -NoTypeInformation -Append 
        $singleVM | Get-Annotation | where {$_.name -like "Description"} | Select @{N="VM Name";E={$_.AnnotatedEntity}},@{N="Attribute";E={$_.Name}},Value | Export-Csv "C:\Users\918842605\Downloads\Scripts\SFSU\Missing Details VM List.csv" -NoTypeInformation -Append
        $singleVM | Get-Annotation | where {$_.name -like "Team"} | Select @{N="VM Name";E={$_.AnnotatedEntity}},@{N="Attribute";E={$_.Name}},Value | Export-Csv "C:\Users\918842605\Downloads\Scripts\SFSU\Missing Details VM List.csv" -NoTypeInformation -Append

    }
}

###MANIPULATE EXPORTED CSV FILE BEFORE CONTINUING###

$vmListAndDets = Import-Csv "C:\Users\918842605\Downloads\Scripts\SFSU\Missing Details VM List.csv"

foreach ($singleVM in $vmListAndDets){

    $vm = Get-VM $singleVM."VM Name"
    $vm | Set-Annotation -CustomAttribute $singleVM.Attribute -Value $singleVM.Value

}