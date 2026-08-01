$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'TestHelpers.ps1')

$scriptFiles = Get-ChildItem -LiteralPath $repositoryRoot -Recurse -File -Filter '*.ps1'
foreach ($scriptFile in $scriptFiles) {
    $bytes = [System.IO.File]::ReadAllBytes($scriptFile.FullName)
    $hasUtf8Bom = $bytes.Length -ge 3 -and
        $bytes[0] -eq 0xEF -and
        $bytes[1] -eq 0xBB -and
        $bytes[2] -eq 0xBF
    $hasNonAsciiBytes = @($bytes | Where-Object { $_ -gt 0x7F }).Count -gt 0

    Assert-True (-not $hasNonAsciiBytes -or $hasUtf8Bom) (
        "PowerShell 5.1 requires UTF-8 BOM for non-ASCII script text: {0}" -f
        $scriptFile.FullName.Substring($repositoryRoot.Length + 1)
    )
}

'PASS: PowerShell source encoding contract'
