$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'TestHelpers.ps1')
. (Join-Path $PSScriptRoot 'TestRunnerSandboxHelpers.ps1')

$pathProbeCommand = Get-Command 'Assert-TestRunnerPathProbe' -ErrorAction SilentlyContinue
Assert-True ($null -ne $pathProbeCommand) 'Shared temporary-parent path probe is missing'

$probeTemporaryParent = Join-Path $repositoryRoot '.tmp'
$sentinelWriteReached = $false
$prewriteProbeRejected = $false
try {
    Assert-TestRunnerPathProbe `
        -RepositoryRoot $repositoryRoot `
        -TemporaryParent $probeTemporaryParent `
        -TemporaryParentAttributes ([IO.FileAttributes]::Directory -bor [IO.FileAttributes]::ReparsePoint)
    $sentinelWriteReached = $true
}
catch {
    $prewriteProbeRejected = $true
}
Assert-True $prewriteProbeRejected 'Pre-write guard accepted a simulated reparse-point .tmp directory'
Assert-True (-not $sentinelWriteReached) 'Sentinel write stage was reached after temporary-parent validation failed'

$cleanupProbeRejected = $false
try {
    Assert-TestRunnerPathProbe `
        -RepositoryRoot $repositoryRoot `
        -TemporaryParent $probeTemporaryParent `
        -TemporaryParentAttributes ([IO.FileAttributes]::Directory) `
        -TargetPath (Join-Path $probeTemporaryParent 'runner-empty-suite-probe') `
        -TargetAttributes ([IO.FileAttributes]::Directory -bor [IO.FileAttributes]::ReparsePoint)
}
catch {
    $cleanupProbeRejected = $true
}
Assert-True $cleanupProbeRejected 'Cleanup guard accepted a simulated reparse-point target'

$temporaryParentGuard = Initialize-TestRunnerTemporaryParent -RepositoryRoot $repositoryRoot
$temporaryParent = [string]$temporaryParentGuard.Path
$sentinelToken = [guid]::NewGuid().ToString('N')
$sentinelRoot = Join-Path $temporaryParent "runner-empty-suite-$sentinelToken"
$sentinelFile = Join-Path $sentinelRoot 'sentinel.txt'
$sentinelCreated = $false
$sandbox = $null

if (Test-Path -LiteralPath $sentinelRoot) {
    throw "Refusing to touch pre-existing sentinel fixture: $sentinelRoot"
}

try {
    New-Item -ItemType Directory -Path $sentinelRoot | Out-Null
    Set-Content -LiteralPath $sentinelFile -Value $sentinelToken -NoNewline
    $sentinelCreated = $true

    $candidateNames = [Collections.Generic.Queue[string]]::new()
    $candidateNames.Enqueue((Split-Path -Leaf $sentinelRoot))
    $candidateNames.Enqueue("runner-empty-suite-$([guid]::NewGuid().ToString('N'))")
    $sandbox = New-TestRunnerSandbox `
        -RepositoryRoot $repositoryRoot `
        -TemporaryParentGuard $temporaryParentGuard `
        -NameFactory { $candidateNames.Dequeue() }
    $testRoot = $sandbox.Path

    Assert-True ($testRoot -ne $sentinelRoot) 'Sandbox reused the pre-existing sentinel directory'
    Assert-Equal $sentinelToken (Get-Content -LiteralPath $sentinelFile -Raw) 'Sentinel changed during sandbox creation'

    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Run-AllTests.ps1') -Destination $testRoot
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'TestHelpers.ps1') -Destination $testRoot

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $testRoot 'Run-AllTests.ps1') 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    Assert-True ($exitCode -ne 0) 'Runner succeeded with zero actual test scripts'
    Assert-True (($output -join "`n") -match 'No test scripts found') 'Runner did not explain the empty test suite failure'
}
finally {
    if ($null -ne $sandbox) {
        Remove-TestRunnerSandbox -Sandbox $sandbox
    }

    if ($sentinelCreated) {
        $safeSentinelFile = Assert-TestRunnerCleanupTarget `
            -TemporaryParentGuard $temporaryParentGuard `
            -TargetPath $sentinelFile
        $safeSentinelRoot = Assert-TestRunnerCleanupTarget `
            -TemporaryParentGuard $temporaryParentGuard `
            -TargetPath $sentinelRoot
        Assert-Equal $sentinelToken (Get-Content -LiteralPath $safeSentinelFile -Raw) 'Sandbox cleanup changed the pre-existing sentinel'
        Remove-Item -LiteralPath $safeSentinelFile -Force

        $safeSentinelRoot = Assert-TestRunnerCleanupTarget `
            -TemporaryParentGuard $temporaryParentGuard `
            -TargetPath $safeSentinelRoot
        Assert-Equal 0 @(Get-ChildItem -LiteralPath $safeSentinelRoot -Force).Count 'Sentinel fixture directory is not empty'
        Remove-Item -LiteralPath $safeSentinelRoot -Force
    }

    Remove-TestRunnerTemporaryParentIfOwned -TemporaryParentGuard $temporaryParentGuard
}

'TEST RUNNER EMPTY-SUITE AND SENTINEL GUARDS PASSED'
