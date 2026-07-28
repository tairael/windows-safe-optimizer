$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'TestHelpers.ps1')
. (Join-Path $PSScriptRoot 'PublicSourceBoundaryHelpers.ps1')

function Assert-Throws {
    param([scriptblock]$Action, [string]$Message)

    $threw = $false
    try {
        & $Action
    }
    catch {
        $threw = $true
    }

    Assert-True $threw $Message
}

$blockedCases = @(
    @{ Name = 'requirements'; Path = '01-需求\brief.md' },
    @{ Name = 'design'; Path = '02-方案\design.md' },
    @{ Name = 'test evidence'; Path = '05-测试与验证\results.md' },
    @{ Name = 'delivery'; Path = '06-交付物\发布说明.md' },
    @{ Name = 'temporary files'; Path = '99-临时文件\scratch.txt' },
    @{ Name = 'sdd ledger'; Path = '.SuPeRpOwErS\sdd\progress.md' },
    @{ Name = 'task report'; Path = 'notes\TASK-1-REPORT.MD' },
    @{ Name = 'baseline results'; Path = 'notes\Skill-Baseline-Results.md' },
    @{ Name = 'baseline scenarios'; Path = 'notes\SKILL-BASELINE-SCENARIOS.MD' }
)

foreach ($case in $blockedCases) {
    $fileSystemEntry = [pscustomobject]@{
        FullName = Join-Path $repositoryRoot $case.Path
        Attributes = [IO.FileAttributes]::Normal
    }

    Assert-Throws {
        Assert-PublicFileSystemEntriesAllowed -RepositoryRoot $repositoryRoot -Entries @($fileSystemEntry)
    } "File-system scan accepted blocked $($case.Name) path: $($case.Path)"

    Assert-Throws {
        Assert-PublicTrackedPathsAllowed -RelativePaths @($case.Path)
    } "Git tracked-path scan accepted blocked $($case.Name) path: $($case.Path)"
}

$allowedBoundaryCases = @(
    'docs\101-需求-notes.md',
    'docs\02-方案外.md',
    'docs\task-1-reporter.md',
    'docs\skill-baseline-results-summary.md'
)

Assert-PublicTrackedPathsAllowed -RelativePaths $allowedBoundaryCases

$reparseEntry = [pscustomobject]@{
    FullName = Join-Path $repositoryRoot 'docs\linked-content'
    Attributes = [IO.FileAttributes]::Directory -bor [IO.FileAttributes]::ReparsePoint
}

Assert-Throws {
    Assert-PublicFileSystemEntriesAllowed -RepositoryRoot $repositoryRoot -Entries @($reparseEntry)
} 'File-system scan accepted a reparse point probe'

"PUBLIC SOURCE NEGATIVE MATRIX PASSED: $($blockedCases.Count) blocked patterns checked through 2 scan paths; reparse probe rejected"
