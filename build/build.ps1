param($task = "default")

$scriptPath = $MyInvocation.MyCommand.Path

if(!$scriptPath) {
    $scriptPath = Convert-Path ./build/build.ps1
}

$scriptDir = Split-Path $scriptPath
$packagesDir = Join-Path $scriptDir packages

$nuget_exe="$scriptDir\tools\NuGet.exe"

get-module psake | remove-module

& $nuget_exe install $scriptDir\packages.config -OutputDirectory $packagesDir 2>&1

# Import the psake module
$psakeModulePath = (Get-ChildItem "$packagesDir\psake.*\tools\psake.psm1" | Select-Object -First 1)
import-module $psakeModulePath

# Run psake with our own build script
invoke-psake "$scriptDir\psakeBuildScript.ps1" $task
