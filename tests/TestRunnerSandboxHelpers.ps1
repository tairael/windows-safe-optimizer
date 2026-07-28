Set-StrictMode -Version Latest

function Test-PathStrictlyWithin {
    param(
        [Parameter(Mandatory = $true)][string]$CandidatePath,
        [Parameter(Mandatory = $true)][string]$ParentPath
    )

    $candidate = [IO.Path]::GetFullPath($CandidatePath).TrimEnd('\', '/')
    $parent = [IO.Path]::GetFullPath($ParentPath).TrimEnd('\', '/')
    $parentPrefix = $parent + [IO.Path]::DirectorySeparatorChar
    return $candidate.StartsWith($parentPrefix, [StringComparison]::OrdinalIgnoreCase)
}

function Assert-TestRunnerPathProbe {
    param(
        [Parameter(Mandatory = $true)][string]$RepositoryRoot,
        [Parameter(Mandatory = $true)][string]$TemporaryParent,
        [Parameter(Mandatory = $true)][IO.FileAttributes]$TemporaryParentAttributes,
        [string]$TargetPath,
        [IO.FileAttributes]$TargetAttributes = [IO.FileAttributes]::Normal
    )

    if (-not (Test-PathStrictlyWithin -CandidatePath $TemporaryParent -ParentPath $RepositoryRoot)) {
        throw "Temporary parent is outside the public repository: $TemporaryParent"
    }
    if (($TemporaryParentAttributes -band [IO.FileAttributes]::Directory) -eq 0 -or
        ($TemporaryParentAttributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Temporary parent must be a normal directory: $TemporaryParent"
    }

    if ($PSBoundParameters.ContainsKey('TargetPath')) {
        if (-not (Test-PathStrictlyWithin -CandidatePath $TargetPath -ParentPath $TemporaryParent)) {
            throw "Cleanup target is outside the public repository .tmp directory: $TargetPath"
        }
        if (($TargetAttributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Cleanup target cannot be a reparse point: $TargetPath"
        }
    }
}

function Initialize-TestRunnerTemporaryParent {
    param([Parameter(Mandatory = $true)][string]$RepositoryRoot)

    $repositoryItem = Get-Item -LiteralPath $RepositoryRoot -Force
    if (-not $repositoryItem.PSIsContainer -or (($repositoryItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) {
        throw "Public repository root must be a normal directory: $RepositoryRoot"
    }

    $resolvedRepositoryRoot = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $repositoryItem.FullName).ProviderPath).TrimEnd('\', '/')
    $temporaryParent = [IO.Path]::GetFullPath((Join-Path $resolvedRepositoryRoot '.tmp')).TrimEnd('\', '/')
    if (-not (Test-PathStrictlyWithin -CandidatePath $temporaryParent -ParentPath $resolvedRepositoryRoot)) {
        throw "Temporary parent is outside the public repository: $temporaryParent"
    }

    $created = $false
    if (-not (Test-Path -LiteralPath $temporaryParent)) {
        New-Item -ItemType Directory -Path $temporaryParent | Out-Null
        $created = $true
    }

    $temporaryParentItem = Get-Item -LiteralPath $temporaryParent -Force
    $resolvedTemporaryParent = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $temporaryParentItem.FullName).ProviderPath).TrimEnd('\', '/')
    Assert-TestRunnerPathProbe `
        -RepositoryRoot $resolvedRepositoryRoot `
        -TemporaryParent $resolvedTemporaryParent `
        -TemporaryParentAttributes $temporaryParentItem.Attributes

    return [pscustomobject]@{
        RepositoryRoot = $resolvedRepositoryRoot
        Path = $resolvedTemporaryParent
        Created = $created
    }
}

function Confirm-TestRunnerTemporaryParent {
    param([Parameter(Mandatory = $true)][psobject]$TemporaryParentGuard)

    $repositoryItem = Get-Item -LiteralPath ([string]$TemporaryParentGuard.RepositoryRoot) -Force
    if (-not $repositoryItem.PSIsContainer -or (($repositoryItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) {
        throw "Public repository root must remain a normal directory: $($TemporaryParentGuard.RepositoryRoot)"
    }

    $resolvedRepositoryRoot = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $repositoryItem.FullName).ProviderPath).TrimEnd('\', '/')
    $temporaryParentItem = Get-Item -LiteralPath ([string]$TemporaryParentGuard.Path) -Force
    $resolvedTemporaryParent = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $temporaryParentItem.FullName).ProviderPath).TrimEnd('\', '/')
    Assert-TestRunnerPathProbe `
        -RepositoryRoot $resolvedRepositoryRoot `
        -TemporaryParent $resolvedTemporaryParent `
        -TemporaryParentAttributes $temporaryParentItem.Attributes

    if (-not $resolvedRepositoryRoot.Equals([string]$TemporaryParentGuard.RepositoryRoot, [StringComparison]::OrdinalIgnoreCase) -or
        -not $resolvedTemporaryParent.Equals([string]$TemporaryParentGuard.Path, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Temporary-parent guard paths changed after validation'
    }

    return $TemporaryParentGuard
}

function Assert-TestRunnerCleanupTarget {
    param(
        [Parameter(Mandatory = $true)][psobject]$TemporaryParentGuard,
        [Parameter(Mandatory = $true)][string]$TargetPath
    )

    $confirmedGuard = Confirm-TestRunnerTemporaryParent -TemporaryParentGuard $TemporaryParentGuard
    $targetItem = Get-Item -LiteralPath $TargetPath -Force
    $resolvedTarget = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $targetItem.FullName).ProviderPath).TrimEnd('\', '/')
    Assert-TestRunnerPathProbe `
        -RepositoryRoot ([string]$confirmedGuard.RepositoryRoot) `
        -TemporaryParent ([string]$confirmedGuard.Path) `
        -TemporaryParentAttributes ([IO.FileAttributes]::Directory) `
        -TargetPath $resolvedTarget `
        -TargetAttributes $targetItem.Attributes

    return $resolvedTarget
}

function Remove-TestRunnerTemporaryParentIfOwned {
    param([Parameter(Mandatory = $true)][psobject]$TemporaryParentGuard)

    if (-not [bool]$TemporaryParentGuard.Created) {
        return
    }

    $confirmedGuard = Confirm-TestRunnerTemporaryParent -TemporaryParentGuard $TemporaryParentGuard
    if (@(Get-ChildItem -LiteralPath ([string]$confirmedGuard.Path) -Force).Count -eq 0) {
        Remove-Item -LiteralPath ([string]$confirmedGuard.Path) -Force
    }
}

function New-TestRunnerSandbox {
    param(
        [Parameter(Mandatory = $true)][string]$RepositoryRoot,
        [psobject]$TemporaryParentGuard,
        [scriptblock]$NameFactory = { "runner-empty-suite-$([guid]::NewGuid().ToString('N'))" },
        [int]$MaximumAttempts = 16
    )

    if ($null -eq $TemporaryParentGuard) {
        $TemporaryParentGuard = Initialize-TestRunnerTemporaryParent -RepositoryRoot $RepositoryRoot
    }
    else {
        [void](Confirm-TestRunnerTemporaryParent -TemporaryParentGuard $TemporaryParentGuard)
    }

    $normalizedRepositoryRoot = [string]$TemporaryParentGuard.RepositoryRoot
    $temporaryParent = [string]$TemporaryParentGuard.Path

    for ($attempt = 0; $attempt -lt $MaximumAttempts; $attempt++) {
        $candidateName = [string](& $NameFactory)
        if ($candidateName -notmatch '^runner-empty-suite-[a-zA-Z0-9-]+$') {
            throw "Unsafe runner sandbox name: $candidateName"
        }

        $candidatePath = [IO.Path]::GetFullPath((Join-Path $temporaryParent $candidateName))
        if (-not (Test-PathStrictlyWithin -CandidatePath $candidatePath -ParentPath $temporaryParent)) {
            throw "Runner sandbox candidate is outside the temporary parent: $candidatePath"
        }
        if (Test-Path -LiteralPath $candidatePath) {
            continue
        }

        $createdDirectory = New-Item -ItemType Directory -Path $candidatePath
        $resolvedPath = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $createdDirectory.FullName).ProviderPath).TrimEnd('\', '/')
        if (-not (Test-PathStrictlyWithin -CandidatePath $resolvedPath -ParentPath $temporaryParent)) {
            throw "Resolved runner sandbox is outside the temporary parent: $resolvedPath"
        }
        if (($createdDirectory.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Runner sandbox cannot be a reparse point: $resolvedPath"
        }

        $ownerToken = [guid]::NewGuid().ToString('N')
        $ownerMarker = Join-Path $resolvedPath '.codex-test-owner'
        Set-Content -LiteralPath $ownerMarker -Value $ownerToken -NoNewline

        return [pscustomobject]@{
            Path = $resolvedPath
            RepositoryRoot = $normalizedRepositoryRoot
            TemporaryParent = $temporaryParent
            TemporaryParentCreated = [bool]$TemporaryParentGuard.Created
            TemporaryParentGuard = $TemporaryParentGuard
            OwnerMarker = $ownerMarker
            OwnerToken = $ownerToken
        }
    }

    throw "Could not allocate a unique runner sandbox after $MaximumAttempts attempts"
}

function Remove-TestRunnerSandbox {
    param([Parameter(Mandatory = $true)][psobject]$Sandbox)

    $resolvedSandbox = Assert-TestRunnerCleanupTarget `
        -TemporaryParentGuard $Sandbox.TemporaryParentGuard `
        -TargetPath ([string]$Sandbox.Path)

    $expectedMarker = Join-Path $resolvedSandbox '.codex-test-owner'
    $ownerMarker = Assert-TestRunnerCleanupTarget `
        -TemporaryParentGuard $Sandbox.TemporaryParentGuard `
        -TargetPath ([string]$Sandbox.OwnerMarker)
    if (-not $ownerMarker.Equals($expectedMarker, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Unexpected sandbox ownership marker path: $ownerMarker"
    }
    if (-not (Test-Path -LiteralPath $ownerMarker -PathType Leaf)) {
        throw "Sandbox ownership marker is missing: $ownerMarker"
    }
    if ((Get-Content -LiteralPath $ownerMarker -Raw) -ne [string]$Sandbox.OwnerToken) {
        throw "Sandbox ownership marker does not match this run: $ownerMarker"
    }

    $resolvedSandbox = Assert-TestRunnerCleanupTarget `
        -TemporaryParentGuard $Sandbox.TemporaryParentGuard `
        -TargetPath $resolvedSandbox
    Remove-Item -LiteralPath $resolvedSandbox -Recurse -Force
    Remove-TestRunnerTemporaryParentIfOwned -TemporaryParentGuard $Sandbox.TemporaryParentGuard
}
