# Contributing

Contributions are welcome when they make the Skill safer, more accurate, or easier to verify. A familiar tweak is not enough by itself: Windows advice changes with version, device ownership, installed software, user purpose, execution identity, and recovery options.

## Before opening a change

1. Choose the single module that owns the behavior. Cross-module rules belong in `SKILL.md` only when every module must follow them.
2. State the supported Windows versions, device context, exact target type, prerequisites, and exclusions.
3. Provide a primary source, reproducible observation, or controlled fixture. Remove machine-specific paths, names, identifiers, network addresses, and credentials.
4. Classify R0–R4 from the real impact. Document feature impact, backup, rollback, validation, and the condition that stops further work.
5. Check that the proposal still behaves safely on a managed device, with OneDrive or another sync provider, across a reparse point, and under a non-administrator user when those contexts apply.

Do not contribute registry-cleaner rules, memory cleaners, generic debloat lists, blanket service changes, broad permission takeover, security-control bypasses, or deletion of application directories as an uninstall method.

## Tests

Run the complete public suite from the repository root:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-AllTests.ps1
```

For a new recommendation, add or update the smallest contract test that proves its safety boundary. For script changes, include parser checks, a controlled fixture, and before/after evidence that no Windows, application, or user-data state changed. For documentation changes, keep relative links valid and render affected Mermaid or SVG content.

## Privacy review

Before submitting, scan every changed file for usernames, device names, SIDs, serial numbers, organization names, public IP addresses, credentials, tokens, real proxy URLs, local absolute paths, and raw reports. Use fictional values in examples and say that they are fictional.

## Pull request notes

Explain the problem with one concrete scenario. Then list the evidence, affected risk level, behavior before and after, tests run, privacy review result, and rollback for the contribution itself. Screenshots should show public fixtures only.

Keep prose direct and follow [docs/writing-style.md](docs/writing-style.md). By contributing, you agree that your work may be distributed under the repository's [MIT License](LICENSE).

