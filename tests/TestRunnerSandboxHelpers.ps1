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

function New-TestRunnerSandbox {
    param(
        [Parameter(Mandatory = $true)][string]$RepositoryRoot,
        [scriptblock]$NameFactory = { "runner-empty-suite-$([guid]::NewGuid().ToString('N'))" },
        [int]$MaximumAttempts = 16
    )

    $normalizedRepositoryRoot = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd('\', '/')
    $temporaryParent = [IO.Path]::GetFullPath((Join-Path $normalizedRepositoryRoot '.tmp')).TrimEnd('\', '/')
    if (-not (Test-PathStrictlyWithin -CandidatePath $temporaryParent -ParentPath $normalizedRepositoryRoot)) {
        throw "Temporary parent is outside the public repository: $temporaryParent"
    }

    $temporaryParentCreated = $false
    if (Test-Path -LiteralPath $temporaryParent) {
        $temporaryParentItem = Get-Item -LiteralPath $temporaryParent -Force
        if (-not $temporaryParentItem.PSIsContainer -or (($temporaryParentItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) {
            throw "Temporary parent must be a normal directory: $temporaryParent"
        }
    }
    else {
        New-Item -ItemType Directory -Path $temporaryParent | Out-Null
        $temporaryParentCreated = $true
    }

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
            TemporaryParentCreated = $temporaryParentCreated
            OwnerMarker = $ownerMarker
            OwnerToken = $ownerToken
        }
    }

    throw "Could not allocate a unique runner sandbox after $MaximumAttempts attempts"
}

function Remove-TestRunnerSandbox {
    param([Parameter(Mandatory = $true)][psobject]$Sandbox)

    $repositoryRoot = [IO.Path]::GetFullPath([string]$Sandbox.RepositoryRoot).TrimEnd('\', '/')
    $expectedTemporaryParent = [IO.Path]::GetFullPath((Join-Path $repositoryRoot '.tmp')).TrimEnd('\', '/')
    $temporaryParent = [IO.Path]::GetFullPath([string]$Sandbox.TemporaryParent).TrimEnd('\', '/')
    if (-not $temporaryParent.Equals($expectedTemporaryParent, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Sandbox temporary parent is not the public repository .tmp directory: $temporaryParent"
    }

    $resolvedTemporaryParent = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $temporaryParent).ProviderPath).TrimEnd('\', '/')
    $resolvedSandbox = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath ([string]$Sandbox.Path)).ProviderPath).TrimEnd('\', '/')
    if (-not (Test-PathStrictlyWithin -CandidatePath $resolvedTemporaryParent -ParentPath $repositoryRoot)) {
        throw "Resolved temporary parent is outside the public repository: $resolvedTemporaryParent"
    }
    if (-not (Test-PathStrictlyWithin -CandidatePath $resolvedSandbox -ParentPath $resolvedTemporaryParent)) {
        throw "Resolved runner sandbox is outside the public repository .tmp directory: $resolvedSandbox"
    }

    foreach ($path in @($resolvedTemporaryParent, $resolvedSandbox)) {
        $item = Get-Item -LiteralPath $path -Force
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Refusing to clean a reparse point: $path"
        }
    }

    $expectedMarker = Join-Path $resolvedSandbox '.codex-test-owner'
    $ownerMarker = [IO.Path]::GetFullPath([string]$Sandbox.OwnerMarker)
    if (-not $ownerMarker.Equals($expectedMarker, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Unexpected sandbox ownership marker path: $ownerMarker"
    }
    if (-not (Test-Path -LiteralPath $ownerMarker -PathType Leaf)) {
        throw "Sandbox ownership marker is missing: $ownerMarker"
    }
    if ((Get-Content -LiteralPath $ownerMarker -Raw) -ne [string]$Sandbox.OwnerToken) {
        throw "Sandbox ownership marker does not match this run: $ownerMarker"
    }

    Remove-Item -LiteralPath $resolvedSandbox -Recurse -Force
    if ([bool]$Sandbox.TemporaryParentCreated -and @(Get-ChildItem -LiteralPath $resolvedTemporaryParent -Force).Count -eq 0) {
        Remove-Item -LiteralPath $resolvedTemporaryParent -Force
    }
}
