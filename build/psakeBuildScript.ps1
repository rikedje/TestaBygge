
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
  rm $build_script_dir\*.nupkg -force
}

Task CreateNugetPackage -Depends Clean {
  Update-NuspecVersionNumber
  $nuget_exe = (Get-ChildItem "$build_script_dir\tools\NuGet.exe" | Select-Object -First 1)
  Exec { &$nuget_exe "pack" $nuget_spec -NoPackageAnalysis }
}

Task PushNugetPackageToOctopusDeploy -Depends CreateNugetPackage {
  $nuget_exe = (Get-ChildItem "$build_script_dir\tools\NuGet.exe" | Select-Object -First 1)
  $octopus_package = (Get-ChildItem "$root_dir\*.nupkg" | Select-Object -Last 1)
  
  Write-Host "Publish $octopus_package to $octo_serverUrl/nuget/packages"
  Exec { &$nuget_exe push $octopus_package -ApiKey $octo_apiKey -Source $octo_serverUrl/nuget/packages }
}

function Update-NuspecVersionNumber {
  # update nuget spec version number
  [xml] $spec = gc $nuget_spec -enc UTF8
  $spec.package.metadata.version = $designated_versionNumber
  sp $nuget_spec IsReadOnly $false
  $spec.Save($nuget_spec)
}
