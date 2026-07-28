$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'TestHelpers.ps1')

$required = @(
    'skills\windows-safe-optimizer\SKILL.md',
    'skills\windows-safe-optimizer\agents\openai.yaml',
    'skills\windows-safe-optimizer\scripts',
    'skills\windows-safe-optimizer\references',
    'tests\Run-AllTests.ps1',
    '.public-source-root'
)

foreach ($relativePath in $required) {
    Assert-True (Test-Path -LiteralPath (Join-Path $repositoryRoot $relativePath)) "Missing required path: $relativePath"
}
