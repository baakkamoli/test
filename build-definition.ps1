Properties {

    # This number will be used to replace the * in all versions of all libraries.
    # This should be overwritten by a CI system like VSTS, AppVeyor, TeamCity, ...
    $VersionSuffix = ""

    # The build configuration used for compilation
    $BuildConfiguration = "Release"

    # The folder in which all output artifacts should be placed
    $ArtifactsPath = "artifacts"

    if ($env:APPVEYOR -eq "True") {
        if ($env:APPVEYOR_REPO_TAG -ne "true") {
            $VersionSuffix = "preview-" + $env:APPVEYOR_BUILD_NUMBER.PadLeft(4, '0')
        } elseif ($env:APPVEYOR_REPO_TAG_NAME.Contains("-")) {
            $VersionSuffix = $env:APPVEYOR_REPO_TAG_NAME.SubString(6) # i.e. the part after "-"
        }
    }
}

Task Default -depends init, dotnet-restore, dotnet-build, dotnet-test

Task init {

    Write-Host "VersionSuffix: $VersionSuffix"
    Write-Host "BuildConfiguration: $BuildConfiguration"

    Assert ($VersionSuffix -ne $null) "Property 'VersionSuffix' may not be null."
    Assert ($BuildConfiguration -ne $null) "Property 'BuildConfiguration' may not be null."
}


Task dotnet-restore {

    exec { dotnet restore -v Minimal }
}

Task dotnet-build {

    if ($VersionSuffix.Length -gt 0) {
        exec { dotnet build -c $BuildConfiguration --version-suffix $VersionSuffix }
    } else {
        exec { dotnet build -c $BuildConfiguration }
    }
}

Task dotnet-test {

    $testFailed = $false

    # Find all projects that are directly under the tests folder

    Get-ChildItem -Path "test\**\*.csproj" | ForEach-Object {

      Write-Host ""
      Write-Host "Testing $library"
      Write-Host ""

      dotnet test $_.FullName -c $BuildConfiguration --no-build

      if ($LASTEXITCODE -ne 0) {
          $testFailed = $true
      }
    }

    if ($testFailed) {
        throw "Tests for at least one library failed"
    }
}