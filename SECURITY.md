# Security policy

## Scope

`windows-safe-optimizer` is a guidance Skill with two bundled PowerShell scripts for environment checks and read-only baseline collection. Security reports may cover the Skill instructions, references, scripts, installation guidance, public examples, or a workflow that could cause an agent to cross the stated authorization boundary.

The project does not ship a generic mutating cleanup, uninstall, registry, service, permission, proxy, or debloat script.

## Threat model

The main risks are incorrect object identity, broad filesystem traversal, cloud-sync or reparse-point boundaries, unsafe privilege escalation, hidden feature impact, weak rollback, credential disclosure, and instructions that treat a broad request as approval for specific changes.

Expected defenses include:

- platform and device-ownership checks before collection or change;
- explicit selection of `conservative-advice` or `deep-collaboration`;
- R0–R4 classification based on the real target and context;
- one complete operation card before any proposed mutation;
- exact targets, usable backups, rollback steps, fresh validation, and stop conditions;
- refusal of R4 actions even when the user asks for speed, a numeric target, or one-click automation;
- no collection of credentials, browser history, personal content, or unrelated filenames.

## Supported security reports

Please report issues such as:

- a bundled script that changes Windows, application, or user-data state beyond writing reports to the selected directory;
- path handling that accepts a volume root, protected directory, reparse point, or ambiguous output location;
- an instruction that permits mutation without the matching mode and risk confirmation;
- sensitive information included in a report or public example;
- a bypass of the managed-device, enterprise-security, OneDrive, pagefile, proxy-credential, or R4 boundary.

General optimization disagreements without a reproducible safety impact can use the normal contribution process.

## Reporting privately

Use GitHub's private vulnerability reporting for the repository. Include the affected file and revision, a minimal reproduction, expected versus observed behavior, possible impact, and whether the reproduction touched a real computer. Redact usernames, device names, organization details, paths, IP addresses, credentials, and report files.

Do not open a public issue containing an exploitable workflow or private machine data. Do not run a destructive proof of concept to demonstrate impact.

## Response expectations

Maintainers will confirm receipt when the report channel is available, reproduce in an isolated fixture, classify the affected risk gate, and publish a fix or documented limitation when evidence supports it. No fixed response or release deadline is promised for this volunteer project.

## Supported versions

Security fixes target the latest published release and the default branch. Older revisions may receive documentation for migration rather than a backport.

