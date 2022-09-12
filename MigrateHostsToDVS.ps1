$esxs = Get-Cluster QA | Get-VMHost | where {$_.Name -notlike "znestesx02.zerto.local"}

foreach($esx in $esxs){
Get-VDSwitch vDSwitch | Add-VDSwitchVMHost -VMHost $esx
$nic = Get-VMHostNetworkAdapter -VMHost $esx -Name "vmnic1"
$vnic1 = Get-VMHostNetworkAdapter -VMHost $esx -Name "vmk0"
$vnic2 = Get-VMHostNetworkAdapter -VMHost $esx -Name "vmk1"
$pg1 = Get-VDSwitch vDSwitch | Get-VDPortgroup Management
$pg2 = Get-VDSwitch vDSwitch | Get-VDPortgroup iSCSI-Vlan353
Add-VDSwitchPhysicalNetworkAdapter -VMHostPhysicalNic $nic -VMHostVirtualNic $vnic1,$vnic2 -DistributedSwitch vDSwitch -VirtualNicPortgroup $pg1,$pg2 -Confirm:$false
}


$vms = import-csv "C:\Users\ran.nova\Desktop\PG1.csv"

foreach($vm in $vms){
Get-VM $vm.name | Get-NetworkAdapter -Name $vm.nic | Set-NetworkAdapter -Portgroup $vm.newnet -Confirm:$false
}





foreach($esx in $esxs){
$nic = Get-VMHostNetworkAdapter -VMHost $esx -Name "vmnic2"
Add-VDSwitchPhysicalNetworkAdapter -VMHostPhysicalNic $nic -DistributedSwitch vDSwitch -Confirm:$false
Remove-VDSwitchVMHost -VDSwitch vDS -VMHost $esx -Confirm:$false
}


