# TPP Operations 

See the [README](./README.md) for getting started information.

## Removing medium privacy outputs
All outputs are put into the high privacy directory of a workspace on L3. Outputs that have been marked as having a lower privacy level are then copied into the appropriate directory (i.e at the moment only the medium privacy directory).

Medium privacy outputs are copied from L3 to L4 every five minutes by a sync script controlled by TPP. *Note: this sync script is unidirectional, so any changes to L4 are not reflected back on L3.*

There are times when these medium privacy outputs may need to be deleted. For example, the researcher or output checkers may realise they should have been marked as high privacy, or the researcher may no longer need the output and want to preserve disk space.

To remove a medium privacy output:
1. On L3, as the jobrunner user
    1. Browse to `/srv/medium_privacy/workspaces/{workspace name}/output`.
    2. Delete the file
2. On L4 (after deleting the file from L3)
    1. Browse to `D:\Level4Files\workspaces\{workspace name}\output`
    2. Permanently delete the file (using SHIFT+DEL or by emptying the recycle bin after deleting normally).

