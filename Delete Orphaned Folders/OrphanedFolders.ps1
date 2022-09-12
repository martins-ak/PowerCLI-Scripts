#####################################################################################################
#																									#
#Created By:	Martin Aides-Klok																	#
#Purpose:		Scan all production datastores for orphaned files and folders; Delete them as needed#
#Explanation:	Line 42 - Read the user credentials to log in to vCenter Server;					#
#				Change to your credential file's location and name (must be created before using)	#
#				Lines 44-45 - Disconnect from any already connected vCenter Server to clear the		#
#				session; if there's no current	connections, omit the error message and continue	#
#				Lines 47-48 - Connect to the vCenter Server specified on the $vCenter variable;		#
#				use the credentials previously loaded												#
#																									#
#				:::Datastore-Dirs Function:::														#
#				Lines 50-86 - Function to search the folder's content on the current datastore;		#
#				This function relies on another one to retrieve all the folders with VMs/Templates	#
#				there; Results (orphaned folders) are exported to a csv file on line 82				#
#				Lines 54-63 - Get folders to scan in the current datastore and define search queries#
#				Lines 65-85 - Search each folder in the current datastore (except sytem based		#
#				folders: "HA",DVS","SSD" and "SYSLOG"); Export the results (orphaned folders) to a	#
#				csv file; Change the name and path of the file accordingly on line 82				#
#																									#
#				:::Get-VMFolderByDS Function:::														#
#				Lines 88-113 - Function that retrievess all the folders with VMs/Templates config	#
#				files on the current datastore; Folders will be analyzed on the previous function	#
#				Lines 92-100 - Get folders that host VMs config files to add them to the scan list	#
#				Lines 102-110 - Get folders that host VM Templates config files to add them to the	#
#				scan list																			#
#				Line 112 - Return the list of folders to scan to the main function					#
#																									#
#				:::Main Section:::																	#
#				Line 115 - Get all production datastores (excluding "cold"/"veeam"/"local") we want	#
#				to scan																				#
#				Lines 117-121 - Scan each loaded datastore; orphaned folders will be exported to a 	#
#				csv file from inside the "Datastore-Dirs" function (line 82)						#
#				FILES AND FOLDERS DELETION BLOCK AHEAD; REVIEW THE EXPORTED CSV FILE BEFORE			#
#				CONTINUING, LEAVE ONLY THE LINES INTENDED FOR DATA THAT WILL BE DELETED				#
#				Line 126 - Import the csv file containing the files and folders to be deleted after	#
#				reviewing and modifying it accordingly												#
#				Lines 128-134 - Delete all the folders loaded from the csv and their content		#
#																									#
#################################MAY THE SCRIPTING FORCE BE WITH YOU#################################

$credentials = Import-CliXml -Path "C:\Users\918842605\Downloads\Scripts\SFSU\pscred.xml"

try {Disconnect-VIServer * -Confirm:$false}
catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.VimException]{}

$vCenter = "vc01.ops.sfsu.edu"
Connect-VIServer $vCenter -Credential $credentials

Function Datastore-Dirs ($ds){

	Write-Host ""
    Write-Host "Searching Datastore:" $ds.Name
    $vmfolders = Get-VMFoldersByDS ($ds)
	$dsBrowser = Get-View $ds.ExtensionData.Browser
	$root = "[" + $ds.Name + "]"
	
	$searchSpec = New-Object VMware.Vim.HostDatastoreBrowserSearchSpec
	$searchSpec.details = $flags
	$searchSpec.Query += $disk
	$searchSpec.sortFoldersFirst = $true
	
	$searchResult = $dsBrowser.SearchDatastoreSubFolders($root, $searchSpec)
	
	foreach ($folder in ($searchResult | Sort-Object)){

        if (-Not($vmfolders -contains $folder.FolderPath) -and ($folder.FolderPath -NotLike '*HA*' -and $folder.FolderPath -notlike '*dvs*' -and $folder.FolderPath -notlike '*ssd*' -and $folder.FolderPath -notlike '*syslog*')){

            $pos = $folder.FolderPath.IndexOf("]")
            $folderName =  $folder.FolderPath.Substring($pos+1)

            if ($folderName.length -ne 0){

                $folderName = ((($folder.FolderPath.Substring($pos)).Trim("]")).TrimEnd("/")).Trim()
                $folderContent = [string]((Get-Childitem -Path vmstore:"SFSU Datacenter"\$ds\$folderName).Name)
                $orphanedFolders = [PSCUSTOMOBJECT]@{
                    Datastore = $ds
                    Folder = $folderName
                    Content = $folderContent
                }

                $orphanedFolders | Export-Csv "C:\Users\918842605\Downloads\Scripts\SFSU\OrphanedFolders082521.csv" -NoTypeInformation -Append
            }
		}
	}
}

Function Get-VMFoldersByDS ($ds){

	$folders = @()

	$vms = Get-VM -Datastore $ds

	foreach ($vm in $vms){

		$config_file = $vm.ExtensionData.LayoutEx.File | Where {$_.Type -eq 'config'}
		$path = ($config_file.Name.Split('/')[0] + '/')
		$folders += $path

	}
	
	$temps = Get-Template | Where {$_.DatastoreIdList -Contains $ds.Id}

	foreach ($temp in $temps){

		$config_file = $temp.ExtensionData.LayoutEx.File | Where {$_.Type -eq 'config'}
		$path = ($config_file.Name.Split('/')[0] + '/')
		$folders += $path

	}
	
	return $folders
}

$allDS = Get-Datastore | where {($_.name -notlike "*cold*") -and ($_.name -notlike "*veeam*") -and ($_.name -notlike "*local*")} | Sort-Object

foreach ($ds in $allDS){

    Datastore-Dirs ($ds)

}


#####FILES AND FOLDERS DELETE BLOCK#####

$filesToDelete = Import-Csv -Path "C:\Users\918842605\Downloads\Scripts\SFSU\OrphanedFolders082521.csv"

foreach ($dsFolder in $filesToDelete){
    
    $dsName = $dsFolder.Datastore
    $folderName = $dsFolder.Folder
    Get-Item -Path vmstore:"SFSU Datacenter"\$dsName\$folderName | Remove-Item -Recurse

}

#####FILES AND FOLDERS DELETE BLOCK#####