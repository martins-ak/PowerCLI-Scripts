- VMToolsRepo includes two folders that are needed for Upgrade: floppies and vmtools.

- VMToolsRepo currently includes the files for VMware Tools version 11.3.0 (latest as of 2021-06-17).

- VMToolsRepo folder can be found at [datastore-lun133-cold-storage] and it's the current directory that all ESXi host pinpoint too (instead of the default folder in the local storage for each host).

- When a new version of VMware Tools is available (independently of the version of the ESXi hosts, it should be downloaded and the folder+files copied over to the VMToolsRepo on [datastore-lun133-cold-storage]

- VMToolsOldLocation.csv contains the original (default) path of the VMware Tools repository fodler located on each ESXi host.

- VMToolsChangeRepo.ps1 is the script that changes the repository from the default (local) location, to the centralized (external) location on th [datastore-lun133-cold-storage] datastore. More information can be found inline the script file.

- Before running the script, make sure to copy the VMware Tools files (located in a folder, e.g: VMToolsRepo) to the location which will serve as the centralized repository for all hosts, e.g: [datastore-lun133-cold-storage] VMToolsRepo/