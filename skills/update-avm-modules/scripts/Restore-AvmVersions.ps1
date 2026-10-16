<#
.SYNOPSIS
Restore a complete AVM update batch unless a target contains later edits.
.PARAMETER SnapshotFile
The snapshot produced by Update-AvmVersions.
.EXAMPLE
./Restore-AvmVersions.ps1 -SnapshotFile snapshot.json
#>
[CmdletBinding()]
param([Parameter(Mandatory)][string]$SnapshotFile)
$ErrorActionPreference = 'Stop'
& node (Join-Path $PSScriptRoot 'avm.mjs') restore --snapshot-file $SnapshotFile
exit $LASTEXITCODE
