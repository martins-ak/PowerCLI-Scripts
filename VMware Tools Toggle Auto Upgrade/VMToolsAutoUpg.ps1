#####################################################################################################
#																									#
#Created By:	Martin Aides-Klok																	#
#Purpose:		Enable/Disable VMTools Auto-Upgrade on VMs (checks if needed upon reboot)			#
#Explanation:	Line 20 - Read the user credentials to log in to vCenter Server;					#
#				Change to your credential file's location and name (must be created before using)	#
#				Lines 22-23 - Disconnect from any already connected vCenter Server to clear the		#
#				session; if there's no current	connections, omit the error message and continue	#
#				Lines 25-26 - Connect to the vCenter Server specified on the $vCenter variable;		#
#				use the credentials previously loaded												#
#				Lines 28 - Get the list of VMs for which we want to enable/disable Auto-Upgrade;	#
#				create the file beforehand and adjust the location and name accordingly				#
#				Lines 30-37 - Run for each of the VMs, set the new configuration and apply it		#
#				Lines 31-34 - Set the configuration to Auto-Upgrade at a VM power cycle;			#
#               To disable Auto-Upgrade, change "UpgradeAtPowerCycle" on line ## to "manual"		#
#				Line 36 - Apply the new configuration to the current VM								#
#																									#
#################################MAY THE SCRIPTING FORCE BE WITH YOU#################################

$credentials = Import-CliXml -Path "C:\Users\918842605\Downloads\Scripts\SFSU\pscred.xml"

try {Disconnect-VIServer * -Confirm:$false}
catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.VimException]{}

$vCenter = "vc01.ops.sfsu.edu"
Connect-VIServer vc01.ops.sfsu.edu -Credential $credentials

$vmsToChange = Get-Content "C:\Users\918842605\Downloads\Scripts\SFSU\Annotated\VMware Tools\VMware Tools Toggle Auto Upgrade\VMToolsAutoUpg.txt"

foreach ($singleVM in $vmsToChange){
    $vmConfig = Get-View -VIObject $singleVM
    $vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
    $vmConfigSpec.Tools = New-Object VMware.Vim.ToolsConfigInfo
    $vmConfigSpec.Tools.ToolsUpgradePolicy = "UpgradeAtPowerCycle"
    Write-Host "Enabling/Disabling Auto-Upgrade of VMware Tools on: $singleVM"
    $vmConfig.ReconfigVM($vmConfigSpec)
}