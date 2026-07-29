[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$OutputDirectory,

    [string[]]$Sections = @('System', 'Storage', 'Memory', 'Startup', 'Security', 'Network'),

    [ValidateRange(1, 5)]
    [int]$SampleCount = 1,

    [ValidateRange(1, 10)]
    [int]$SampleIntervalSeconds = 1
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Add-BaselineWarning {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.List[object]]$Warnings,
        [Parameter(Mandatory = $true)][string]$Section,
        [Parameter(Mandatory = $true)][string]$Code,
        [Parameter(Mandatory = $true)][string]$Message
    )

    $Warnings.Add([pscustomobject][ordered]@{
            section = $Section
            code = $Code
            message = $Message
        })
}

function Get-NullableBooleanProperty {
    param(
        [Parameter(Mandatory = $true)][object]$InputObject,
        [Parameter(Mandatory = $true)][string]$PropertyName
    )

    $property = $InputObject.PSObject.Properties[$PropertyName]
    if ($null -eq $property -or $null -eq $property.Value) {
        return $null
    }

    return [bool]$property.Value
}

function Resolve-ValidatedOutputDirectory {
    param([Parameter(Mandatory = $true)][string]$Path)

    $environmentInspectionScript = Join-Path $PSScriptRoot 'Test-WindowsOptimizerEnvironment.ps1'
    if (-not (Test-Path -LiteralPath $environmentInspectionScript -PathType Leaf)) {
        throw 'The required output-directory safety validator is unavailable.'
    }

    try {
        Push-Location -LiteralPath $PSScriptRoot
        try {
            $inspectionJson = & .\Test-WindowsOptimizerEnvironment.ps1 -OutputDirectory $Path -AsJson
        }
        finally {
            Pop-Location
        }
        $inspection = $inspectionJson | ConvertFrom-Json -ErrorAction Stop
        if ($null -eq $inspection -or [bool]$inspection.outputDirectoryIsReparsePoint) {
            throw 'The selected output directory did not pass safety validation.'
        }
        return [string]$inspection.outputDirectory
    }
    catch {
        throw 'The selected output directory was rejected by the safety policy.'
    }
}

function Get-SystemSnapshot {
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.List[object]]$Warnings)

    $productName = $null
    $displayVersion = $null
    $buildNumber = $null
    $architecture = $null
    try {
        $version = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop
        $productName = [string]$version.ProductName
        $displayVersion = [string]$version.DisplayVersion
        if ([string]::IsNullOrWhiteSpace($displayVersion)) {
            $displayVersion = [string]$version.ReleaseId
        }
        $buildNumber = [string]$version.CurrentBuildNumber
        if ([string]::IsNullOrWhiteSpace($buildNumber)) {
            $buildNumber = [string]$version.CurrentBuild
        }
    }
    catch {
        Add-BaselineWarning -Warnings $Warnings -Section 'system' -Code 'versionReadUnavailable' -Message 'Windows version information could not be read.'
    }

    try {
        $operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $architecture = [string]$operatingSystem.OSArchitecture
    }
    catch {
        Add-BaselineWarning -Warnings $Warnings -Section 'system' -Code 'architectureReadUnavailable' -Message 'Operating-system architecture could not be read.'
    }

    return [pscustomobject][ordered]@{
        productName = $productName
        displayVersion = $displayVersion
        buildNumber = $buildNumber
        architecture = $architecture
    }
}

function Get-StorageSnapshot {
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.List[object]]$Warnings)

    try {
        $volumes = @(
            Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType = 3' -ErrorAction Stop |
                ForEach-Object {
                    [pscustomobject][ordered]@{
                        volume = [string]$_.DeviceID
                        fileSystem = [string]$_.FileSystem
                        sizeBytes = if ($null -eq $_.Size) { $null } else { [Int64]$_.Size }
                        freeBytes = if ($null -eq $_.FreeSpace) { $null } else { [Int64]$_.FreeSpace }
                    }
                }
        )
        return [pscustomobject][ordered]@{ volumes = $volumes }
    }
    catch {
        Add-BaselineWarning -Warnings $Warnings -Section 'storage' -Code 'volumeReadUnavailable' -Message 'Fixed-volume capacity information could not be read.'
        return [pscustomobject][ordered]@{ volumes = $null }
    }
}

function Get-MemorySnapshot {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.List[object]]$Warnings,
        [Parameter(Mandatory = $true)][int]$RequestedSampleCount,
        [Parameter(Mandatory = $true)][int]$IntervalSeconds,
        [System.Func[object]]$MemoryProvider = [System.Func[object]]{ Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop }
    )

    $samples = [System.Collections.Generic.List[object]]::new()
    for ($sampleIndex = 1; $sampleIndex -le $RequestedSampleCount; $sampleIndex++) {
        try {
            $operatingSystem = $MemoryProvider.Invoke()
            $samples.Add([pscustomobject][ordered]@{
                    totalVisibleBytes = if ($null -eq $operatingSystem.TotalVisibleMemorySize) { $null } else { [Int64]$operatingSystem.TotalVisibleMemorySize * 1KB }
                    freePhysicalBytes = if ($null -eq $operatingSystem.FreePhysicalMemory) { $null } else { [Int64]$operatingSystem.FreePhysicalMemory * 1KB }
                })
        }
        catch {
            Add-BaselineWarning -Warnings $Warnings -Section 'memory' -Code 'sampleReadUnavailable' -Message 'A memory sample could not be read.'
        }

        if ($sampleIndex -lt $RequestedSampleCount) {
            Start-Sleep -Seconds $IntervalSeconds
        }
    }

    return [pscustomobject][ordered]@{
        requestedSampleCount = $RequestedSampleCount
        sampleIntervalSeconds = $IntervalSeconds
        samples = if ($samples.Count -eq 0) { $null } else { @($samples) }
    }
}

function Get-StartupSnapshot {
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.List[object]]$Warnings)

    try {
        $startupItems = @(Get-CimInstance -ClassName Win32_StartupCommand -ErrorAction Stop)
        return [pscustomobject][ordered]@{ startupItemCount = $startupItems.Count }
    }
    catch {
        Add-BaselineWarning -Warnings $Warnings -Section 'startup' -Code 'startupReadUnavailable' -Message 'Startup-item count could not be read.'
        return [pscustomobject][ordered]@{ startupItemCount = $null }
    }
}

function Get-SecuritySnapshot {
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.List[object]]$Warnings)

    $antivirusEnabled = $null
    $realTimeProtectionEnabled = $null
    try {
        $defenderStatus = Get-MpComputerStatus -ErrorAction Stop
        $antivirusEnabled = Get-NullableBooleanProperty -InputObject $defenderStatus -PropertyName 'AntivirusEnabled'
        $realTimeProtectionEnabled = Get-NullableBooleanProperty -InputObject $defenderStatus -PropertyName 'RealTimeProtectionEnabled'
    }
    catch {
        Add-BaselineWarning -Warnings $Warnings -Section 'security' -Code 'defenderReadUnavailable' -Message 'Microsoft Defender status could not be read.'
    }

    $firewallProfileCount = $null
    $enabledFirewallProfileCount = $null
    try {
        $firewallProfiles = @(Get-NetFirewallProfile -ErrorAction Stop)
        $firewallProfileCount = $firewallProfiles.Count
        $enabledFirewallProfileCount = @($firewallProfiles | Where-Object { $_.Enabled -eq $true }).Count
    }
    catch {
        Add-BaselineWarning -Warnings $Warnings -Section 'security' -Code 'firewallReadUnavailable' -Message 'Firewall profile status could not be read.'
    }

    return [pscustomobject][ordered]@{
        defender = [pscustomobject][ordered]@{
            antivirusEnabled = $antivirusEnabled
            realTimeProtectionEnabled = $realTimeProtectionEnabled
        }
        firewall = [pscustomobject][ordered]@{
            profileCount = $firewallProfileCount
            enabledProfileCount = $enabledFirewallProfileCount
        }
    }
}

function Get-NetworkSnapshot {
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.List[object]]$Warnings)

    $adapterCount = $null
    $connectedAdapterCount = $null
    try {
        $adapters = @(Get-NetAdapter -ErrorAction Stop)
        $adapterCount = $adapters.Count
        $connectedAdapterCount = @($adapters | Where-Object { $_.Status -eq 'Up' }).Count
    }
    catch {
        Add-BaselineWarning -Warnings $Warnings -Section 'network' -Code 'adapterReadUnavailable' -Message 'Network-adapter status could not be read.'
    }

    $defaultRouteCount = $null
    try {
        $defaultRouteCount = @(Get-NetRoute -ErrorAction Stop | Where-Object { $_.DestinationPrefix -in @('0.0.0.0/0', '::/0') }).Count
    }
    catch {
        Add-BaselineWarning -Warnings $Warnings -Section 'network' -Code 'routeReadUnavailable' -Message 'Default-route count could not be read.'
    }

    return [pscustomobject][ordered]@{
        adapterCount = $adapterCount
        connectedAdapterCount = $connectedAdapterCount
        defaultRouteCount = $defaultRouteCount
    }
}

function Get-CollectionContext {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.List[object]]$Warnings,
        [Parameter(Mandatory = $true)][string[]]$SelectedSections,
        [Parameter(Mandatory = $true)][int]$RequestedSampleCount,
        [Parameter(Mandatory = $true)][int]$IntervalSeconds
    )

    $isAdministrator = $null
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]::new($identity)
        $isAdministrator = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        Add-BaselineWarning -Warnings $Warnings -Section 'collectionContext' -Code 'elevationReadUnavailable' -Message 'The elevation context could not be read.'
    }

    return [pscustomobject][ordered]@{
        powerShellVersion = $PSVersionTable.PSVersion.ToString()
        isAdministrator = $isAdministrator
        sections = @($SelectedSections)
        sampleCount = $RequestedSampleCount
        sampleIntervalSeconds = $IntervalSeconds
    }
}

function ConvertTo-BaselineMarkdown {
    param([Parameter(Mandatory = $true)][psobject]$Baseline)

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('# Windows 安全优化基线')
    $lines.Add('')
    $lines.Add("- 架构版本：$($Baseline.schemaVersion)")
    $lines.Add("- 生成时间（UTC）：$($Baseline.generatedAt)")
    $lines.Add("- 采集分区：$($Baseline.collectionContext.sections -join ', ')")
    $lines.Add('')

    foreach ($sectionName in @('system', 'storage', 'memory', 'startup', 'security', 'network')) {
        $lines.Add("## $sectionName")
        $section = $Baseline.$sectionName
        if ($null -eq $section) {
            $lines.Add('未采集。')
        }
        else {
            $sectionJson = $section | ConvertTo-Json -Depth 8 -Compress
            $lines.Add('```json')
            $lines.Add($sectionJson)
            $lines.Add('```')
        }
        $lines.Add('')
    }

    $lines.Add('## warnings')
    if (@($Baseline.warnings).Count -eq 0) {
        $lines.Add('无。')
    }
    else {
        foreach ($warning in @($Baseline.warnings)) {
            $lines.Add("- [$($warning.section)/$($warning.code)] $($warning.message)")
        }
    }
    $lines.Add('')
    return ($lines -join [Environment]::NewLine)
}

function Assert-BaselineReportTargetIsAbsent {
    param([Parameter(Mandatory = $true)][string]$Path)

    $existingItem = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if ($null -ne $existingItem) {
        throw 'A baseline report target already exists; reports are never overwritten.'
    }
}

function Open-NewBaselineReport {
    param([Parameter(Mandatory = $true)][string]$Path)

    return [IO.File]::Open(
        $Path,
        [IO.FileMode]::CreateNew,
        [IO.FileAccess]::Write,
        ([IO.FileShare]::Read -bor [IO.FileShare]::Delete)
    )
}

function Remove-NewlyCreatedBaselineReport {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [AllowNull()][IO.FileStream]$Stream
    )

    if ($null -eq $Stream) {
        return
    }

    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if ($null -eq $item -or $item.PSIsContainer -or (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) {
        throw 'A newly created baseline report could not be safely cleaned up.'
    }

    [IO.File]::Delete($Path)
}

function Write-NewBaselineReports {
    param(
        [Parameter(Mandatory = $true)][string]$JsonPath,
        [Parameter(Mandatory = $true)][string]$MarkdownPath,
        [Parameter(Mandatory = $true)][string]$Json,
        [Parameter(Mandatory = $true)][string]$Markdown
    )

    Assert-BaselineReportTargetIsAbsent -Path $JsonPath
    Assert-BaselineReportTargetIsAbsent -Path $MarkdownPath

    $jsonStream = $null
    $markdownStream = $null
    try {
        $jsonStream = Open-NewBaselineReport -Path $JsonPath
        $markdownStream = Open-NewBaselineReport -Path $MarkdownPath

        $utf8WithoutBom = [Text.UTF8Encoding]::new($false)
        $jsonWriter = [IO.StreamWriter]::new($jsonStream, $utf8WithoutBom, 1024, $true)
        try {
            $jsonWriter.Write($Json)
            $jsonWriter.Flush()
        }
        finally {
            $jsonWriter.Dispose()
        }

        $markdownWriter = [IO.StreamWriter]::new($markdownStream, $utf8WithoutBom, 1024, $true)
        try {
            $markdownWriter.Write($Markdown)
            $markdownWriter.Flush()
        }
        finally {
            $markdownWriter.Dispose()
        }
    }
    catch {
        $originalException = $_
        foreach ($createdReport in @(
                [pscustomobject]@{ Path = $markdownPath; Stream = $markdownStream },
                [pscustomobject]@{ Path = $jsonPath; Stream = $jsonStream }
            )) {
            if ($null -ne $createdReport.Stream) {
                Remove-NewlyCreatedBaselineReport -Path $createdReport.Path -Stream $createdReport.Stream
            }
        }
        throw $originalException
    }
    finally {
        if ($null -ne $markdownStream) {
            $markdownStream.Dispose()
        }
        if ($null -ne $jsonStream) {
            $jsonStream.Dispose()
        }
    }
}

$safeOutputDirectory = Resolve-ValidatedOutputDirectory -Path $OutputDirectory
$jsonPath = [IO.Path]::GetFullPath((Join-Path $safeOutputDirectory 'baseline.json'))
$markdownPath = [IO.Path]::GetFullPath((Join-Path $safeOutputDirectory 'baseline.md'))
if (-not [string]::Equals((Split-Path -Parent $jsonPath), $safeOutputDirectory, [StringComparison]::OrdinalIgnoreCase) -or
    -not [string]::Equals((Split-Path -Parent $markdownPath), $safeOutputDirectory, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Baseline report paths did not remain within the validated output directory.'
}

$selectedSections = @(
    $Sections |
        ForEach-Object { $_ -split ',' } |
        ForEach-Object { $_.Trim() } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Select-Object -Unique
)
$validSections = @('System', 'Storage', 'Memory', 'Startup', 'Security', 'Network')
$invalidSections = @($selectedSections | Where-Object { $_ -notin $validSections })
if ($selectedSections.Count -eq 0 -or $invalidSections.Count -ne 0) {
    throw 'Sections must contain one or more supported collector names.'
}
$warnings = [System.Collections.Generic.List[object]]::new()
$baseline = [pscustomobject][ordered]@{
    schemaVersion = '1.0'
    generatedAt = [DateTime]::UtcNow.ToString('o')
    collectionContext = Get-CollectionContext -Warnings $warnings -SelectedSections $selectedSections -RequestedSampleCount $SampleCount -IntervalSeconds $SampleIntervalSeconds
    system = if ($selectedSections -contains 'System') { Get-SystemSnapshot -Warnings $warnings } else { $null }
    storage = if ($selectedSections -contains 'Storage') { Get-StorageSnapshot -Warnings $warnings } else { $null }
    memory = if ($selectedSections -contains 'Memory') { Get-MemorySnapshot -Warnings $warnings -RequestedSampleCount $SampleCount -IntervalSeconds $SampleIntervalSeconds } else { $null }
    startup = if ($selectedSections -contains 'Startup') { Get-StartupSnapshot -Warnings $warnings } else { $null }
    security = if ($selectedSections -contains 'Security') { Get-SecuritySnapshot -Warnings $warnings } else { $null }
    network = if ($selectedSections -contains 'Network') { Get-NetworkSnapshot -Warnings $warnings } else { $null }
    warnings = @($warnings)
}

$json = $baseline | ConvertTo-Json -Depth 8
$markdown = ConvertTo-BaselineMarkdown -Baseline $baseline
Write-NewBaselineReports -JsonPath $jsonPath -MarkdownPath $markdownPath -Json $json -Markdown $markdown
