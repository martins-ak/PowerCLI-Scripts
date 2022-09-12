#####################################################################################################
#																									#
#Created By:	Martin Aides-Klok																	#
#Purpose:		Get location information for VMs, and move if needed. Addresses 3 scenarios:		#
#				(a) VMs tagged as "dev" or "test" running on a production cluster					#
#				(b) Powered on VMs that are running on "cold" datastores							#
#				(c) VMs tagged as "delete" running on production cluster/regular datastores			#
#Explanation:	Line 32 - Read the user credentials to log in to vCenter Server;					#
#				Change to your credential file's location and name (must be created before using)	#
#				Lines 34-35 - Disconnect from any already connected vCenter Server to clear the		#
#				session; if there's no current	connections, omit the error message and continue	#
#				Lines 37-38 - Connect to the vCenter Server specified on the $vCenter variable;		#
#				use the credentials previously loaded												#
#				Lines 40 - Get the Dev/Test cluster													#
#	(a)																								#
#				Lines 44 - Get all VMs in the production cluster with the tag "dev" or "test" in	#
#				their name, except for: veeam/ob18/fabs												#
#				Lines 46-50 - Move these Dev/Test VMs to the Dev/Test cluster						#
#	(b)																								#
#				Line 58 - Get all the running (powered on) VMs on "cold" storage datastores			#
#				Lines 60-72 - Move these VMs one by one to the regular datastore with the maximum	#
#				amount of free space, but only if the datastore has enough space to host the VM		#
#	(c)																								#
#				Lines 80-81 - Get all VMs with the "delete" tag on their name that are running on	#
#				regular datastores (not "cold") and on production clusters (not dev/test)			#
#				Lines 83-87 - Move these VMs to the Dev/Test cluster								#
#				Lines 89-101 - Move these VMs one by one to the "cold" datastore with the maximum	#
#				amount of free space, but only if the datastore has enough space to host the VM		#
#																									#
#################################MAY THE SCRIPTING FORCE BE WITH YOU#################################

$credentials = Import-CliXml -Path "C:\Users\918842605\Downloads\Scripts\SFSU\pscred.xml"

try {Disconnect-VIServer * -Confirm:$false}
catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.VimException]{}

$vCenter = "vc01.ops.sfsu.edu"
Connect-VIServer $vCenter -Credential $credentials

$devTestClu = Get-Cluster -Name "SFSU_Dev_Test_Cluster"

###MOVE DEV/TEST VMS FROM PROD CLUSTER###

$moveVMs = Get-Cluster | where {$_.Name -like "SFSU_Production_Cluster"} | Get-VM | where {(($_.Name -notlike "*veeam*") -and ($_.Name -notlike "*ob18*") -and ($_.Name -notlike "*fabs*")) -and (($_.Name -like "*dev*") -or ($_.Name -like "*test*"))}

foreach ($onevm in $moveVMs){

    $onevm | Move-VM -Destination $devTestClu

}

###MOVE DEV/TEST VMS FROM PROD CLUSTER###

#

###MOVE POWERED ON VMS FROM *COLD* DATASTORES###

$runsOnCold = Get-VM | where {($_.Name -notlike "*delete*") -and ($_.PowerState -like "PoweredOn") -and ($_.ExtensionData.Config.Files.VmPathName -like "*cold*")}

foreach ($onevm in $runsOnCold){

    $regDS = Get-Datastore | where {$_.Name -notlike "*cold*"}
    $maxSpaceDS = ($regDS | measure-object -Property FreeSpaceGB -maximum).maximum
    $biggerRegDS = $regDS | ? { $_.FreeSpaceGB -eq $maxSpaceDS}

    if ($onevm.ProvisionedSpaceGB -le $biggerRegDS.FreeSpaceGB){

        $onevm | Move-VM -Datastore $biggerRegDS

    }

}

###MOVE POWERED ON VMS FROM *COLD* DATASTORES###

#

###MOVE "DELETE" TAGGED VMS###

$deleteByDS = Get-VM | where {($_.name -like "*delete*") -and ($_.ExtensionData.Config.Files.VmPathName -notlike "*cold*")}
$deleteByClu = Get-VM | where {($_.name -like "*delete*") -and ($_.VMHost.Parent -notlike $devTestClu)}

foreach ($onevm in $deleteByClu){

    $onevm | Move-VM -Destination $devTestClu

}

foreach ($onevm in $deleteByDS){

    $coldDS = Get-Datastore | where {$_.Name -like "*cold*"}
    $maxSpaceDS = ($coldDS | measure-object -Property FreeSpaceGB -maximum).maximum
    $biggerColdDS = $coldDS | ? { $_.FreeSpaceGB -eq $maxSpaceDS}

    if ($onevm.ProvisionedSpaceGB -le $biggerColdDS.FreeSpaceGB){

        $onevm | Move-VM -Datastore $biggerColdDS

    }

}

###MOVE "DELETE" TAGGED VMS###