[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$OutputDirectory,

    [switch]$AsJson
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-SamePath {
    param(
        [Parameter(Mandatory = $true)][string]$Left,
        [Parameter(Mandatory = $true)][string]$Right
    )

    return [string]::Equals($Left, $Right, [StringComparison]::OrdinalIgnoreCase)
}

function Resolve-SafeOutputDirectory {
    param([Parameter(Mandatory = $true)][string]$Path)

    try {
        $fullPath = [IO.Path]::GetFullPath($Path)
    }
    catch {
        throw "Output directory is not a valid filesystem path: $Path"
    }

    $volumeRoot = [IO.Path]::GetPathRoot($fullPath)
    if (Test-SamePath -Left $fullPath -Right $volumeRoot) {
        throw "Output directory cannot be a volume root: $fullPath"
    }

    foreach ($protectedDirectory in @(
            $env:windir,
            $env:ProgramFiles,
            [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
        )) {
        if (-not [string]::IsNullOrWhiteSpace($protectedDirectory)) {
            $protectedFullPath = [IO.Path]::GetFullPath($protectedDirectory)
            if (Test-SamePath -Left $fullPath -Right $protectedFullPath) {
                throw "Output directory is protected and cannot be used: $fullPath"
            }
        }
    }

    try {
        $item = Get-Item -LiteralPath $fullPath -Force -ErrorAction Stop
    }
    catch {
        throw "Output directory must already exist and be accessible: $fullPath"
    }

    if (-not $item.PSIsContainer) {
        throw "Output directory must be a directory: $fullPath"
    }
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Output directory cannot be a reparse point: $fullPath"
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
        $supportedOS = ($productName -match '^Windows (10|11)\\b')
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
