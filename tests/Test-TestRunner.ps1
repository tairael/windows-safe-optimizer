$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'TestHelpers.ps1')
. (Join-Path $PSScriptRoot 'TestRunnerSandboxHelpers.ps1')

$temporaryParent = Join-Path $repositoryRoot '.tmp'
$temporaryParentExisted = Test-Path -LiteralPath $temporaryParent
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
    $sandbox = New-TestRunnerSandbox -RepositoryRoot $repositoryRoot -NameFactory { $candidateNames.Dequeue() }
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
        Assert-True (Test-Path -LiteralPath $sentinelFile -PathType Leaf) 'Sandbox cleanup removed the pre-existing sentinel'
        Assert-Equal $sentinelToken (Get-Content -LiteralPath $sentinelFile -Raw) 'Sandbox cleanup changed the pre-existing sentinel'
        Remove-Item -LiteralPath $sentinelFile -Force
        Remove-Item -LiteralPath $sentinelRoot -Force
    }

    if (-not $temporaryParentExisted -and (Test-Path -LiteralPath $temporaryParent) -and @(Get-ChildItem -LiteralPath $temporaryParent -Force).Count -eq 0) {
        Remove-Item -LiteralPath $temporaryParent -Force
    }
}

'TEST RUNNER EMPTY-SUITE AND SENTINEL GUARDS PASSED'
