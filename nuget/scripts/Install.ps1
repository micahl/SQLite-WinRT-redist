param($installPath, $toolsPath, $package, $project)
  $sqliteVSIXUrl = 'http://www.sqlite.org/2014/sqlite-winrt81-3080401.vsix'
  $SQLiteVersion = '3.8.4.1'
  $SQLiteSDKIdentity = 'SQLite.WinRT81'
  $SQLiteSDKIdentityVer = "$SQLiteSDKIdentity, Version=$SQLiteVersion"
  $SQLiteSDKName = 'SQLite for Windows Runtime (Windows 8.1)'
  $VCLibsSDKIdentity = 'Microsoft.VCLibs, version=12.0'
  $VCLibsSDKName = 'Microsoft Visual C++ 2013 Runtime Package for Windows'
  $tmpVSIXFile = Join-Path $env:TEMP (Split-Path -leaf $sqliteVSIXUrl)
  $vsixinstaller = Join-Path $env:VS120COMNTOOLS '..\IDE\vsixinstaller.exe'

  Write-Host $installPath
  Write-Host $toolsPath
  Write-Host $package
  Write-Host $project

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

  $isUpgrade = $false
  # If someone already has the SQLite for Windows Runtime (Windows 8.1) Extension SDK installed,
  # then use it when adding a reference to the project and gracefully uninstall this package as
  # it would be unnecessary duplication.
  # Otherwise, download, install it, and remove this package.
  $extMgrAssembly = [appdomain]::currentdomain.getassemblies() | where-object { $_.FullName.StartsWith("Microsoft.VisualStudio.ExtensionManager") } | Select-Object -First 1
  $svsExtMgr = $extMgrAssembly.GetType("Microsoft.VisualStudio.ExtensionManager.SVsExtensionManager")
  $extMgrSvc = Get-VSService($svsExtMgr)
  #$sqliteSDKReferenceNode = $project.Object.References.Find($SQLiteSDKIdentityVer)
  $sqliteSDKReferenceNode = $project.Object.References | Where-Object { $_.Name -eq $SQLiteSDKName } | Select-Object -First 1
  $sqliteSDKExt = $null
#if ($sqliteSDKReferenceNode)
#{
    if ($sqliteSDKReferenceNode.Version -ne $SQLiteVersion)
    {
        if ($sqliteSDKReferenceNode.Version)
        {
          # An existing version of the SDK is installed.  Is the project using it?  Only verified the latest isn't being used.
          #$extMgrSvc.TryGetInstalledExtension($SQLiteSDKIdentity, [REF]$sqliteSDKExt) -and $sqliteSDKExt)
          Write-Host "Upgrading from version " $sqliteSDKReferenceNode.Version " to $SQLiteVersion."
          $isUpgrade = $true
        }
    }

    if ($extMgrSvc.TryGetInstalledExtension($SQLiteSDKIdentity, [REF]$sqliteSDKExt))
    {
      Write-Host "$SQLiteSDKName is already installed."
    }
    else
    {
#}
#if (!$sqliteSDKReferenceNode)
#{
#if (!$extMgrSvc.TryGetInstalledExtension($SQLiteSDKIdentity, [REF]$sqliteSDKExt))
#{
      try {
        # download the VSIX from SQLite
        $client = new-object System.Net.WebClient
        $client.DownloadFile($sqliteVSIXUrl, $tmpVSIXFile)
      } catch [Exception] {
        Write-Host "Failed to download the $SQLiteSDKName Extension SDK."
      }

      # install it
      $process = Start-Process $vsixinstaller $tmpVSIXFile -Wait -PassThru
      if ($process.ExitCode -ne 0)
      {
        Write-Host $process.ExitCode
        throw "Failed to install $SQLiteSDKName Extension SDK."
      }

      # Need a way to verify install happened. If someone cancels out of vsixinstaller it doesn't return an error code.
      <#
      [System.Threading.Thread]::Sleep(1000) #bad, i know
      #>
      if (!$extMgrSvc.TryGetInstalledExtension($SQLiteSDKIdentity, [REF]$sqliteSDKExt))
      {
        Write-Host $sqliteSDKExt
        #throw "$SQLiteSDKName installation was canceled."
      }

      # cleanup
      Remove-Item $tmpVSIXFile
#}
    }

    try {
      if ($isUpgrade) { $sqliteSDKReferenceNode.Remove() }
      $sqliteLibsReference = $project.Object.References.AddSDK($SQLiteSDKName, $SQLiteSDKIdentityVer)
      # If the reference is unresolved with no path then assume it isn't installed
      if ($sqliteLibsReference -and $sqliteLibsReference.Resolved -and $sqliteLibsReference.Path)
      {
        Write-Host "Successfully installed $SQLiteSDKName Extension SDK.  Uninstalling this package."
        Uninstall-Package $package.Id
        return
      }
    } catch [Exception] { }

    if ($sqliteLibsReference -and (!$sqliteLibsReference.Resolved -or !$sqliteLibsReference.Path))
    {
      $sqliteLibsReference.Remove()  # Cleanup orphaned reference
      throw "Failed to install $SQLiteSDKName."
    }

    # Success?... uninstall gracefully
    Uninstall-Package $package.Id
#}
