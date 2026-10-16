<#
.SYNOPSIS
Apply an approved update array and save a complete rollback snapshot.
.PARAMETER Updates
Inline JSON. Alternatively, supply UpdatesFile.
.PARAMETER SnapshotFile
A new snapshot path outside the target files. Existing snapshots are not overwritten.
.EXAMPLE
./Update-AvmVersions.ps1 -UpdatesFile updates.json -SnapshotFile snapshot.json
#>
[CmdletBinding(DefaultParameterSetName = 'Inline')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Inline')][string]$Updates,
    [Parameter(Mandatory, ParameterSetName = 'File')][string]$UpdatesFile,
    [Parameter(Mandatory)][string]$SnapshotFile
)
$ErrorActionPreference = 'Stop'
$arguments = if ($PSCmdlet.ParameterSetName -eq 'File') { @('--file', $UpdatesFile) } else { @('--updates', $Updates) }
& node (Join-Path $PSScriptRoot 'avm.mjs') update @arguments --snapshot-file $SnapshotFile
exit $LASTEXITCODE
