$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'TestHelpers.ps1')

$markerPath = Join-Path $repositoryRoot '.public-source-root'
Assert-True (Test-Path -LiteralPath $markerPath -PathType Leaf) 'Public source root marker is missing'
Assert-Equal 'windows-safe-optimizer-public-source-v1' ((Get-Content -LiteralPath $markerPath -Raw).Trim()) 'Public source root marker is invalid'
Assert-Equal 'windows-safe-optimizer' (Split-Path -Leaf $repositoryRoot) 'Unexpected public source root directory'
Assert-Equal '03-源文件' (Split-Path -Leaf (Split-Path -Parent $repositoryRoot)) 'Public source root is outside 03-源文件'
Assert-True (Test-Path -LiteralPath (Join-Path $repositoryRoot '.git')) 'Public source root is not an independent Git repository'

$gitRoot = (& git -C $repositoryRoot rev-parse --show-toplevel).Trim()
Assert-Equal ([IO.Path]::GetFullPath($repositoryRoot).TrimEnd('\', '/')) ([IO.Path]::GetFullPath($gitRoot).TrimEnd('\', '/')) 'Git top-level is not the public source root'
Assert-Equal 'main' ((& git -C $repositoryRoot branch --show-current).Trim()) 'Public source repository must use the main branch'

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

$trackedFiles = @(& git -C $repositoryRoot ls-files)
foreach ($relativePath in $trackedFiles) {
    foreach ($pattern in $blockedPatterns) {
        Assert-True ($relativePath -notmatch $pattern) "Internal evidence is tracked for public release: $relativePath"
    }
}

"PUBLIC SOURCE BOUNDARY PASSED: scanned $($publicFiles.Count) files and $($trackedFiles.Count) tracked release paths under $repositoryRoot"
