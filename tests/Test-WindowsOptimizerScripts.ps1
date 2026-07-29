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

    return [pscustomobject]@{ Output = $output; ExitCode = $exitCode }
}

function Get-PathSnapshot {
    param([Parameter(Mandatory = $true)][string]$Path)

    $fullPath = [IO.Path]::GetFullPath($Path)
    if (-not (Test-Path -LiteralPath $fullPath)) {
        return [pscustomobject]@{ Path = $fullPath; Exists = $false; Attributes = $null; LastWriteTimeUtc = $null; ChildCount = $null }
    }

    $item = Get-Item -LiteralPath $fullPath -Force -ErrorAction Stop
    $childCount = $null
    if ($item.PSIsContainer) {
        $childCount = @(Get-ChildItem -LiteralPath $fullPath -Force -ErrorAction Stop).Count
    }
    return [pscustomobject]@{
        Path = $fullPath
        Exists = $true
        Attributes = [int]$item.Attributes
        LastWriteTimeUtc = $item.LastWriteTimeUtc.Ticks
        ChildCount = $childCount
    }
}

function Assert-PathSnapshotUnchanged {
    param(
        [Parameter(Mandatory = $true)][psobject]$Before,
        [Parameter(Mandatory = $true)][psobject]$After,
        [Parameter(Mandatory = $true)][string]$Description
    )

    foreach ($property in @('Path', 'Exists', 'Attributes', 'LastWriteTimeUtc', 'ChildCount')) {
        Assert-Equal $Before.$property $After.$property "Output path changed during rejected inspection ($Description): $property"
    }
}

function Assert-OutputDirectoryRejectedWithoutMutation {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Description
    )

    $before = Get-PathSnapshot -Path $Path
    $invocation = Invoke-EnvironmentScript -OutputDirectory $Path
    $after = Get-PathSnapshot -Path $Path
    Assert-True ($invocation.ExitCode -ne 0) "Unsafe output directory was accepted: $Description"
    Assert-PathSnapshotUnchanged -Before $before -After $after -Description $Description
}

function Get-CaseAndTrailingSeparatorVariant {
    param([Parameter(Mandatory = $true)][string]$Path)

    $fullPath = [IO.Path]::GetFullPath($Path).ToUpperInvariant()
    if (-not $fullPath.EndsWith([string][IO.Path]::DirectorySeparatorChar)) {
        $fullPath += [IO.Path]::DirectorySeparatorChar
    }
    return $fullPath
}

Assert-True (Test-Path -LiteralPath $scriptPath) 'Environment script is missing'

$temporaryParentGuard = Initialize-TestRunnerTemporaryParent -RepositoryRoot $repositoryRoot
$sandbox = $null
$reparsePath = $null
$ancestorLink = $null
try {
    $sandbox = New-TestRunnerSandbox -RepositoryRoot $repositoryRoot -TemporaryParentGuard $temporaryParentGuard
    $testOutput = Join-Path $sandbox.Path 'output'
    New-Item -ItemType Directory -Path $testOutput | Out-Null

    . $scriptPath -OutputDirectory $testOutput | Out-Null
    Assert-True ($null -ne (Get-Command 'Test-SupportedWindowsProductName' -ErrorAction SilentlyContinue)) 'Product-name support predicate is missing'
    Assert-True (Test-SupportedWindowsProductName -ProductName 'Windows 10 Pro') 'Windows 10 should be supported'
    Assert-True (Test-SupportedWindowsProductName -ProductName 'Windows 11 Home') 'Windows 11 should be supported'
    Assert-Equal $false (Test-SupportedWindowsProductName -ProductName 'Windows Server 2022 Datacenter') 'Windows Server must not be supported'
    Assert-Equal $false (Test-SupportedWindowsProductName -ProductName 'Ubuntu 24.04') 'Non-Windows product must not be supported'

    $validBefore = Get-PathSnapshot -Path $testOutput
    $successfulInvocation = Invoke-EnvironmentScript -OutputDirectory $testOutput
    $validAfter = Get-PathSnapshot -Path $testOutput
    Assert-Equal 0 $successfulInvocation.ExitCode 'Environment script failed for a normal existing directory'
    Assert-PathSnapshotUnchanged -Before $validBefore -After $validAfter -Description 'normal directory'
    $resultJson = $successfulInvocation.Output | Out-String
    $result = $resultJson | ConvertFrom-Json

    Assert-Equal '1.0' $result.schemaVersion 'Unexpected environment schema'
    Assert-True ($null -ne $result.supportedOS) 'supportedOS missing'
    Assert-True ($result.outputDirectory -eq [IO.Path]::GetFullPath($testOutput)) 'Output path was not normalized'
    Assert-Equal $false ([bool]$result.outputDirectoryIsReparsePoint) 'Normal output directory was reported as a reparse point'
    foreach ($field in @('productName', 'displayVersion', 'buildNumber', 'powerShellVersion', 'isAdministrator', 'warnings')) {
        Assert-True ($result.PSObject.Properties.Name -contains $field) "Environment field is missing: $field"
    }

    Assert-OutputDirectoryRejectedWithoutMutation -Path ([IO.Path]::GetPathRoot($testOutput).ToLowerInvariant()) -Description 'volume root with case variation'
    Assert-OutputDirectoryRejectedWithoutMutation -Path (Get-CaseAndTrailingSeparatorVariant -Path $env:windir) -Description 'Windows directory with case and trailing separator'
    Assert-OutputDirectoryRejectedWithoutMutation -Path (Get-CaseAndTrailingSeparatorVariant -Path $env:ProgramFiles) -Description 'Program Files directory with case and trailing separator'
    Assert-OutputDirectoryRejectedWithoutMutation -Path (Get-CaseAndTrailingSeparatorVariant -Path ([Environment]::GetFolderPath('UserProfile'))) -Description 'profile root with case and trailing separator'

    $missingDirectory = Join-Path $sandbox.Path 'does-not-exist'
    Assert-OutputDirectoryRejectedWithoutMutation -Path $missingDirectory -Description 'nonexistent directory'

    $reparseTarget = Join-Path $sandbox.Path 'reparse-target'
    $reparsePath = Join-Path $sandbox.Path 'reparse-output'
    New-Item -ItemType Directory -Path $reparseTarget | Out-Null
    New-Item -ItemType Junction -Path $reparsePath -Target $reparseTarget | Out-Null
    $reparseItem = Get-Item -LiteralPath $reparsePath -Force
    Assert-True (($reparseItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) 'Reparse fixture is not a reparse point'
    Assert-OutputDirectoryRejectedWithoutMutation -Path $reparsePath -Description 'endpoint reparse point'

    $ancestorTarget = Join-Path $sandbox.Path 'ancestor-target'
    $ancestorLink = Join-Path $sandbox.Path 'ancestor-link'
    $ancestorChild = Join-Path $ancestorTarget 'child'
    New-Item -ItemType Directory -Path $ancestorChild -Force | Out-Null
    New-Item -ItemType Junction -Path $ancestorLink -Target $ancestorTarget | Out-Null
    $ancestorItem = Get-Item -LiteralPath $ancestorLink -Force
    Assert-True (($ancestorItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) 'Ancestor reparse fixture is not a reparse point'
    $ancestorTargetBefore = Get-PathSnapshot -Path $ancestorTarget
    $ancestorInvocation = Invoke-EnvironmentScript -OutputDirectory (Join-Path $ancestorLink 'child')
    $ancestorTargetAfter = Get-PathSnapshot -Path $ancestorTarget
    Assert-True ($ancestorInvocation.ExitCode -ne 0) 'Unsafe output directory was accepted: descendant of ancestor reparse point'
    Assert-PathSnapshotUnchanged -Before $ancestorTargetBefore -After $ancestorTargetAfter -Description 'ancestor reparse target'
}
finally {
    foreach ($linkPath in @($reparsePath, $ancestorLink)) {
        if ($null -ne $linkPath -and (Test-Path -LiteralPath $linkPath)) {
            $linkItem = Get-Item -LiteralPath $linkPath -Force
            if (($linkItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                [IO.Directory]::Delete($linkPath, $false)
                Assert-True (-not (Test-Path -LiteralPath $linkPath)) "Owned junction cleanup failed: $linkPath"
            }
        }
    }

    if ($null -ne $sandbox) {
        Remove-TestRunnerSandbox -Sandbox $sandbox
    }
    else {
        Remove-TestRunnerTemporaryParentIfOwned -TemporaryParentGuard $temporaryParentGuard
    }
}

'PASS: Windows optimizer environment inspection'
