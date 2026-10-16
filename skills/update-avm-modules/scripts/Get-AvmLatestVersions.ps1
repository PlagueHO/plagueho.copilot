<#
.SYNOPSIS
Query stable MCR versions once per unique module and return every reference as JSON.
.PARAMETER BicepFile
A Bicep file. Alternatively, supply Directory or Files.
.EXAMPLE
./Get-AvmLatestVersions.ps1 -Files infra/main.bicep,infra/other.bicep
#>
[CmdletBinding(DefaultParameterSetName = 'File')]
param(
    [Parameter(Mandatory, ParameterSetName = 'File')][string]$BicepFile,
    [Parameter(Mandatory, ParameterSetName = 'Directory')][string]$Directory,
    [Parameter(Mandatory, ParameterSetName = 'List')][string[]]$Files
)
$ErrorActionPreference = 'Stop'
$arguments = switch ($PSCmdlet.ParameterSetName) {
    'File' { @('--file', $BicepFile) }
    'Directory' { @('--directory', $Directory) }
    'List' { @('--files') + $Files }
}
& node (Join-Path $PSScriptRoot 'avm.mjs') latest @arguments
exit $LASTEXITCODE
