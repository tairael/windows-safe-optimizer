$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot 'TestHelpers.ps1')

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$skillPath = Join-Path $repositoryRoot 'skills\windows-safe-optimizer\SKILL.md'
$agentPath = Join-Path $repositoryRoot 'skills\windows-safe-optimizer\agents\openai.yaml'
$skill = Get-Content -Raw -LiteralPath $skillPath
$agent = Get-Content -Raw -LiteralPath $agentPath

Assert-True ($skill -match '(?ms)^---\s+name:\s+windows-safe-optimizer\s+description:\s+Use when[^\r\n]+\s+---') 'Frontmatter trigger is invalid or description is not a plain string beginning with Use when'

foreach ($token in @('deep-collaboration', 'conservative-advice', 'R0', 'R1', 'R2', 'R3', 'R4')) {
    Assert-True ($skill.Contains($token)) "Missing Skill contract token: $token"
}

$requiredSections = @(
    '## Core principle',
    '## Platform gate',
    '## Choose a mode',
    '## Risk levels',
    '## Universal workflow',
    '## Operation card',
    '## Module routing',
    '## Forbidden actions',
    '## Privacy boundary',
    '## Completion checklist'
)
$previousIndex = -1
foreach ($section in $requiredSections) {
    $sectionIndex = $skill.IndexOf($section, [System.StringComparison]::Ordinal)
    Assert-True ($sectionIndex -gt $previousIndex) "Missing or out-of-order Skill section: $section"
    $previousIndex = $sectionIndex
}

$operationCardStart = $skill.IndexOf('## Operation card', [System.StringComparison]::Ordinal)
$operationCardEnd = $skill.IndexOf('## Module routing', [System.StringComparison]::Ordinal)
Assert-True (($operationCardStart -ge 0) -and ($operationCardEnd -gt $operationCardStart)) 'Operation-card section boundaries are invalid'
$operationCard = $skill.Substring($operationCardStart, $operationCardEnd - $operationCardStart)

foreach ($field in @('Finding', 'Evidence', 'Expected gain', 'Feature impact', 'Risk', 'Action', 'Backup', 'Rollback', 'Validation', 'Privacy', 'Stop condition')) {
    Assert-True ($operationCard.Contains("| $field |")) "Missing operation-card field in operation-card section: $field"
}
foreach ($contract in @(
    'A refusal, safety stop, unselected mode, or advice-only block is still a candidate outcome',
    '`Not performed`',
    '`Not applicable — no change`',
    'missing platform or ownership fact',
    'exact object that would need naming',
    'why execution is stopped',
    'nearest safe next step',
    'or explicitly says that none was performed'
)) {
    Assert-True ($operationCard.Contains($contract)) "Missing blocked-outcome operation-card contract: $contract"
}

$routingStart = $skill.IndexOf('## Module routing', [System.StringComparison]::Ordinal)
$routingEnd = $skill.IndexOf('## Forbidden actions', [System.StringComparison]::Ordinal)
Assert-True (($routingStart -ge 0) -and ($routingEnd -gt $routingStart)) 'Module routing table boundaries are invalid'
$routing = $skill.Substring($routingStart, $routingEnd - $routingStart)

$referenceFiles = @(
    'disk-and-storage.md',
    'memory-and-startup.md',
    'performance.md',
    'network-and-proxy.md',
    'security-and-privacy.md',
    'interface-and-notifications.md',
    'apps-and-features.md',
    'new-pc-onboarding.md',
    'backup-rollback-validation.md'
)
foreach ($referenceFile in $referenceFiles) {
    $count = ([regex]::Matches($routing, [regex]::Escape($referenceFile))).Count
    Assert-Equal 1 $count "Reference filename must appear exactly once in the routing table: $referenceFile"
    Assert-True ($routing.Contains("(references/$referenceFile)")) "Reference must be a direct Markdown link: $referenceFile"
}

$referenceContracts = @{
    'disk-and-storage.md' = @('logical size', 'volume free space', 'reparse point', 'cloud sync', 'official uninstall')
    'memory-and-startup.md' = @('available memory', 'commit', 'paging', 'process group', 'pagefile')
    'performance.md' = @('bottleneck', 'power mode', 'temperature', 'Windows Update', 'stop condition')
    'network-and-proxy.md' = @('DNS', 'TLS', 'HTTP', 'WebSocket', 'SSE', 'VPN', 'proxy credential')
    'security-and-privacy.md' = @('Defender', 'firewall', 'Windows Update', 'UAC', 'Windows 10 lifecycle')
    'interface-and-notifications.md' = @('security notification', 'update notification', 'background permission', 'user preference')
    'apps-and-features.md' = @('official uninstall', 'dependency', 'shared component', 'optional feature')
    'new-pc-onboarding.md' = @('recovery', 'backup', 'software source', 'storage layout', 'use case')
    'backup-rollback-validation.md' = @('exact target', 'original state', 'execution context', 'rollback', 'fresh evidence')
}
$referenceSections = @('## Read first', '## Evidence', '## Candidate classes', '## Preserve', '## Risk upgrades', '## Validation', '## Stop')

function Remove-MarkdownFencedCodeBlocks {
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    return [regex]::Replace(
        $Content,
        '(?ms)^[ \t]*(?<fence>```|~~~)[^\r\n]*\r?\n.*?^[ \t]*\k<fence>[ \t]*(?:\r?\n|$)',
        ''
    )
}

function Test-ReferenceSectionContract {
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    $body = Remove-MarkdownFencedCodeBlocks -Content $Content
    $previousIndex = -1
    foreach ($section in $referenceSections) {
        $headingPattern = '(?m)^' + [regex]::Escape($section) + '[ \t]*\r?$'
        $matches = [regex]::Matches($body, $headingPattern)
        if ($matches.Count -ne 1) { return $false }
        if ($matches[0].Index -le $previousIndex) { return $false }
        $previousIndex = $matches[0].Index
    }
    return $true
}

$duplicateHeadingFixture = @"
## Read first
## Evidence
## Candidate classes
## Preserve
## Risk upgrades
## Validation
## Stop
## Read first
"@
$wrongOrderFixture = @"
## Evidence
## Read first
## Candidate classes
## Preserve
## Risk upgrades
## Validation
## Stop
"@
$negativeReferenceFixtures = @{
    'duplicate heading' = $duplicateHeadingFixture
    'wrong heading order' = $wrongOrderFixture
}
$legacyFalseGreens = @($negativeReferenceFixtures.GetEnumerator() | Where-Object {
    $fixture = $_.Value
    -not ($referenceSections | Where-Object { -not $fixture.Contains($_) })
})
Assert-Equal 2 $legacyFalseGreens.Count 'Negative fixtures must prove that legacy Contains checks accept duplicate and out-of-order headings'
foreach ($fixture in $negativeReferenceFixtures.GetEnumerator()) {
    Assert-True (-not (Test-ReferenceSectionContract -Content $fixture.Value)) "Reference section contract accepted negative fixture: $($fixture.Key)"
}
$fencedTokenFixture = @'
Body text without the required phrase.

```text
logical size
```
'@
$fencedTokenBody = Remove-MarkdownFencedCodeBlocks -Content $fencedTokenFixture
Assert-True (-not $fencedTokenBody.Contains('logical size')) 'Token checks must ignore fenced code blocks'

foreach ($referenceFile in $referenceContracts.Keys) {
    $referencePath = Join-Path $repositoryRoot "skills\windows-safe-optimizer\references\$referenceFile"
    Assert-True (Test-Path -LiteralPath $referencePath -PathType Leaf) "Missing reference: $referenceFile"
    $reference = Get-Content -Raw -LiteralPath $referencePath
    $referenceBody = Remove-MarkdownFencedCodeBlocks -Content $reference
    Assert-True (Test-ReferenceSectionContract -Content $reference) "Reference sections must appear exactly once and in order: $referenceFile"
    foreach ($token in $referenceContracts[$referenceFile]) {
        Assert-True ($referenceBody.Contains($token)) "Missing reference body token in ${referenceFile}: $token"
    }
}

foreach ($baselineRule in @(
    'Start the first substantive response with `Mode:`',
    'Mode: conservative-advice',
    'Do not guarantee a requested percentage',
    'pagefile',
    'OneDrive',
    'reparse point',
    'one-click',
    'written authorization',
    'exact scan root',
    'full path, hash, and size',
    'one identified configuration object at a time'
)) {
    Assert-True ($skill.Contains($baselineRule)) "Missing RED-baseline safety rule: $baselineRule"
}

Assert-True ($agent -match '(?m)^\s+display_name:\s+"Windows Safe Optimizer"\s*$') 'Agent display_name is invalid'
Assert-True ($agent -match '(?m)^\s+short_description:\s+"[^"]{25,64}"\s*$') 'Agent short_description must be a quoted 25-64 character string'
Assert-True ($agent -match '(?m)^\s+default_prompt:\s+"[^"]*\$windows-safe-optimizer[^"]*"\s*$') 'Agent default_prompt must be quoted and mention $windows-safe-optimizer'

'PASS: Skill contract and routing'
