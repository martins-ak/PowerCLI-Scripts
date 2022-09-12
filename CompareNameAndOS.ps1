#####################################################################################################
#																									#
#Created By:	Martin Aides-Klok																	#
#Purpose:		Compares the vCenter Name (display name) + OS with the Guest Name (Hostname) + OS	#
#Explanation:	Line 30 - Read the user credentials to log in to vCenter Server;					#
#				Change to your credential file's location and name (must be created before using)	#
#				Lines 32-33 - Disconnect from any already connected vCenter Server to clear the		#
#				session; if there's no current	connections, omit the error message and continue	#
#				Lines 35-36 - Connect to the vCenter Server specified on the $vCenter variable;		#
#				use the credentials previously loaded												#
#				Lines 38 - Gets the vCenter Name, Hostname, vCenter OS and Guest OS for all running	#
#				VMs in the vCenter; Hostname and Guest OS can be retrieved only if VMware Tools are	#
#				installed and running (i.e: will not work for powered off VMs)						#
#				Lines 40-68 - Run for each powered on VM and compare vCenter Name with Hostname;	#
#				Output only those who are different + those who couldn't be compared				#
#				Lines 46-55 - If the VM hostname is a FQDN, get the substring containing only the	#
#				name and then compare it to the vCenter name and report if different				#
#				Lines 57-61 - If the VM hostname is NOT a FQDN, compare it to the vCenter name and	#
#				report if different																	#
#				Lines 63-67 - If the VM hostname is blank (couldn't be retrieved), report that		#
#				VMware Tools for said VM are not installed/not running								#
#				Lines 70-87 - Run for each powered on VM and compare vCenter OS and Guest OS; For	#
#				Linux VMs, these will usually be different and can be ignored						#
#				Lines 76-80 - Compare vCenter OS and Guest OS and report if different				#
#				Lines 82-86 - If the Guest OS is blank (couldn't be retrieved), report that	VMware	#
#				Tools for said VM are not installed/not running										#
#																									#
#################################MAY THE SCRIPTING FORCE BE WITH YOU#################################

$credentials = Import-CliXml -Path "C:\Users\918842605\Downloads\Scripts\SFSU\pscred.xml"

try {Disconnect-VIServer * -Confirm:$false}
catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.VimException]{}

$vCenter = "vc01.ops.sfsu.edu"
Connect-VIServer $vCenter -Credential $credentials

$comparison = Get-VM | where {$_.PowerState -like "PoweredOn"} | select @{N="vCenterName";E={$_.Name}},@{N="HostName";E={$_.ExtensionData.Guest.HostName}},@{N="vCenterOS";E={$_.ExtensionData.Config.GuestFullName}},@{N="GuestOS";E={$_.ExtensionData.Guest.GuestFullName}}

foreach ($vm in $comparison){
    
    $vmHostname = $vm.HostName
    
    if ($vmHostname -notlike ""){
    
        if($vmHostname -like "*.*"){
    
            $pos = ($vm.HostName).IndexOf(".")
            $vmHostname = ($vm.HostName).Substring(0,$pos)
    
            if($vm.vCenterName -ne $vmHostname){
    
                Write-Host "Different vCenter Name and Hostname for" $vm.vCenterName "/" $vmHostname
    
            }
    
        }elseif($vm.vCenterName -ne $vmHostname){
    
            Write-Host "Different vCenter Name and Hostname for" $vm.vCenterName "/" $vmHostname
    
        }

    }else{
    
        Write-Host "VMware Tools are not installed/not running for" $vm.vCenterName "- cannot retrieve hostname"
    
    }
}

foreach ($vm in $comparison){
    
    $vmOS = $vm.GuestOS
    
    if ($vmOs -notlike ""){
    
        if($vm.vCenterOS -ne $vmOS){
    
            Write-Host "Different vCenter OS and Guest OS for" $vm.vCenterName ":" $vm.vCenterOS "/" $vmOS
    
        }

    }else{

            Write-Host "VMware Tools are not installed/not running for" $vm.vCenterName "- cannot retrieve hostname"
    
    }
}