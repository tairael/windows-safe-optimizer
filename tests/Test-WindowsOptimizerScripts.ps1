$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot 'TestHelpers.ps1')
. (Join-Path $PSScriptRoot 'TestRunnerSandboxHelpers.ps1')

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $repositoryRoot 'skills\windows-safe-optimizer\scripts\Test-WindowsOptimizerEnvironment.ps1'

function Invoke-EnvironmentScript {
    param([Parameter(Mandatory = $true)][string]$OutputDirectory)

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $scriptPath -OutputDirectory $OutputDirectory -AsJson 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    return [pscustomobject]@{
        Output = $output
        ExitCode = $exitCode
    }
}

function Assert-OutputDirectoryRejected {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Description
    )

    $invocation = Invoke-EnvironmentScript -OutputDirectory $Path
    Assert-True ($invocation.ExitCode -ne 0) "Unsafe output directory was accepted: $Description"
}

Assert-True (Test-Path -LiteralPath $scriptPath) 'Environment script is missing'

$temporaryParentGuard = Initialize-TestRunnerTemporaryParent -RepositoryRoot $repositoryRoot
$sandbox = $null
try {
    $sandbox = New-TestRunnerSandbox -RepositoryRoot $repositoryRoot -TemporaryParentGuard $temporaryParentGuard
    $testOutput = Join-Path $sandbox.Path 'output'
    New-Item -ItemType Directory -Path $testOutput | Out-Null

    $successfulInvocation = Invoke-EnvironmentScript -OutputDirectory $testOutput
    Assert-Equal 0 $successfulInvocation.ExitCode 'Environment script failed for a normal existing directory'
    $resultJson = $successfulInvocation.Output | Out-String
    $result = $resultJson | ConvertFrom-Json

    Assert-Equal '1.0' $result.schemaVersion 'Unexpected environment schema'
    Assert-True ($null -ne $result.supportedOS) 'supportedOS missing'
    Assert-True ($result.outputDirectory -eq [IO.Path]::GetFullPath($testOutput)) 'Output path was not normalized'
    Assert-Equal $false ([bool]$result.outputDirectoryIsReparsePoint) 'Normal output directory was reported as a reparse point'
    foreach ($field in @('productName', 'displayVersion', 'buildNumber', 'powerShellVersion', 'isAdministrator', 'warnings')) {
        Assert-True ($result.PSObject.Properties.Name -contains $field) "Environment field is missing: $field"
    }

    Assert-OutputDirectoryRejected -Path ([IO.Path]::GetPathRoot($testOutput)) -Description 'volume root'
    Assert-OutputDirectoryRejected -Path $env:windir -Description 'Windows directory'
    Assert-OutputDirectoryRejected -Path $env:ProgramFiles -Description 'Program Files directory'
    Assert-OutputDirectoryRejected -Path ([Environment]::GetFolderPath('UserProfile')) -Description 'profile root'

    $missingDirectory = Join-Path $sandbox.Path 'does-not-exist'
    Assert-True (-not (Test-Path -LiteralPath $missingDirectory)) 'Missing-directory fixture already exists'
    Assert-OutputDirectoryRejected -Path $missingDirectory -Description 'nonexistent directory'
    Assert-True (-not (Test-Path -LiteralPath $missingDirectory)) 'Environment script created a nonexistent output directory'

    $reparseTarget = Join-Path $sandbox.Path 'reparse-target'
    $reparsePath = Join-Path $sandbox.Path 'reparse-output'
    New-Item -ItemType Directory -Path $reparseTarget | Out-Null
    New-Item -ItemType Junction -Path $reparsePath -Target $reparseTarget | Out-Null
    $reparseItem = Get-Item -LiteralPath $reparsePath -Force
    Assert-True (($reparseItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) 'Reparse fixture is not a reparse point'
    Assert-OutputDirectoryRejected -Path $reparsePath -Description 'reparse point'
    Assert-True (Test-Path -LiteralPath $reparsePath) 'Environment script removed the reparse fixture'
}
finally {
    if ($null -ne $sandbox) {
        Remove-TestRunnerSandbox -Sandbox $sandbox
    }
    else {
        Remove-TestRunnerTemporaryParentIfOwned -TemporaryParentGuard $temporaryParentGuard
    }
}

'PASS: Windows optimizer environment inspection'
