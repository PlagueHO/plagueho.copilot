<#
.SYNOPSIS
Compile Bicep without creating or deleting adjacent ARM templates.
.PARAMETER BicepFile
A Bicep file. Alternatively, supply Directory or Files.
.EXAMPLE
./Test-BicepBuild.ps1 -BicepFile infra/main.bicep
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
& node (Join-Path $PSScriptRoot 'avm.mjs') build @arguments
exit $LASTEXITCODE
