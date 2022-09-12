#####################################################################################################
#																									#
#Created By:	Martin Aides-Klok																	#
#Purpose:		Change the repository location for VMware Tools										#
#Explanation:	Line 26 - Read the user credentials to log in to vCenter	Server;					#
#				Change to your credential file's location and name (must be created before using)	#
#				Lines 28-29 - Disconnect from any already connected vCenter Server to clear the		#
#				session; if there's no current	connections, omit the error message and continue	#
#				Lines 31-32 - Connect to the vCenter Server specified on the $vCenter variable;		#
#				use the credentials previously loaded												#
#				Lines 34-35 - Specify the name of the Datastore where the new VMTools Repository is	#
#				located and load it	to the $ds variable												#
#				Lines 37-38 - Specify the name of the folder in the above Datastore where the		#
#				VMware Tools files were uploaded to (must be done before continuing) and define the	#
#				new	location path																	#
#				Line 40 - Get all the ESXi host on $vCenter to change their repository location		#
#				Lines 42-51 - Run for each of the ESXi Hosts, backup the old repository location and#
#				change it to the new one															#
#				Lines 44-45 - Backup the old repository paths, located locally on each host;		#
#				change the csv path accordingly														#
#				Line 47 - Change the repository location to the one defined previously				#
#				Line 49 - Write to console to keep track of which host was modified					#
#																									#
#################################MAY THE SCRIPTING FORCE BE WITH YOU#################################

$credentials = Import-CliXml -Path "C:\Users\918842605\Downloads\Scripts\SFSU\pscred.xml"

try {Disconnect-VIServer * -Confirm:$false}
catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.VimException]{}

$vCenter = "vc01.ops.sfsu.edu"
Connect-VIServer $vCenter -Credential $credentials

$dsName = 'datastore-lun133-cold-storage'
$ds = Get-Datastore -Name $dsName

$dsFolder = 'VMToolsRepo'
$newLocation = "/$($ds.ExtensionData.Info.Url.TrimStart('ds:/'))$dsFolder"

$allEsxHosts = Get-VMHost

foreach ($esxHost in $allEsxHosts){
    
    $oldLocation = $esxHost.ExtensionData.QueryProductLockerLocation()
    echo $esxHost.Name,$oldLocation >> "C:\Users\918842605\Downloads\Scripts\SFSU\VMTools Repo Files\VMToolsOldLocation.csv"
    
    $esxHost.ExtensionData.UpdateProductLockerLocation($newLocation)
    
    Write-Host $esxHost " VMTools repository moved from:: " $oldLocation " to:: " $newLocation

}