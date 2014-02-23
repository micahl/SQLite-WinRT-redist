param($installPath, $toolsPath, $package, $project)
  $SQLiteVersion = '3.8.3.1'
  $SQLiteSDKIdentity = "SQLite.WinRT81, Version=$SQLiteVersion"
  $SQLiteSDKName = 'SQLite for Windows Runtime (Windows 8.1)'
  $VCLibsSDKIdentity = 'Microsoft.VCLibs, version=12.0'
  $VCLibsSDKName = 'Microsoft Visual C++ 2013 Runtime Package for Windows'

  # Need to load MSBuild assembly if it's not loaded yet.
  Add-Type -AssemblyName 'Microsoft.Build, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a'

  # Grab the loaded MSBuild project for the project
  $msbuild = [Microsoft.Build.Evaluation.ProjectCollection]::GlobalProjectCollection.GetLoadedProjects($project.FullName) | Select-Object -First 1

  # Grab the target framework version and identifier from the loaded MSBuild proect
  $targetPlatformVersion = $msbuild.Xml.Properties | Where-Object { $_.Name.Equals("TargetPlatformVersion") } | Select-Object -First 1

  # Fail unless the project is targeting the Windows platform v8.1 or higher
  $version = [System.Version]::Parse($targetPlatformVersion.Value.TrimStart('v'))
  if ($version.CompareTo([System.Version]::Parse('8.1')) -lt 0)
  {
    throw "Targeted platform version 'v$version' is less than the requisite 'v8.1'"
  }

  $vcLibsSDKReference = $project.Object.References.Find($VCLibsSDKIdentity)
  if (!$vcLibsSDKReference)
  {
    # Add the VC runtime SDK reference to the project (required to pass store certification when using SQLite)
    $vcLibsReferenceNode = $project.Object.References.AddSDK($VCLibsSDKName, $VCLibsSDKIdentity)
    if (!$vcLibsReferenceNode)
    {
      throw "Unable to add the Extension SDK $VCLibsSDKName"
    }
  }

  # If someone already has the SQLite for Windows Runtime (Windows 8.1) Extension SDK installed,
  # then use it when adding a reference to the project and gracefully uninstall this package as
  # it would be unnecessary duplication.
  $sqliteSDKReferenceNode = $project.Object.References.Find($SQLiteSDKIdentity)
  if (!$sqliteSDKReferenceNode)
  {
    try {
      $sqliteLibsReference = $project.Object.References.AddSDK($SQLiteSDKName, $SQLiteSDKIdentity)
    } catch [Exception] { }

    if ($sqliteLibsReference)
    {
      Write-Host "Successfully referenced the $SQLiteSDKName Extension SDK.  Uninstalling this package."
      Uninstall-Package $package.Id
      return
    }
  }

  Write-Host "$SQLiteSDKName is not installed"
  Write-Host "This package will provide the redistributable binaries as well as update build logic to include the required flavor of 'sqlite3.dll' as part of the build output."
