$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'TestHelpers.ps1')
. (Join-Path $PSScriptRoot 'PublicSourceBoundaryHelpers.ps1')

$markerPath = Join-Path $repositoryRoot '.public-source-root'
Assert-True (Test-Path -LiteralPath $markerPath -PathType Leaf) 'Public source root marker is missing'
Assert-Equal 'windows-safe-optimizer-public-source-v1' ((Get-Content -LiteralPath $markerPath -Raw).Trim()) 'Public source root marker is invalid'
Assert-True (Test-Path -LiteralPath (Join-Path $repositoryRoot '.git')) 'Public source root is not an independent Git repository'

$gitRoot = (& git -C $repositoryRoot rev-parse --show-toplevel).Trim()
Assert-Equal ([IO.Path]::GetFullPath($repositoryRoot).TrimEnd('\', '/')) ([IO.Path]::GetFullPath($gitRoot).TrimEnd('\', '/')) 'Git top-level is not the public source root'

$rootEntry = Get-Item -LiteralPath $repositoryRoot -Force
$publicEntries = @(Get-PublicSourceEntries -RepositoryRoot $repositoryRoot)
Assert-PublicFileSystemEntriesAllowed -RepositoryRoot $repositoryRoot -Entries @($rootEntry)
Assert-PublicFileSystemEntriesAllowed -RepositoryRoot $repositoryRoot -Entries $publicEntries

$trackedEntries = @(
    foreach ($line in @(& git -c core.quotepath=false -C $repositoryRoot ls-files --stage)) {
        if ($line -notmatch '^(?<mode>\d{6}) [0-9a-f]+ \d+\t(?<path>.+)$') {
            throw "Unexpected Git index entry: $line"
        }

        [pscustomobject]@{
            Mode = $Matches.mode
            Path = $Matches.path
        }
    }
)
Assert-PublicTrackedEntriesAllowed -Entries $trackedEntries

"PUBLIC SOURCE BOUNDARY PASSED: scanned $($publicEntries.Count) file-system entries and $($trackedEntries.Count) tracked release paths under $repositoryRoot"
