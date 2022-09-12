#####################################################################################################
#																									#
#Created By:	Martin Aides-Klok																	#
#Purpose:		Upgrade VMware Tools on an existing list of VMs + check status afterwards			#
#Explanation:	Line 21 - Read the user credentials to log in to vCenter Server;					#
#				Change to your credential file's location and name (must be created before using)	#
#				Lines 23-24 - Disconnect from any already connected vCenter Server to clear the		#
#				session; if there's no current	connections, omit the error message and continue	#
#				Lines 26-27 - Connect to the vCenter Server specified on the $vCenter variable;		#
#				use the credentials previously loaded												#
#				Lines 29 - Retrieve list of VMs to upgrade VM Tools; must be created beforehand;	#
#				Exact name of the VMs needed; One VM Name per line									#
#				Lines 31-40 - Run for each of VM on the loaded list; Create a snapshot and upgrade 	#
#				VMware Tools															 	 	 	#
#				Lines 35-38 - Double-check that VM Tools version is NOT current on the VM; 	 		#
#				then take a snapshot and then upgrade asynchronously; Snapshot won't be deleted here#
#				Line 42-44 - Check the VM Tools version status on the list of VMs previously loaded	#
#																									#
#################################MAY THE SCRIPTING FORCE BE WITH YOU#################################

$credentials = Import-CliXml -Path "C:\Users\918842605\Downloads\Scripts\SFSU\pscred.xml"

try {Disconnect-VIServer * -Confirm:$false}
catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.VimException]{}

$vCenter = "vc01.ops.sfsu.edu"
Connect-VIServer $vCenter -Credential $credentials

$vmsToUpg = Get-Content "C:\Users\918842605\Downloads\Scripts\SFSU\UpgVMTools.txt"

foreach ($singleVM in $vmsToUpg){
    
    $vm = Get-VM $singleVM
    
    if ($vm.ExtensionData.Guest.ToolsVersionStatus -ne "guestToolsCurrent"){
        $vm | New-Snapshot -Name "Before VMTools Upgrade"
        $vm | Update-Tools -Verbose -RunAsync
    }

}

foreach ($singleVM in $vmsToUpg){
    Get-VM $singleVM | select Name,@{N=“ToolsVersion”;E={$_.ExtensionData.Config.Tools.ToolsVersion}},@{N=“ToolStatus”;E={$_.ExtensionData.Guest.ToolsVersionStatus}} | Sort-Object Name
}