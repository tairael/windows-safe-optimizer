Set-StrictMode -Version Latest

$script:BlockedPublicPathRegexes = @(
    [regex]::new(
        '(?:^|[\\/])(?:01-需求|02-方案|05-测试与验证|06-交付物|99-临时文件|\.superpowers)(?:[\\/]|$)',
        [Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [Text.RegularExpressions.RegexOptions]::CultureInvariant
    ),
    [regex]::new(
        '(?:^|[\\/])(?:task-1-report|skill-baseline-results|skill-baseline-scenarios)(?:\.[^\\/]+)?(?:[\\/]|$)',
        [Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
)

function Test-PublicSourcePathBlocked {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$RelativePath)

    foreach ($regex in $script:BlockedPublicPathRegexes) {
        if ($regex.IsMatch($RelativePath)) {
            return $true
        }
    }

    return $false
}

function Assert-PublicRelativePathAllowed {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$Source
    )

    if (Test-PublicSourcePathBlocked -RelativePath $RelativePath) {
        throw "Internal evidence is present in the $Source scan: $RelativePath"
    }
}

function Assert-PublicFileSystemEntriesAllowed {
    param(
        [Parameter(Mandatory = $true)][string]$RepositoryRoot,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]]$Entries
    )

    $normalizedRoot = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd('\', '/')
    $rootPrefix = $normalizedRoot + [IO.Path]::DirectorySeparatorChar

    foreach ($entry in $Entries) {
        $attributes = [IO.FileAttributes]$entry.Attributes
        if (($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Reparse points and symbolic links are not allowed in public source: $($entry.FullName)"
        }

        $normalizedPath = [IO.Path]::GetFullPath([string]$entry.FullName)
        if ($normalizedPath.Equals($normalizedRoot, [StringComparison]::OrdinalIgnoreCase)) {
            $relativePath = ''
        }
        elseif ($normalizedPath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            $relativePath = $normalizedPath.Substring($rootPrefix.Length)
        }
        else {
            throw "File-system entry is outside the public source root: $normalizedPath"
        }

        Assert-PublicRelativePathAllowed -RelativePath $relativePath -Source 'file-system'
    }
}

function Assert-PublicTrackedPathsAllowed {
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$RelativePaths)

    foreach ($relativePath in $RelativePaths) {
        Assert-PublicRelativePathAllowed -RelativePath $relativePath -Source 'Git tracked-path'
    }
}

function Assert-PublicTrackedEntriesAllowed {
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]]$Entries)

    foreach ($entry in $Entries) {
        if ([string]$entry.Mode -notin @('100644', '100755')) {
            throw "Unsupported Git entry mode in public source: $($entry.Mode) $($entry.Path)"
        }

        Assert-PublicRelativePathAllowed -RelativePath ([string]$entry.Path) -Source 'Git tracked-path'
    }
}

function Get-PublicSourceEntries {
    param([Parameter(Mandatory = $true)][string]$RepositoryRoot)

    $normalizedRoot = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd('\', '/')
    $pendingDirectories = [Collections.Generic.Stack[string]]::new()
    $pendingDirectories.Push($normalizedRoot)

    while ($pendingDirectories.Count -gt 0) {
        $currentDirectory = $pendingDirectories.Pop()
        $children = @(Get-ChildItem -LiteralPath $currentDirectory -Force -ErrorAction Stop)

        foreach ($child in $children) {
            if ($currentDirectory.Equals($normalizedRoot, [StringComparison]::OrdinalIgnoreCase) -and $child.Name -eq '.git') {
                continue
            }

            Write-Output $child

            $isReparsePoint = (($child.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)
            if ($child.PSIsContainer -and -not $isReparsePoint) {
                $pendingDirectories.Push($child.FullName)
            }
        }
    }
}
