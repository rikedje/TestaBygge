
Properties {
    $build_script_dir = Split-Path $psake.build_script_file
    $project_name = "TestaBygge"
	$root_dir = "$build_script_dir\.."
    $nuget_spec = Join-Path $root_dir "$project_name.nuspec"
    $designated_versionNumber = (Get-Date -format yyyy.MM.dd.HHmm).ToString()
    $octo_apiKey = $env:OCTOKEY_LOCAL
    $octo_serverUrl = "http://localhost:8088"
}

Task default -Depends CreateNugetPackage

Task Deploy -Depends PushNugetPackageToOctopusDeploy

Task Clean {
    Remove-Item $build_script_dir\*.nupkg -force
}

Task CreateNugetPackage -Depends Clean {
  Update-NuspecVersionNumber
  $nuget_exe = (Get-ChildItem "$build_script_dir\tools\NuGet.exe" | Select-Object -First 1)
  $cmd = "$nuget_exe pack $nuget_spec -NoPackageAnalysis"
  $sb = [ScriptBlock]::Create($cmd)
  Exec $sb
}

Task PushNugetPackageToOctopusDeploy -Depends CreateNugetPackage {
  $nuget_exe = (Get-ChildItem "$build_script_dir\tools\NuGet.exe" | Select-Object -First 1)
  $octopus_package = (Get-ChildItem "$build_script_dir\*.nupkg" | Select-Object -Last 1)
  
  "Publishing $octopus_package to $octo_serverUrl/nuget/packages"
  $cmd = "$nuget_exe push $octopus_package -ApiKey $octo_apiKey -Source $octo_serverUrl/nuget/packages"
  $sb = [ScriptBlock]::Create($cmd)
  Exec $sb
}

function Update-NuspecVersionNumber {
  # update nuget spec version number
  "Updating versionnumber to $designated_versionNumber"
  [xml]$spec = Get-Content $nuget_spec -Encoding UTF8
  $spec.package.metadata.version = $designated_versionNumber
  Set-ItemProperty $nuget_spec IsReadOnly $false
  $spec.Save($nuget_spec)
}
