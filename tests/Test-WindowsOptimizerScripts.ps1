$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot 'TestHelpers.ps1')
. (Join-Path $PSScriptRoot 'TestRunnerSandboxHelpers.ps1')

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $repositoryRoot 'skills\windows-safe-optimizer\scripts\Test-WindowsOptimizerEnvironment.ps1'
$collectorPath = Join-Path $repositoryRoot 'skills\windows-safe-optimizer\scripts\Collect-WindowsBaseline.ps1'

function Invoke-EnvironmentScript {
    param([Parameter(Mandatory = $true)][string]$OutputDirectory)

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $scriptPath -OutputDirectory $OutputDirectory -AsJson 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    return [pscustomobject]@{ Output = $output; ExitCode = $exitCode }
}

function Invoke-BaselineCollector {
    param(
        [Parameter(Mandatory = $true)][string]$OutputDirectory,
        [Parameter(Mandatory = $true)][string[]]$Sections
    )

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        if (($Sections -join ',') -eq 'System,Storage,Memory') {
            $output = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $collectorPath -OutputDirectory $OutputDirectory -Sections System,Storage,Memory -SampleCount 1 -SampleIntervalSeconds 1 2>&1)
        }
        elseif (($Sections -join ',') -eq 'System,Storage,Memory,Startup,Security,Network') {
            $output = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $collectorPath -OutputDirectory $OutputDirectory -Sections System,Storage,Memory,Startup,Security,Network -SampleCount 1 -SampleIntervalSeconds 1 2>&1)
        }
        else {
            throw 'Baseline collector test must use an explicit supported section set.'
        }
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    return [pscustomobject]@{ Output = $output; ExitCode = $exitCode }
}

function Assert-CaseInsensitiveNotContains {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [AllowNull()][string]$Value,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not [string]::IsNullOrWhiteSpace($Value)) {
        Assert-True ($Text.IndexOf($Value, [StringComparison]::OrdinalIgnoreCase) -lt 0) $Message
    }
}

function Assert-BaselineOutputContainsOnlyReports {
    param([Parameter(Mandatory = $true)][string]$OutputDirectory)

    $children = @(Get-ChildItem -LiteralPath $OutputDirectory -Force)
    Assert-Equal 2 $children.Count 'Baseline collector created an unexpected number of output files'
    Assert-Equal 'baseline.json|baseline.md' (@($children.Name | Sort-Object) -join '|') 'Baseline collector wrote unexpected files'
}

function Assert-BaselineCollectorRejectsExistingReport {
    param(
        [Parameter(Mandatory = $true)][string]$OutputDirectory,
        [Parameter(Mandatory = $true)][string]$ExistingReportName,
        [Parameter(Mandatory = $true)][string]$Description
    )

    $existingReport = Join-Path $OutputDirectory $ExistingReportName
    $before = Get-Content -Raw -LiteralPath $existingReport
    $invocation = Invoke-BaselineCollector -OutputDirectory $OutputDirectory -Sections @('System', 'Storage', 'Memory')
    Assert-True ($invocation.ExitCode -ne 0) "Existing report was overwritten: $Description"
    Assert-Equal $before (Get-Content -Raw -LiteralPath $existingReport) "Existing report changed: $Description"
    $otherReportName = if ($ExistingReportName -eq 'baseline.json') { 'baseline.md' } else { 'baseline.json' }
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $OutputDirectory $otherReportName))) "Rejected collection left a partial report: $Description"
}

function Get-ScriptAstSafetyViolations {
    param([Parameter(Mandatory = $true)][Management.Automation.Language.Ast]$Ast)

    $violations = [System.Collections.Generic.List[string]]::new()
    $forbiddenCommandNames = @(
        'Remove-Item', 'Move-Item', 'Copy-Item', 'New-Item', 'Set-Content', 'Add-Content', 'Clear-Content', 'Out-File',
        'Set-ItemProperty', 'New-ItemProperty', 'Stop-Service', 'Set-Service',
        'Disable-ScheduledTask', 'Start-Process', 'reg', 'reg.exe', 'schtasks', 'schtasks.exe', 'cmd', 'cmd.exe',
        'del', 'erase', 'rd', 'rmdir', 'ri', 'rm', 'mv', 'move'
    )
    foreach ($command in @($Ast.FindAll({ param($node) $node -is [Management.Automation.Language.CommandAst] }, $true))) {
        $commandName = $command.GetCommandName()
        if ([string]::IsNullOrWhiteSpace($commandName)) {
            $violations.Add('dynamic command')
            continue
        }
        if ($forbiddenCommandNames -contains $commandName.ToLowerInvariant()) {
            $violations.Add("prohibited command: $commandName")
        }
        if ($commandName.EndsWith('.exe', [StringComparison]::OrdinalIgnoreCase)) {
            $violations.Add("native executable: $commandName")
        }
        if ($null -ne (Get-Alias -Name $commandName -ErrorAction SilentlyContinue)) {
            $violations.Add("alias command: $commandName")
        }
    }

    foreach ($member in @($Ast.FindAll({ param($node) $node -is [Management.Automation.Language.MemberExpressionAst] }, $true))) {
        $memberName = $member.Member.Extent.Text
        $isDangerousCall = $member.Extent.Text -match '(?i)(::|\.)(Delete|Move|MoveTo|Replace|Copy|CopyTo|SetValue)\('
        if ($isDangerousCall) {
            $containingFunction = $member
            while ($null -ne $containingFunction -and -not ($containingFunction -is [Management.Automation.Language.FunctionDefinitionAst])) {
                $containingFunction = $containingFunction.Parent
            }
            $isExactOwnedCleanup = $memberName -eq 'Delete' -and
                $null -ne $containingFunction -and
                $containingFunction.Name -eq 'Remove-NewlyCreatedBaselineReport' -and
                $member.Extent.Text -eq '[IO.File]::Delete($Path)'
            if (-not $isExactOwnedCleanup) {
                $violations.Add("dangerous .NET member call: $memberName")
            }
        }
    }

    return @($violations)
}

function Assert-NoDynamicOrMutatingBundledScriptAst {
    param([Parameter(Mandatory = $true)][string[]]$BundledScripts)

    foreach ($bundledScript in $BundledScripts) {
        $tokens = $null
        $errors = $null
        $ast = [Management.Automation.Language.Parser]::ParseFile($bundledScript, [ref]$tokens, [ref]$errors)
        Assert-Equal 0 $errors.Count "Bundled script has parser errors: $bundledScript"
        $violations = @(Get-ScriptAstSafetyViolations -Ast $ast)
        Assert-Equal 0 $violations.Count "Bundled script failed AST safety audit: $bundledScript; $($violations -join ', ')"

        if ((Split-Path -Leaf $bundledScript) -eq 'Collect-WindowsBaseline.ps1') {
            $fileOpenCalls = @($ast.FindAll({
                        param($node)
                        $node -is [Management.Automation.Language.MemberExpressionAst] -and
                        $node.Extent.Text.StartsWith('[IO.File]::Open(', [StringComparison]::Ordinal)
                    }, $true))
            Assert-Equal 1 $fileOpenCalls.Count 'Collector must have exactly one no-clobber file-open primitive'
            Assert-True ($fileOpenCalls[0].Extent.Text.Contains('[IO.FileMode]::CreateNew')) 'Collector file-open primitive is not exclusive CreateNew'

            $reportOpenCommands = @($ast.FindAll({
                        param($node)
                        $node -is [Management.Automation.Language.CommandAst] -and
                        $node.GetCommandName() -eq 'Open-NewBaselineReport'
                    }, $true))
            Assert-Equal 2 $reportOpenCommands.Count 'Collector must open exactly two report targets'
            $reportOpenExtents = @($reportOpenCommands.Extent.Text | Sort-Object)
            Assert-Equal 'Open-NewBaselineReport -Path $JsonPath|Open-NewBaselineReport -Path $MarkdownPath' ($reportOpenExtents -join '|') 'Collector report opens are not precisely limited to the two validated report paths'
        }
    }
}

function Assert-AstSafetyProbeRejected {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Description
    )

    $tokens = $null
    $errors = $null
    $ast = [Management.Automation.Language.Parser]::ParseInput($Source, [ref]$tokens, [ref]$errors)
    Assert-Equal 0 $errors.Count "AST safety probe did not parse: $Description"
    Assert-True (@(Get-ScriptAstSafetyViolations -Ast $ast).Count -gt 0) "AST safety probe was not rejected: $Description"
}

function Get-PathSnapshot {
    param([Parameter(Mandatory = $true)][string]$Path)

    $fullPath = [IO.Path]::GetFullPath($Path)
    if (-not (Test-Path -LiteralPath $fullPath)) {
        return [pscustomobject]@{ Path = $fullPath; Exists = $false; Attributes = $null; LastWriteTimeUtc = $null; ChildCount = $null }
    }

    $item = Get-Item -LiteralPath $fullPath -Force -ErrorAction Stop
    $childCount = $null
    if ($item.PSIsContainer) {
        try {
            $childCount = @(Get-ChildItem -LiteralPath $fullPath -Force -ErrorAction Stop).Count
        }
        catch [UnauthorizedAccessException] {
            $childCount = $null
        }
    }
    return [pscustomobject]@{
        Path = $fullPath
        Exists = $true
        Attributes = [int]$item.Attributes
        LastWriteTimeUtc = $item.LastWriteTimeUtc.Ticks
        ChildCount = $childCount
    }
}

function Assert-PathSnapshotUnchanged {
    param(
        [Parameter(Mandatory = $true)][psobject]$Before,
        [Parameter(Mandatory = $true)][psobject]$After,
        [Parameter(Mandatory = $true)][string]$Description
    )

    foreach ($property in @('Path', 'Exists', 'Attributes', 'LastWriteTimeUtc', 'ChildCount')) {
        Assert-Equal $Before.$property $After.$property "Output path changed during rejected inspection ($Description): $property"
    }
}

function Assert-OutputDirectoryRejectedWithoutMutation {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Description
    )

    $before = Get-PathSnapshot -Path $Path
    $invocation = Invoke-EnvironmentScript -OutputDirectory $Path
    $after = Get-PathSnapshot -Path $Path
    Assert-True ($invocation.ExitCode -ne 0) "Unsafe output directory was accepted: $Description"
    Assert-PathSnapshotUnchanged -Before $before -After $after -Description $Description
}

function Get-CaseAndTrailingSeparatorVariant {
    param([Parameter(Mandatory = $true)][string]$Path)

    $fullPath = [IO.Path]::GetFullPath($Path).ToUpperInvariant()
    if (-not $fullPath.EndsWith([string][IO.Path]::DirectorySeparatorChar)) {
        $fullPath += [IO.Path]::DirectorySeparatorChar
    }
    return $fullPath
}

Assert-True (Test-Path -LiteralPath $scriptPath) 'Environment script is missing'
Assert-True (Test-Path -LiteralPath $collectorPath) 'Baseline collector is missing'

$temporaryParentGuard = Initialize-TestRunnerTemporaryParent -RepositoryRoot $repositoryRoot
$sandbox = $null
$reparsePath = $null
$ancestorLink = $null
$reportReparsePath = $null
try {
    $sandbox = New-TestRunnerSandbox -RepositoryRoot $repositoryRoot -TemporaryParentGuard $temporaryParentGuard
    $testOutput = Join-Path $sandbox.Path 'output'
    New-Item -ItemType Directory -Path $testOutput | Out-Null

    . $scriptPath -OutputDirectory $testOutput | Out-Null
    Assert-True ($null -ne (Get-Command 'Test-SupportedWindowsProductName' -ErrorAction SilentlyContinue)) 'Product-name support predicate is missing'
    Assert-True (Test-SupportedWindowsProductName -ProductName 'Windows 10 Pro') 'Windows 10 should be supported'
    Assert-True (Test-SupportedWindowsProductName -ProductName 'Windows 11 Home') 'Windows 11 should be supported'
    Assert-Equal $false (Test-SupportedWindowsProductName -ProductName 'Windows Server 2022 Datacenter') 'Windows Server must not be supported'
    Assert-Equal $false (Test-SupportedWindowsProductName -ProductName 'Ubuntu 24.04') 'Non-Windows product must not be supported'

    $validBefore = Get-PathSnapshot -Path $testOutput
    $successfulInvocation = Invoke-EnvironmentScript -OutputDirectory $testOutput
    $validAfter = Get-PathSnapshot -Path $testOutput
    Assert-Equal 0 $successfulInvocation.ExitCode 'Environment script failed for a normal existing directory'
    Assert-PathSnapshotUnchanged -Before $validBefore -After $validAfter -Description 'normal directory'
    $resultJson = $successfulInvocation.Output | Out-String
    $result = $resultJson | ConvertFrom-Json

    Assert-Equal '1.0' $result.schemaVersion 'Unexpected environment schema'
    Assert-True ($null -ne $result.supportedOS) 'supportedOS missing'
    Assert-True ($result.outputDirectory -eq [IO.Path]::GetFullPath($testOutput)) 'Output path was not normalized'
    Assert-Equal $false ([bool]$result.outputDirectoryIsReparsePoint) 'Normal output directory was reported as a reparse point'
    foreach ($field in @('productName', 'displayVersion', 'buildNumber', 'powerShellVersion', 'isAdministrator', 'warnings')) {
        Assert-True ($result.PSObject.Properties.Name -contains $field) "Environment field is missing: $field"
    }

    $documentsDirectory = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)) 'Documents'
    $documentsBefore = Get-PathSnapshot -Path $documentsDirectory
    $documentsInvocation = Invoke-EnvironmentScript -OutputDirectory $documentsDirectory
    $documentsAfter = Get-PathSnapshot -Path $documentsDirectory
    Assert-Equal 0 $documentsInvocation.ExitCode 'A normal user-profile child directory was rejected'
    Assert-PathSnapshotUnchanged -Before $documentsBefore -After $documentsAfter -Description 'normal user-profile child directory'

    Assert-OutputDirectoryRejectedWithoutMutation -Path (Get-CaseAndTrailingSeparatorVariant -Path (Join-Path $env:windir 'Temp')) -Description 'Windows descendant with case and trailing separator'
    foreach ($programFilesRoot in @($env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:ProgramW6432 | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)) {
        $commonFiles = Join-Path $programFilesRoot 'Common Files'
        if (Test-Path -LiteralPath $commonFiles -PathType Container) {
            Assert-OutputDirectoryRejectedWithoutMutation -Path (Get-CaseAndTrailingSeparatorVariant -Path $commonFiles) -Description "Program Files descendant with case and trailing separator: $programFilesRoot"
        }
    }

    $ordinaryConflictOutput = Join-Path $sandbox.Path 'ordinary-conflict-output'
    New-Item -ItemType Directory -Path $ordinaryConflictOutput | Out-Null
    Set-Content -LiteralPath (Join-Path $ordinaryConflictOutput 'baseline.json') -Value 'ordinary sentinel' -NoNewline
    Assert-BaselineCollectorRejectsExistingReport -OutputDirectory $ordinaryConflictOutput -ExistingReportName 'baseline.json' -Description 'ordinary baseline.json sentinel'

    $markdownConflictOutput = Join-Path $sandbox.Path 'markdown-conflict-output'
    New-Item -ItemType Directory -Path $markdownConflictOutput | Out-Null
    Set-Content -LiteralPath (Join-Path $markdownConflictOutput 'baseline.md') -Value 'markdown sentinel' -NoNewline
    Assert-BaselineCollectorRejectsExistingReport -OutputDirectory $markdownConflictOutput -ExistingReportName 'baseline.md' -Description 'ordinary baseline.md sentinel'

    $hardLinkOutput = Join-Path $sandbox.Path 'hardlink-conflict-output'
    New-Item -ItemType Directory -Path $hardLinkOutput | Out-Null
    $hardLinkTarget = Join-Path $hardLinkOutput 'hardlink-target.json'
    Set-Content -LiteralPath $hardLinkTarget -Value 'hardlink target sentinel' -NoNewline
    New-Item -ItemType HardLink -Path (Join-Path $hardLinkOutput 'baseline.json') -Target $hardLinkTarget | Out-Null
    $hardLinkTargetBefore = Get-Content -Raw -LiteralPath $hardLinkTarget
    $hardLinkInvocation = Invoke-BaselineCollector -OutputDirectory $hardLinkOutput -Sections @('System', 'Storage', 'Memory')
    Assert-True ($hardLinkInvocation.ExitCode -ne 0) 'Hard-linked baseline.json was accepted'
    Assert-Equal $hardLinkTargetBefore (Get-Content -Raw -LiteralPath $hardLinkTarget) 'Hard-link target content changed'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $hardLinkOutput 'baseline.md'))) 'Hard-link rejection left a partial report'

    $baselineOutput = Join-Path $sandbox.Path 'baseline-output'
    New-Item -ItemType Directory -Path $baselineOutput | Out-Null
    $fastInvocation = Invoke-BaselineCollector -OutputDirectory $baselineOutput -Sections @('System', 'Storage', 'Memory')
    Assert-Equal 0 $fastInvocation.ExitCode "Three-section baseline collection failed: $($fastInvocation.Output | Out-String)"
    $baselineJsonPath = Join-Path $baselineOutput 'baseline.json'
    $baselineMarkdownPath = Join-Path $baselineOutput 'baseline.md'
    Assert-True (Test-Path -LiteralPath $baselineJsonPath -PathType Leaf) 'baseline.json missing'
    Assert-True (Test-Path -LiteralPath $baselineMarkdownPath -PathType Leaf) 'baseline.md missing'
    Assert-BaselineOutputContainsOnlyReports -OutputDirectory $baselineOutput

    $baselineJson = Get-Content -Raw -LiteralPath $baselineJsonPath
    $baseline = $baselineJson | ConvertFrom-Json
    Assert-Equal '1.0' $baseline.schemaVersion 'Unexpected baseline schema'
    foreach ($field in @('generatedAt', 'collectionContext', 'system', 'storage', 'memory', 'startup', 'security', 'network', 'warnings')) {
        Assert-True ($baseline.PSObject.Properties.Name -contains $field) "Baseline top-level field is missing: $field"
    }
    foreach ($section in @('system', 'storage', 'memory')) {
        Assert-True ($null -ne $baseline.$section) "Fast baseline section is missing: $section"
    }
    Assert-CaseInsensitiveNotContains -Text $baselineJson -Value $env:USERNAME -Message 'Raw username leaked from baseline JSON'
    Assert-CaseInsensitiveNotContains -Text $baselineJson -Value $env:USERPROFILE -Message 'Raw profile path leaked from baseline JSON'
    Assert-True ($baselineJson -notmatch '(?i)\bS-\d-\d+(?:-\d+){1,}\b') 'SID-shaped value leaked from baseline JSON'
    $baselineMarkdown = Get-Content -Raw -LiteralPath $baselineMarkdownPath
    Assert-True ($baselineMarkdown.Contains([string]$baseline.generatedAt)) 'Markdown was not generated from the finalized baseline object'
    Assert-CaseInsensitiveNotContains -Text $baselineMarkdown -Value $env:USERNAME -Message 'Raw username leaked from baseline Markdown'
    Assert-CaseInsensitiveNotContains -Text $baselineMarkdown -Value $env:USERPROFILE -Message 'Raw profile path leaked from baseline Markdown'
    Assert-True ($baselineMarkdown -notmatch '(?i)\bS-\d-\d+(?:-\d+){1,}\b') 'SID-shaped value leaked from baseline Markdown'

    $allBaselineOutput = Join-Path $sandbox.Path 'all-baseline-output'
    New-Item -ItemType Directory -Path $allBaselineOutput | Out-Null
    $allSectionsInvocation = Invoke-BaselineCollector -OutputDirectory $allBaselineOutput -Sections @('System', 'Storage', 'Memory', 'Startup', 'Security', 'Network')
    Assert-Equal 0 $allSectionsInvocation.ExitCode "All-section baseline collection failed: $($allSectionsInvocation.Output | Out-String)"
    Assert-BaselineOutputContainsOnlyReports -OutputDirectory $allBaselineOutput
    $allBaseline = (Get-Content -Raw -LiteralPath (Join-Path $allBaselineOutput 'baseline.json')) | ConvertFrom-Json
    foreach ($section in @('system', 'storage', 'memory', 'startup', 'security', 'network')) {
        Assert-True ($null -ne $allBaseline.$section) "All-section baseline is missing: $section"
    }
    if ($allBaseline.collectionContext.isAdministrator -ne $false) {
        throw 'NON-ADMIN VERIFICATION UNAVAILABLE: the current test process is elevated; no scheduled task, UAC prompt, or unsafe restricted-token workaround is used.'
    }
    foreach ($warning in @($allBaseline.warnings)) {
        foreach ($property in @('section', 'code', 'message')) {
            Assert-True ($warning.PSObject.Properties.Name -contains $property) "Baseline warning is not structured: $property"
        }
    }

    $memoryProviderOutput = Join-Path $sandbox.Path 'memory-provider-output'
    New-Item -ItemType Directory -Path $memoryProviderOutput | Out-Null
    . $collectorPath -OutputDirectory $memoryProviderOutput -Sections System -SampleCount 1 -SampleIntervalSeconds 1
    $memoryWarnings = [System.Collections.Generic.List[object]]::new()
    $unavailableMemory = Get-MemorySnapshot -Warnings $memoryWarnings -RequestedSampleCount 1 -IntervalSeconds 1 -MemoryProvider ([System.Func[object]]{ throw [UnauthorizedAccessException]::new('denied for test') })
    Assert-Equal $null $unavailableMemory.samples 'Fully unavailable memory collection must not report an empty successful sample set'
    Assert-Equal 1 $memoryWarnings.Count 'Fully unavailable memory collection must add one warning'
    Assert-Equal 'memory' $memoryWarnings[0].section 'Memory warning section is incorrect'
    Assert-Equal 'sampleReadUnavailable' $memoryWarnings[0].code 'Memory warning code is incorrect'

    Assert-NoDynamicOrMutatingBundledScriptAst -BundledScripts @($scriptPath, $collectorPath)
    foreach ($astProbe in @(
            [pscustomobject]@{ Source = "& ('re' + 'g.exe') add HKCU\Software\Probe /v Value /d 1"; Description = 'dynamically concatenated native command' },
            [pscustomobject]@{ Source = 're`g.exe add HKCU\Software\Probe /v Value /d 1'; Description = 'backtick-obfuscated reg.exe command' },
            [pscustomobject]@{ Source = 'schtasks.exe /change /tn Probe /disable'; Description = 'schtasks.exe mutation' },
            [pscustomobject]@{ Source = "[IO.File]::Delete('probe')"; Description = '.NET file deletion' },
            [pscustomobject]@{ Source = "[IO.File]::Move('from','to')"; Description = '.NET file move' }
        )) {
        Assert-AstSafetyProbeRejected -Source $astProbe.Source -Description $astProbe.Description
    }

    Assert-OutputDirectoryRejectedWithoutMutation -Path ([IO.Path]::GetPathRoot($testOutput).ToLowerInvariant()) -Description 'volume root with case variation'
    Assert-OutputDirectoryRejectedWithoutMutation -Path (Get-CaseAndTrailingSeparatorVariant -Path $env:windir) -Description 'Windows directory with case and trailing separator'
    Assert-OutputDirectoryRejectedWithoutMutation -Path (Get-CaseAndTrailingSeparatorVariant -Path $env:ProgramFiles) -Description 'Program Files directory with case and trailing separator'
    Assert-OutputDirectoryRejectedWithoutMutation -Path (Get-CaseAndTrailingSeparatorVariant -Path ([Environment]::GetFolderPath('UserProfile'))) -Description 'profile root with case and trailing separator'

    $missingDirectory = Join-Path $sandbox.Path 'does-not-exist'
    Assert-OutputDirectoryRejectedWithoutMutation -Path $missingDirectory -Description 'nonexistent directory'

    $reparseTarget = Join-Path $sandbox.Path 'reparse-target'
    $reparsePath = Join-Path $sandbox.Path 'reparse-output'
    New-Item -ItemType Directory -Path $reparseTarget | Out-Null
    New-Item -ItemType Junction -Path $reparsePath -Target $reparseTarget | Out-Null
    $reparseItem = Get-Item -LiteralPath $reparsePath -Force
    Assert-True (($reparseItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) 'Reparse fixture is not a reparse point'
    Assert-OutputDirectoryRejectedWithoutMutation -Path $reparsePath -Description 'endpoint reparse point'

    $reportReparseTarget = Join-Path $sandbox.Path 'report-reparse-target'
    $reportReparseOutput = Join-Path $sandbox.Path 'report-reparse-output'
    New-Item -ItemType Directory -Path $reportReparseTarget | Out-Null
    New-Item -ItemType Directory -Path $reportReparseOutput | Out-Null
    $reportReparsePath = Join-Path $reportReparseOutput 'baseline.json'
    New-Item -ItemType Junction -Path $reportReparsePath -Target $reportReparseTarget | Out-Null
    $reportReparseTargetBefore = Get-PathSnapshot -Path $reportReparseTarget
    $reportReparseInvocation = Invoke-BaselineCollector -OutputDirectory $reportReparseOutput -Sections @('System', 'Storage', 'Memory')
    $reportReparseTargetAfter = Get-PathSnapshot -Path $reportReparseTarget
    Assert-True ($reportReparseInvocation.ExitCode -ne 0) 'Reparse-point baseline.json was accepted'
    Assert-PathSnapshotUnchanged -Before $reportReparseTargetBefore -After $reportReparseTargetAfter -Description 'baseline.json reparse target'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $reportReparseOutput 'baseline.md'))) 'Reparse-point rejection left a partial report'

    $ancestorTarget = Join-Path $sandbox.Path 'ancestor-target'
    $ancestorLink = Join-Path $sandbox.Path 'ancestor-link'
    $ancestorChild = Join-Path $ancestorTarget 'child'
    New-Item -ItemType Directory -Path $ancestorChild -Force | Out-Null
    New-Item -ItemType Junction -Path $ancestorLink -Target $ancestorTarget | Out-Null
    $ancestorItem = Get-Item -LiteralPath $ancestorLink -Force
    Assert-True (($ancestorItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) 'Ancestor reparse fixture is not a reparse point'
    $ancestorTargetBefore = Get-PathSnapshot -Path $ancestorTarget
    $ancestorInvocation = Invoke-EnvironmentScript -OutputDirectory (Join-Path $ancestorLink 'child')
    $ancestorTargetAfter = Get-PathSnapshot -Path $ancestorTarget
    Assert-True ($ancestorInvocation.ExitCode -ne 0) 'Unsafe output directory was accepted: descendant of ancestor reparse point'
    Assert-PathSnapshotUnchanged -Before $ancestorTargetBefore -After $ancestorTargetAfter -Description 'ancestor reparse target'
}
finally {
    foreach ($linkPath in @($reparsePath, $ancestorLink, $reportReparsePath)) {
        if ($null -ne $linkPath -and (Test-Path -LiteralPath $linkPath)) {
            $linkItem = Get-Item -LiteralPath $linkPath -Force
            if (($linkItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                [IO.Directory]::Delete($linkPath, $false)
                Assert-True (-not (Test-Path -LiteralPath $linkPath)) "Owned junction cleanup failed: $linkPath"
            }
        }
    }

    if ($null -ne $sandbox) {
        Remove-TestRunnerSandbox -Sandbox $sandbox
    }
    else {
        Remove-TestRunnerTemporaryParentIfOwned -TemporaryParentGuard $temporaryParentGuard
    }
}

'PASS: Windows optimizer environment inspection'
