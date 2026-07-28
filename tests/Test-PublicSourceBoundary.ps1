$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'TestHelpers.ps1')
. (Join-Path $PSScriptRoot 'PublicSourceBoundaryHelpers.ps1')

$markerPath = Join-Path $repositoryRoot '.public-source-root'
Assert-True (Test-Path -LiteralPath $markerPath -PathType Leaf) 'Public source root marker is missing'
Assert-Equal 'windows-safe-optimizer-public-source-v1' ((Get-Content -LiteralPath $markerPath -Raw).Trim()) 'Public source root marker is invalid'
Assert-Equal 'windows-safe-optimizer' (Split-Path -Leaf $repositoryRoot) 'Unexpected public source root directory'
Assert-Equal '03-源文件' (Split-Path -Leaf (Split-Path -Parent $repositoryRoot)) 'Public source root is outside 03-源文件'
Assert-True (Test-Path -LiteralPath (Join-Path $repositoryRoot '.git')) 'Public source root is not an independent Git repository'

$gitRoot = (& git -C $repositoryRoot rev-parse --show-toplevel).Trim()
Assert-Equal ([IO.Path]::GetFullPath($repositoryRoot).TrimEnd('\', '/')) ([IO.Path]::GetFullPath($gitRoot).TrimEnd('\', '/')) 'Git top-level is not the public source root'
Assert-Equal 'main' ((& git -C $repositoryRoot branch --show-current).Trim()) 'Public source repository must use the main branch'

$rootEntry = Get-Item -LiteralPath $repositoryRoot -Force
$publicEntries = @(Get-PublicSourceEntries -RepositoryRoot $repositoryRoot)
Assert-PublicFileSystemEntriesAllowed -RepositoryRoot $repositoryRoot -Entries @($rootEntry)
Assert-PublicFileSystemEntriesAllowed -RepositoryRoot $repositoryRoot -Entries $publicEntries

$trackedFiles = @(& git -C $repositoryRoot ls-files)
Assert-PublicTrackedPathsAllowed -RelativePaths $trackedFiles

"PUBLIC SOURCE BOUNDARY PASSED: scanned $($publicEntries.Count) file-system entries and $($trackedFiles.Count) tracked release paths under $repositoryRoot"
