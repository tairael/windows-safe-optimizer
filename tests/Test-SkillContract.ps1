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

foreach ($field in @('Finding', 'Evidence', 'Expected gain', 'Feature impact', 'Risk', 'Action', 'Backup', 'Rollback', 'Validation', 'Stop condition')) {
    Assert-True ($skill.Contains("| $field |")) "Missing operation-card field: $field"
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
