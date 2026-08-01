![Windows Safe Optimizer](assets/banner.svg)

# Windows Safe Optimizer

[简体中文](README.md) · English

A safety-first Agent Skill for diagnosing and improving Windows 10/11 PCs with read-only baselines, explicit risk gates, rollback plans, and fresh validation.

The package covers storage, memory and startup, performance, network and proxy behavior, security and privacy, interface noise, installed apps and optional features, new-PC setup, and recovery. It does not bundle a one-click debloater or a generic mutating cleanup script.

## Installation

In PowerShell, disable optional telemetry from the third-party installer for this session, then install the Skill for Codex:

```powershell
$env:DO_NOT_TRACK = '1'
npx skills add tairael/windows-safe-optimizer --skill windows-safe-optimizer -g -a codex
```

The bundled Skill scripts do not connect to the network or include telemetry. The separate `skills` CLI may have its own telemetry policy, so `DO_NOT_TRACK=1` is recommended. Review the current installer policy before running it.

First prompt:

```text
Use windows-safe-optimizer on this Windows 11 PC.
Choose conservative-advice. My system drive is low on space, but OneDrive, hibernation, and my development tools must keep working. Run read-only checks first and create a report.
```

## Modes

| Mode | R0 read-only | R1 low risk | R2 medium risk | R3 high risk | R4 prohibited |
|---|---|---|---|---|---|
| `conservative-advice` | Run after scope is clear | Execute after confirmation | Manual guidance only | Manual guidance only | Refuse |
| `deep-collaboration` | Run after scope is clear | Review a same-purpose batch, then confirm | Confirm each exact item | Separate authorization for one exact, backed-up action | Refuse |

If no mode is selected, the Skill stays in `conservative-advice`. A question, a request to inspect, or permission for one earlier action does not authorize later changes.

## Modules

| | Module | Main boundary |
|---|---|---|
| 💽 | Disk and storage | Respect cloud-sync and reparse-point boundaries |
| 🧠 | Memory and startup | Preserve the pagefile; compare restart-and-idle evidence |
| ⚡ | Performance | Diagnose the bottleneck before tuning |
| 🌐 | Network and proxy | Test the real transport without exposing credentials |
| 🛡️ | Security and privacy | Preserve Defender, firewall, Update, UAC, and encryption |
| 🎛️ | Interface and notifications | Keep security and account-failure alerts |
| 🧩 | Apps and features | Use official removal paths and exact component identities |
| 🌱 | New-PC onboarding | Start with updates, recovery, backup, and user role |
| ↩️ | Backup and validation | Load for every R2/R3 proposal and ambiguous recovery case |

## Safety

The Skill classifies the actual target and context from R0 to R4. It never executes R4 requests such as disabling Defender, UAC, the firewall, Windows Update, or device encryption; using registry or memory cleaners; bulk-disabling services; taking broad ownership of a directory tree; or deleting an application folder as an uninstall method.

Managed work or school devices stay advice-only until ownership, policy, and written authorization for exact targets can be verified. Every proposed change includes feature impact, backup, rollback, validation, and a stop condition.

See [SECURITY.md](SECURITY.md) for the threat model and private reporting route.

## Privacy

The Skill does not read passwords, browser history, cookies, tokens, Wi-Fi passwords, proxy credentials, personal document contents, or chat records. The baseline collector does not connect to the network. Reports are written only to an existing directory selected by the user and should be redacted before sharing.

## Support status

- Windows 11 desktop editions are supported, subject to version, permissions, policy, and vendor customization.
- Windows 10 can still be diagnosed, but standard support ended on October 14, 2025. The Skill must report the detected release, ESU eligibility, and real security-update status without hiding lifecycle risk.
- Windows Server, macOS, and Linux are outside the Skill's scope.
- PowerShell scripts target Windows PowerShell 5.1 or later.

This project cannot replace incident response, hardware repair, enterprise administration, or data-recovery services.

## Contributing and license

Read [CONTRIBUTING.md](CONTRIBUTING.md) before proposing optimization guidance. Every change needs evidence, scope, risk, rollback, privacy review, and tests. Licensed under the [MIT License](LICENSE).

