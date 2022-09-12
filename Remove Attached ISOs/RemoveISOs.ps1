#####################################################################################################
#																									#
#Created By:	Martin Aides-Klok																	#
#Purpose:		Detaches the currently attached ISOs from the CD-Drive on a list of VMs				#
#Explanation:	Line 51 - Read the user credentials to log in to vCenter Server;					#
#				Change to your credential file's location and name (must be created before using)	#
#				Lines 53-54 - Disconnect from any already connected vCenter Server to clear the		#
#				session; if there's no current	connections, omit the error message and continue	#
#				Lines 56-57 - Connect to the vCenter Server specified on the $vCenter variable;		#
#				use the credentials previously loaded												#
#																									#
#				:::Datastore-Dirs Function:::														#
#				Lines 59-111 - Function that detaches the ISO from a given VM; If the Guest OS of	#
#				the VM is locking the drive, answer the question to override the lock				#
#				Lines 62-67 - Define the function parameters and to accept values from pipeline;	#
#				Parameter Name - the display name of the VM; Parameter Server - The VC on which the	#
#				VM is located (default is $global:defaultviserver which we are connecting in Main)	#
#				Lines 69-98 - Define the function Begin section (the preprocessing block), including#
#				the background While Loop that waits to answer the VM Question to override the		#
#				CD-Drive lock (if needed)															#
#				Lines 74-75 - Initialize the counter parameters to set the max number of runs		#
#				(seconds) to wait for the question to appear; Currently set to 15					#
#				Line 77 - Reuse the open vSphere Server connection with the SessionSecret property	#
#				Lines 79-92 - The background While loop that waits for the VM Question to appear and#
#				answers it; will runs until it eithers answers it or 15 seconds have passed			#
#				Line 81 - Check that the question matches the locked cd-rom issue					#
#				Lines 83-91 - Answer the question, overriding the lock; Set the counter parameters	#
#				to exit the loop																	#
#				Lines 95-97 - If no VC name was passed on the Server parameter, the script will use	#
#				the default connection ($global:defaultviserver) established outside the function	#
#				Lines 100-110 - Defining the Process block that includes:							#
#				(a) Call for the background job to check for the question and answer it				#
#				(b) The actual detach command that removes the ISO using the NoMedia switch			#
#				Line 106 - Start background job defined in the Begin block, waiting for the question#
#				to override the lock to pop-up, or 15 seconds (the first to occur)					#
#				Line 108 - The actual detach command; if a VM question is triggered to override the	#
#				lock, it will be answered by the background job										#
#																									#
#				:::Main Section:::																	#
#				Line 113 - Get all the VMs in the vCenter											#
#				Lines 115-119 - Search all the VMs and export to a csv file all those with attached	#
#				ISOs, including the VM's name, the CD-Drive name and the ISO path+name (for review);#
#				Change the name and path of the file accordingly									#
#				REVIEW THE EXPORTED CSV FILE BEFORE	CONTINUING, LEAVE ONLY THE LINES INCLUDING THE	#
#				VMS FOR WHICH THE ISOS WILL BE DETACHED												#
#				Line 121 - Import the csv file containing the VMs that will have their ISOs detached#
#				Lines 123-129 - Send each of the VMs from the file to the Remove-ISO function		#
#																									#
#################################MAY THE SCRIPTING FORCE BE WITH YOU#################################

$credentials = Import-CliXml -Path "C:\Users\918842605\Downloads\Scripts\SFSU\pscred.xml"

try {Disconnect-VIServer * -Confirm:$false}
catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.VimException]{}

$vCenter = "vc01.ops.sfsu.edu"
Connect-VIServer $vCenter -Credential $credentials

function Remove-ISO
{

    [CmdletBinding()]
    param(
    [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
    [string[]]$Name,
    [PSObject]$Server
    )
    
    Begin
    {
        $cdQuestion = {
            param($VmName,$vServer)
            
            $maxPass = 15
            $pass = 0
            
            Connect-VIServer -Server $vServer.Name  -Session $vServer.SessionSecret | Out-Null

            while($pass -lt $maxPass){

                $question = Get-VM -Name $VmName | Get-VMQuestion -QuestionText "*locked the CD-ROM*"

                if($question){

                    Set-VMQuestion -VMQuestion $question -Option button.yes -Confirm:$false
                    $pass = $maxPass + 1

                }

                $pass++
                Start-Sleep 1
            }
        }
        
        if(!$Server){
            $Server = $global:DefaultVIServer
        }
    }
    
    Process
    {
        $Name | %{
        $vm = Get-VM -Name $_
        $cd = Get-CDDrive -VM $vm

        $job = Start-Job -Name Check-CDQuestion -ScriptBlock $cdQuestion -ArgumentList $_,$Server

        Set-CDDrive -CD $cd -NoMedia -Confirm:$false -ErrorAction Stop
        }
    }
}

$allVMs = Get-VM

foreach ($onevm in $allVMs){

    Get-CDDrive -VM $onevm.name | where {$_.IsoPath -notlike ""} | select @{N="VM Name";E={$onevm.Name}},@{N="Drive Name";E={$_.Name}},IsoPath | Export-Csv -NoTypeInformation "C:\Users\918842605\Downloads\Scripts\SFSU\VMsWithISOs.csv" -Append

}

$vmsWithISO = import-csv "C:\Users\918842605\Downloads\Scripts\SFSU\VMsWithISOs.csv"

foreach ($isoVM in $vmsWithISO){
    
    $vm = $isoVM.'VM Name'
    Write-Host "Removing ISO from"$vm
    Remove-ISO $vm

}