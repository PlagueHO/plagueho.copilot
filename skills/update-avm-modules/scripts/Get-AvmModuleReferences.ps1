<#
.SYNOPSIS
Extract active AVM declarations as a JSON array using the shared Node.js implementation.
.PARAMETER BicepFile
A Bicep file. Alternatively, supply Directory or Files.
.EXAMPLE
./Get-AvmModuleReferences.ps1 -Directory infra
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
& node (Join-Path $PSScriptRoot 'avm.mjs') references @arguments
exit $LASTEXITCODE
