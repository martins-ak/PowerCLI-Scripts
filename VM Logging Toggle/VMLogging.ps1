#####################################################################################################
#																									#
#Created By:	Martin Aides-Klok																	#
#Purpose:		Change the repository location for VMware Tools										#
#Explanation:	Line 25 - Read the user credentials to log in to vCenter Server;					#
#				Change to your credential file's location and name (must be created before using)	#
#				Lines 27-28 - Disconnect from any already connected vCenter Server to clear the		#
#				session; if there's no current	connections, omit the error message and continue	#
#				Lines 30-31 - Connect to the vCenter Server specified on the $vCenter variable;		#
#				use the credentials previously loaded												#
#				Lines 33-34 - Identify all the VMs with the "Enable Logging" flag unchecked;		#
#				Export the name of said VMs to a text file - change the path accordingly;			#
#	>>>>>>>		Modify file to include only relevant VMs to be modified - they will be powered off!	#
#				Line 38 - Get all the VMs to be modified from the same text file exported (and 		#
#				modified, if needed) - change the path accordingly									#
#				Lines 40-42 - Create the configuration to change the flag to enable VM Logging;		#
#				To disable, change the flag to $false in line 42									#
#				Lines 46-55 - Run for every VM in the list loaded before; Change the configuration	#
#				Line 48-49 - Try to gracefully shut	down the VM, if that fails - power it off		#
#				Line 51 - Change the VM Logging flag configuration									#
#				Line 53 - Power on the VM															#
#																									#
#################################MAY THE SCRIPTING FORCE BE WITH YOU#################################

$credentials = Import-CliXml -Path "C:\Users\918842605\Downloads\Scripts\SFSU\pscred.xml"

try {Disconnect-VIServer * -Confirm:$false}
catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.VimException]{}

$vCenter = "vc01.ops.sfsu.edu"
Connect-VIServer $vCenter -Credential $credentials

$logDisabledVMs = Get-VM | where {$_.ExtensionData.Config.Flags.EnableLogging -like "False"}
$logDisabledVMs.Name | Out-File -FilePath "C:\Users\918842605\Downloads\Scripts\SFSU\VM Logging Toggle\VMLoggingToggle.txt"

####CHECK/TWEEK FILE BEFORE CONTINUING!###

$toggleVM = Get-Content -Path "C:\Users\918842605\Downloads\Scripts\SFSU\VM Logging Toggle\VMLoggingToggle.txt"

$spec = New-Object VMware.Vim.VirtualMachineConfigSpec
$spec.Flags = New-Object VMware.Vim.VirtualMachineFlagInfo
$spec.Flags.EnableLogging = $true

###VMS WILL BE SHUT DOWN/POWERED OFF!###

foreach ($singleVM in $toggleVM){

    try {$vm | Shutdown-VMGuest -Confirm:$false -ErrorAction Stop}
    catch {$vm | Stop-VM -Confirm:$false}

    $singleVM | %{$_.Extensiondata.ReconfigVM($spec)}

    $singleVM | Start-VM

}