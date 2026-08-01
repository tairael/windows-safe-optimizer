$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'TestHelpers.ps1')

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$workflowPath = Join-Path $repositoryRoot '.github\workflows\validate.yml'
Assert-True (Test-Path -LiteralPath $workflowPath -PathType Leaf) 'Windows validation workflow is missing'

$expectedWorkflow = @'
name: Validate

on:
  push:
  pull_request:
  workflow_dispatch:

permissions:
  contents: read

jobs:
  validate:
    runs-on: windows-latest
    env:
      WINDOWS_SAFE_OPTIMIZER_CI_ELEVATED: '1'
    steps:
      - name: Check out repository
        uses: actions/checkout@v4

      - name: Run repository tests
        shell: powershell
        run: powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/Run-AllTests.ps1
'@

$workflow = (Get-Content -Raw -LiteralPath $workflowPath) -replace "`r`n", "`n"
$expectedWorkflow = $expectedWorkflow -replace "`r`n", "`n"
Assert-Equal $expectedWorkflow.TrimEnd() $workflow.TrimEnd() 'Windows validation workflow differs from the reviewed least-privilege contract'

'PASS: Windows CI workflow contract'
