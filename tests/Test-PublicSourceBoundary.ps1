$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'TestHelpers.ps1')

$markerPath = Join-Path $repositoryRoot '.public-source-root'
Assert-True (Test-Path -LiteralPath $markerPath -PathType Leaf) 'Public source root marker is missing'
Assert-Equal 'windows-safe-optimizer-public-source-v1' ((Get-Content -LiteralPath $markerPath -Raw).Trim()) 'Public source root marker is invalid'
Assert-Equal 'windows-safe-optimizer' (Split-Path -Leaf $repositoryRoot) 'Unexpected public source root directory'
Assert-Equal '03-源文件' (Split-Path -Leaf (Split-Path -Parent $repositoryRoot)) 'Public source root is outside 03-源文件'

$blockedPatterns = @(
    '(^|[\\/])05-测试与验证([\\/]|$)',
    '(^|[\\/])\.superpowers([\\/]|$)',
    'task-1-report',
    'skill-baseline-results',
    'skill-baseline-scenarios'
)

$publicFiles = Get-ChildItem -LiteralPath $repositoryRoot -Recurse -Force -File |
    Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' }

foreach ($file in $publicFiles) {
    $relativePath = $file.FullName.Substring($repositoryRoot.Length).TrimStart('\', '/')
    foreach ($pattern in $blockedPatterns) {
        Assert-True ($relativePath -notmatch $pattern) "Internal evidence is inside the public source root: $relativePath"
    }
}

"PUBLIC SOURCE BOUNDARY PASSED: scanned $($publicFiles.Count) files under $repositoryRoot"
