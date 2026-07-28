$ErrorActionPreference = 'Stop'
$testFiles = Get-ChildItem -LiteralPath $PSScriptRoot -File -Filter 'Test-*.ps1' |
    Where-Object { $_.Name -ne 'TestHelpers.ps1' } |
    Sort-Object Name

if (@($testFiles).Count -eq 0) {
    throw "No test scripts found in $PSScriptRoot"
}

foreach ($testFile in $testFiles) {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $testFile.FullName
    if ($LASTEXITCODE -ne 0) { throw "Test failed: $($testFile.Name)" }
}

'ALL TESTS PASSED'
