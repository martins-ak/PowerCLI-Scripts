#####################################################################################################
#																									#
#Created By:	Martin Aides-Klok																	#
#Purpose:		Get list of Snapshots older than 14 days and delete them; Can be automated			#
#Explanation:	Line 20 - Read the user credentials to log in to vCenter Server;					#
#				Change to your credential file's location and name (must be created before using)	#
#				Lines 22-23 - Disconnect from any already connected vCenter Server to clear the		#
#				session; if there's no current	connections, omit the error message and continue	#
#				Lines 25-26 - Connect to the vCenter Server specified on the $vCenter variable;		#
#				use the credentials previously loaded												#
#				Line 28 - Get the list of all VMs on the vCenter, except veeam related ones			#
#				Lines 30-37 - Get all the snapshots older than 14 days created on the loaded VMs;	#
#				Show the VM's Name and power state, the Snapshot's Name, Description, Age and Size;	#
#				Display it in a table view sorted by the Age										#
#				Lines 39-41 - Run for each of the Snapshots that were previously retieved and delete#
#				them asynchronously; If needed to run one by one, remove the "-RunAsync" flag		#
#																									#
#################################MAY THE SCRIPTING FORCE BE WITH YOU#################################

$credentials = Import-CliXml -Path "C:\Users\918842605\Downloads\Scripts\SFSU\pscred.xml"

try {Disconnect-VIServer * -Confirm:$false}
catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.VimException]{}

$vCenter = "vc01.ops.sfsu.edu"
Connect-VIServer $vCenter -Credential $credentials

$allVMs = Get-VM | Where {$_.name -notlike "veeam*"}

$ssDetails = $allVMs | Get-Snapshot | Where {$_.Created -lt (Get-Date).AddDays(-14)} | Select @{N="VM Name";E={$_.VM}},
                                                                                              @{N="VM PowerState";E={$_.VM.PowerState}},
                                                                                              @{N="SS Name";E={$_.Name}},
                                                                                              @{N="SS Description";E={$_.Description}},
                                                                                              @{N="SS Age (Days)";E={((Get-Date) - $_.Created).days}},
                                                                                              @{N="SS Size (GB)";E={"{0:N2}" -f ($_.SizeGB)}}

$ssDetails | Sort-Object -Descending "SS Age (Days)" | Format-Table -AutoSize

foreach ($ss in $ssDetails){
    get-vm -Name $ss.'VM Name' | Get-Snapshot -Name $ss.'SS Name' | Remove-Snapshot -Confirm:$false -RunAsync
}