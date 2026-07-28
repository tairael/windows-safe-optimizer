$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'TestHelpers.ps1')

$temporaryParent = Join-Path $repositoryRoot '.tmp'
$temporaryParentExisted = Test-Path -LiteralPath $temporaryParent
$testRoot = Join-Path $temporaryParent 'runner-empty-suite'
if (Test-Path -LiteralPath $testRoot) {
    Remove-Item -LiteralPath $testRoot -Recurse -Force
}

try {
    New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
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
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
    if (-not $temporaryParentExisted -and (Test-Path -LiteralPath $temporaryParent) -and @(Get-ChildItem -LiteralPath $temporaryParent -Force).Count -eq 0) {
        Remove-Item -LiteralPath $temporaryParent -Force
    }
}

'TEST RUNNER EMPTY-SUITE GUARD PASSED'
