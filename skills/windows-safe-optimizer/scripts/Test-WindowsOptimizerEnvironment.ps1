[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$OutputDirectory,

    [switch]$AsJson
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function ConvertTo-NormalizedFileSystemPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $fullPath = [IO.Path]::GetFullPath($Path)
    $volumeRoot = [IO.Path]::GetPathRoot($fullPath)
    if ([string]::Equals($fullPath, $volumeRoot, [StringComparison]::OrdinalIgnoreCase)) {
        return $volumeRoot
    }

    return $fullPath.TrimEnd([char[]]@([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar))
}

function Test-SamePath {
    param(
        [Parameter(Mandatory = $true)][string]$Left,
        [Parameter(Mandatory = $true)][string]$Right
    )

    $normalizedLeft = ConvertTo-NormalizedFileSystemPath -Path $Left
    $normalizedRight = ConvertTo-NormalizedFileSystemPath -Path $Right
    return [string]::Equals($normalizedLeft, $normalizedRight, [StringComparison]::OrdinalIgnoreCase)
}

function Test-SamePathOrChildPath {
    param(
        [Parameter(Mandatory = $true)][string]$Candidate,
        [Parameter(Mandatory = $true)][string]$Parent
    )

    $normalizedCandidate = ConvertTo-NormalizedFileSystemPath -Path $Candidate
    $normalizedParent = ConvertTo-NormalizedFileSystemPath -Path $Parent
    if ([string]::Equals($normalizedCandidate, $normalizedParent, [StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }

    $parentPrefix = $normalizedParent + [IO.Path]::DirectorySeparatorChar
    return $normalizedCandidate.StartsWith($parentPrefix, [StringComparison]::OrdinalIgnoreCase)
}

function Test-SupportedWindowsProductName {
    param([AllowNull()][string]$ProductName)

    return -not [string]::IsNullOrWhiteSpace($ProductName) -and $ProductName -match '^Windows (10|11)\b'
}

function Resolve-SafeOutputDirectory {
    param([Parameter(Mandatory = $true)][string]$Path)

    try {
        $fullPath = ConvertTo-NormalizedFileSystemPath -Path $Path
    }
    catch {
        throw "Output directory is not a valid filesystem path: $Path"
    }

    $volumeRoot = ConvertTo-NormalizedFileSystemPath -Path ([IO.Path]::GetPathRoot($fullPath))
    if (Test-SamePath -Left $fullPath -Right $volumeRoot) {
        throw "Output directory cannot be a volume root: $fullPath"
    }

    foreach ($protectedDirectory in @(
            $env:windir,
            $env:ProgramFiles,
            ${env:ProgramFiles(x86)},
            $env:ProgramW6432
        ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique) {
        if (-not [string]::IsNullOrWhiteSpace($protectedDirectory)) {
            $protectedFullPath = ConvertTo-NormalizedFileSystemPath -Path $protectedDirectory
            if (Test-SamePathOrChildPath -Candidate $fullPath -Parent $protectedFullPath) {
                throw "Output directory is protected and cannot be used: $fullPath"
            }
        }
    }

    $profileRoot = [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
    if (-not [string]::IsNullOrWhiteSpace($profileRoot) -and (Test-SamePath -Left $fullPath -Right $profileRoot)) {
        throw "Output directory is protected and cannot be used: $fullPath"
    }

    $relativePath = $fullPath.Substring($volumeRoot.Length)
    $segments = @($relativePath -split '[\\/]+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $currentPath = $volumeRoot
    $item = $null
    foreach ($segment in $segments) {
        $currentPath = Join-Path -Path $currentPath -ChildPath $segment
        try {
            $item = Get-Item -LiteralPath $currentPath -Force -ErrorAction Stop
        }
        catch {
            throw "Output directory must already exist and be accessible: $fullPath"
        }

        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Output directory cannot contain a reparse point: $currentPath"
        }
    }

    if ($null -eq $item -or -not $item.PSIsContainer) {
        throw "Output directory must be a directory: $fullPath"
    }

    return [pscustomobject]@{
        Path = $fullPath
        IsReparsePoint = $false
    }
}

function Get-WindowsVersionInfo {
    $warnings = [Collections.Generic.List[string]]::new()
    $productName = $null
    $displayVersion = $null
    $buildNumber = $null

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
    catch [System.UnauthorizedAccessException] {
        $warnings.Add('Windows version registry read was denied; version support could not be determined.')
    }
    catch {
        $warnings.Add("Windows version registry read failed: $($_.Exception.Message)")
    }

    $supportedOS = $null
    if (-not [string]::IsNullOrWhiteSpace($productName)) {
        $supportedOS = Test-SupportedWindowsProductName -ProductName $productName
    }

    return [pscustomobject]@{
        SupportedOS = $supportedOS
        ProductName = $productName
        DisplayVersion = $displayVersion
        BuildNumber = $buildNumber
        Warnings = @($warnings)
    }
}

function Get-IsAdministrator {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]::new($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

$safeOutputDirectory = Resolve-SafeOutputDirectory -Path $OutputDirectory
$windowsVersion = Get-WindowsVersionInfo

$result = [pscustomobject]@{
    schemaVersion = '1.0'
    supportedOS = $windowsVersion.SupportedOS
    productName = $windowsVersion.ProductName
    displayVersion = $windowsVersion.DisplayVersion
    buildNumber = $windowsVersion.BuildNumber
    powerShellVersion = $PSVersionTable.PSVersion.ToString()
    isAdministrator = Get-IsAdministrator
    outputDirectory = $safeOutputDirectory.Path
    outputDirectoryIsReparsePoint = $safeOutputDirectory.IsReparsePoint
    warnings = @($windowsVersion.Warnings)
}

if ($AsJson) {
    $result | ConvertTo-Json -Compress -Depth 3
}
else {
    $result
}
