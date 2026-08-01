$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot 'TestHelpers.ps1')

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$requiredFiles = @(
    'README.md',
    'README.en.md',
    'SECURITY.md',
    'CONTRIBUTING.md',
    'LICENSE',
    'assets/banner.svg',
    'docs/writing-style.md',
    'examples/example-prompts.md',
    'examples/sample-report.md'
)

foreach ($relativePath in $requiredFiles) {
    $fullPath = Join-Path $repositoryRoot $relativePath
    Assert-True (Test-Path -LiteralPath $fullPath -PathType Leaf) "Missing documentation file: $relativePath"
}

$readme = Get-Content -LiteralPath (Join-Path $repositoryRoot 'README.md') -Raw
$englishReadme = Get-Content -LiteralPath (Join-Path $repositoryRoot 'README.en.md') -Raw
$sampleReport = Get-Content -LiteralPath (Join-Path $repositoryRoot 'examples/sample-report.md') -Raw
$banner = Get-Content -LiteralPath (Join-Path $repositoryRoot 'assets/banner.svg') -Raw

$requiredHeadings = @(
    '它解决什么问题',
    '你会得到什么',
    '两种使用模式',
    '三分钟开始',
    '九个能力模块',
    '来自实测的方法',
    '安全边界',
    '隐私',
    '常见问题'
)
foreach ($heading in $requiredHeadings) {
    Assert-True ($readme.Contains($heading)) "Missing README section: $heading"
}

$installCommand = 'npx skills add tairael/windows-safe-optimizer --skill windows-safe-optimizer -g -a codex'
Assert-True ($readme.Contains('assets/banner.svg')) 'README banner missing'
Assert-True ($readme.Contains($installCommand)) 'README install command missing or changed'
Assert-True ($readme.Contains('DO_NOT_TRACK')) 'Installer telemetry disclosure missing'
Assert-True (([regex]::Matches($readme, '```mermaid')).Count -ge 3) 'README needs at least three useful Mermaid diagrams'

$badgeCount = ([regex]::Matches($readme, 'https://img\.shields\.io/badge/')).Count
Assert-True ($badgeCount -ge 3 -and $badgeCount -le 4) "README must use 3 to 4 badges; found $badgeCount"
foreach ($callout in @('[!NOTE]', '[!IMPORTANT]', '[!WARNING]')) {
    Assert-True ($readme.Contains($callout)) "Missing GitHub callout: $callout"
}

foreach ($term in @('Installation', 'Modes', 'Modules', 'Safety', 'Privacy', 'Support status', 'DO_NOT_TRACK')) {
    Assert-True ($englishReadme.Contains($term)) "English README is missing: $term"
}
Assert-True ($englishReadme.Contains($installCommand)) 'English README install command missing or changed'

$publicMarkdown = Get-ChildItem -LiteralPath $repositoryRoot -Recurse -File -Filter '*.md'
foreach ($markdownFile in $publicMarkdown) {
    $content = Get-Content -LiteralPath $markdownFile.FullName -Raw

    foreach ($match in [regex]::Matches($content, '(?i)windows-safe-optimizer')) {
        Assert-Equal 'windows-safe-optimizer' $match.Value "Inconsistent package-name casing in $($markdownFile.FullName)"
    }

    $links = [regex]::Matches($content, '!?(?:\[[^\]]*\])\((?<target>[^)]+)\)')
    foreach ($link in $links) {
        $target = $link.Groups['target'].Value.Trim()
        if ($target.StartsWith('<') -and $target.EndsWith('>')) {
            $target = $target.Substring(1, $target.Length - 2)
        }
        if ($target -match '^(?:https?://|mailto:|#)' -or [string]::IsNullOrWhiteSpace($target)) {
            continue
        }

        $pathOnly = [uri]::UnescapeDataString(($target -split '#', 2)[0])
        $resolvedPath = Join-Path $markdownFile.DirectoryName $pathOnly
        Assert-True (Test-Path -LiteralPath $resolvedPath) "Broken relative link in $($markdownFile.FullName): $target"
    }
}

Assert-Equal 1 ([regex]::Matches($banner, '<linearGradient\b')).Count 'Banner must contain exactly one linearGradient'
Assert-Equal 1 ([regex]::Matches($banner, '<title\b')).Count 'Banner must contain one title'
Assert-Equal 1 ([regex]::Matches($banner, '<desc\b')).Count 'Banner must contain one description'
Assert-True ($banner -match '<svg\b[^>]*\bwidth="1600"[^>]*\bheight="520"') 'Banner must be 1600 by 520'
Assert-True ($banner -match '\brole="img"') 'Banner must declare role="img"'
$bannerWithoutSvgNamespace = $banner -replace 'http://www\.w3\.org/2000/svg', ''
Assert-True ($bannerWithoutSvgNamespace -notmatch '(?i)https?://') 'Banner must not load external URLs'
Assert-True ($banner -notmatch '(?i)<(?:script|image|filter)\b') 'Banner must not use scripts, images, or filters'

Assert-True ($sampleReport.Contains('完全虚构')) 'Sample report must declare that it is fictional'
Assert-True ($sampleReport -notmatch 'S-1-5-\d+(?:-\d+)+') 'Sample report must not contain a SID'
Assert-True ($sampleReport -notmatch '(?im)\b[A-Z]:\\(?:Users|Documents and Settings)\\') 'Sample report must not contain a real-style user path'
Assert-True ($sampleReport -notmatch '(?im)\b(?:25[0-5]|2[0-4]\d|1?\d?\d)(?:\.(?:25[0-5]|2[0-4]\d|1?\d?\d)){3}\b') 'Sample report must not contain an IP address'

'PASS: Public documentation contract'
