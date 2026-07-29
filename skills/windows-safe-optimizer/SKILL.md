---
name: windows-safe-optimizer
description: Use when a Windows 10 or Windows 11 computer needs storage cleanup, memory or startup diagnosis, performance tuning, proxy or network troubleshooting, security and privacy review, notification cleanup, app and feature reduction, or new-PC setup.
---

# Windows Safe Optimizer

## Core principle

Optimize from evidence, not folklore. Establish a read-only baseline, protect the functions the user needs, propose the smallest reversible change, validate it with fresh evidence, and stop when the system is healthy or the next gain is not worth the risk. Never treat a lower number, a shorter process list, or more free space as sufficient proof of improvement.

## Platform gate

1. Confirm that the target is a Windows 10 or Windows 11 desktop PC. On any other operating system, Windows Server, or an unknown platform, stop before collecting or changing state and explain that the Skill is out of scope.
2. On Windows 10, report the detected version and its actual Microsoft support status. Do not hide lifecycle risk or imply that a runnable release still receives normal security updates.
3. Identify whether the device is personally controlled or managed by an employer, school, or other organization. Lock a managed device to `conservative-advice` and R0/advice-only work until the user supplies verifiable written authorization naming the exact objects that may change. Even then, keep the normal risk gates and preserve proof that VPN, zero-trust, endpoint security, and policy compliance still work.
4. Confirm the real signed-in user, privilege context, device purpose, functions that must remain available, and any user-selected report directory. Do not request elevation merely to broaden a scan.

## Choose a mode

Make the opening choice explicit before proposing or performing any system change. If the user has not already selected a mode, present both choices and pause mutation work. A request for advice, a follow-up question, or approval to inspect is not approval to change state.

Start the first substantive response with `Mode:` and name the active mode. When an advice-only constraint is present, write `Mode: conservative-advice (advice-only)`, state that no command or mutation will occur, and still explain that `deep-collaboration` is the separately selected alternative for risk-gated execution. When the user has not chosen and no stricter constraint applies, write `Mode: conservative-advice (default pending your choice)`, briefly present both modes, and keep the response within conservative boundaries until the user explicitly switches.

| Mode | Read-only work | R1 | R2 | R3 | R4 |
|---|---|---|---|---|---|
| `deep-collaboration` | Run approved R0 checks and create reports only in the selected directory | Show the complete same-purpose batch, then obtain one confirmation | Obtain confirmation for each named item | Obtain separate authorization for one exact action with current state, impact, backup, rollback, and validation | Refuse |
| `conservative-advice` | Run approved R0 checks and create reports only in the selected directory | Execute only after confirmation | Explain, prepare backup/rollback, and give manual steps; do not execute | Explain, prepare backup/rollback, and give manual steps; do not execute | Refuse |

If no mode is chosen, remain in `conservative-advice`. To execute an R2 or R3 action, require the user to state that they are switching to `deep-collaboration`; never infer the switch. In an advice-only evaluation, give advice only and do not run even R0 system commands.

## Risk levels

Classify the real target and context, not just the command name. Raise risk for unclear ownership, software dependencies, cloud sync, reparse points, permissions, poor rollback, a managed-device policy, or a different execution user.

| Level | Meaning | Typical examples | Gate |
|---|---|---|---|
| R0 | Read-only; no Windows, application, or user-data state change | Capacity, memory, startup, update, and security-state inspection | Automatic only after mode/platform scope is clear; report output is the sole default write |
| R1 | Exact target, verifiable benefit, minimal feature impact, reliable recovery | Official cache controls; a confirmed obsolete installer | Confirm before execution |
| R2 | May change a normal feature or require reconfiguration | Startup items, notification settings, optional features, official uninstall | Per-item confirmation in deep mode; manual guidance only in conservative mode |
| R3 | System configuration, permission, cloud-sync, or critical-network impact | Registry, services, ACLs, OneDrive state, proxy/VPN chain | One exact action and separate authorization in deep mode; manual guidance only in conservative mode |
| R4 | Unacceptable generalization, unprovable benefit, or disproportionate recovery risk | Disabling Defender, UAC, firewall, or updates; registry cleaners; bulk service disabling | Never execute or package as a recipe |

## Universal workflow

1. Pass the platform gate and establish the mode.
2. Record the symptom, device purpose, required functions, target outcome, and a stopping threshold based on user experience or system health. Do not guarantee a requested percentage or chase an arbitrary free-space, memory, process-count, latency, or startup target after evidence says the system is healthy.
3. Select only the relevant module references below. Run environment inspection and baseline collection only when tools, scope, output directory, and the current advice/execute boundary permit it.
4. Separate healthy state, temporary load, measurement noise, and genuine bottlenecks. Record access denied and not found as different outcomes.
5. Present every proposed change as one complete operation card. Do not turn approval of a plan into approval of its actions.
6. Apply the mode and risk gate. Change one independently recoverable target or an explicitly reviewed R1 batch at a time.
7. Validate the same symptom and required functions after each change, using the same real user and comparable conditions. Roll back on regression; stop before adding unrelated tweaks.
8. Finish with the baseline, decisions, exact actions or manual guidance, validation results, unresolved uncertainty, and the reason for stopping.

Use these scenario controls whenever they apply:

- Hibernation or Fast Startup: identify `hiberfil.sys`, measure current size and volume free space, explain both feature impacts, preserve the enable/disable reversal, and validate space plus boot/hibernate behavior. Do not lead with an administrator command.
- Memory or startup: name each process, startup item, scheduled task, or service and explain its owner and purpose. Compare restart-and-idle measurements. Do not guarantee a requested percentage. Treat the pagefile as a protected stability mechanism; never disable it or recommend a memory cleaner to improve a screenshot number.
- Network or proxy: define a reproducible test for the actual transport and duration. Record the original configuration and restoration steps, then change one identified configuration object at a time and repeat the same test in a fresh session when relevant.
- Apps or optional features: derive candidates from the user's actual use. Do not package uninstall, service, startup, notification, and feature changes into a one-click action. Use official uninstall or settings surfaces and require item-level review.
- Duplicate or large-file work: default to reporting. State the exact scan root and exclusions before recursion; do not cross OneDrive or another cloud-sync boundary, mount, junction, symbolic link, or reparse point without separate scope. Show each candidate's full path, hash, and size. A matching hash is evidence of equal bytes, not proof that either copy is disposable. Move only individually approved items to a named recoverable location, then validate volume free space, sync health, and dependent applications.

## Operation card

Output one table per candidate. Fill every field; use `Unknown — verify before action` rather than omitting evidence. The Action row includes the exact object identity, proposed command or manual settings path, execution user, and required privileges.

| Field | Required content |
|---|---|
| Finding | The observed condition, without assuming cause |
| Evidence | Fresh measurement, source, scope, and uncertainty |
| Expected gain | Bounded outcome and why it is plausible; no universal promise |
| Feature impact | User-visible behavior, dependencies, and functions at risk |
| Risk | R0–R4 with context-specific reasons and the applicable mode gate |
| Action | One exact target, method, execution identity, privileges, and batch boundary |
| Backup | Original state plus a verified, user-accessible backup location or `Not applicable` |
| Rollback | Exact restoration steps, prerequisites, and fallback if restoration fails |
| Validation | Before/after metric and functional checks under comparable conditions |
| Stop condition | The success, regression, uncertainty, or diminishing-return condition that ends work |

## Module routing

Read only the references required for the current request. Do not preload all modules.

| User need | Read this reference | Boundary to retain |
|---|---|---|
| Disk pressure, large files, caches, duplicate candidates, volume layout | [Disk and storage](references/disk-and-storage.md) | Distinguish logical size from recovered volume space; respect sync and reparse boundaries |
| High memory, startup load, services, scheduled tasks | [Memory and startup](references/memory-and-startup.md) | Use restart-and-idle evidence; preserve pagefile and core services |
| Slow boot, lag, CPU, storage, power, updates, or thermal clues | [Performance](references/performance.md) | Diagnose the bottleneck before tuning |
| DNS, proxy, Clash, VPN, WebSocket, SSE, or connection instability | [Network and proxy](references/network-and-proxy.md) | Test the real transport; never expose credentials |
| Defender, firewall, Update, UAC, encryption, accounts, or privacy | [Security and privacy](references/security-and-privacy.md) | Preserve security controls and state support facts truthfully |
| Taskbar, Start, recommendations, background permissions, notifications | [Interface and notifications](references/interface-and-notifications.md) | Keep security, update, and account-failure alerts |
| Installed apps, vendor utilities, leftovers, optional Windows features | [Apps and features](references/apps-and-features.md) | Use exact identities and official removal paths |
| First setup, updates, recovery, browser, sources, storage, or role profiles | [New-PC onboarding](references/new-pc-onboarding.md) | Offer choices by use case; do not auto-install a generic list |
| Any planned change, recovery design, identity, or final proof | [Backup, rollback, and validation](references/backup-rollback-validation.md) | Load alongside every R2/R3 proposal and any ambiguous recovery case |

## Forbidden actions

- Never disable or weaken Defender, firewall, UAC, Windows Update, device encryption, account protection, enterprise security, or recovery capability to produce a performance number.
- Never use registry cleaners, memory cleaners, timer/TCP folklore, blanket debloat lists, bulk service changes, broad ACL ownership, or an unreviewed one-click optimizer.
- Never delete an application directory as a substitute for official uninstall, delete an unknown root, recursively follow a reparse point, or treat all duplicate bytes as disposable.
- Never disable the pagefile, alter registry/services/ACLs/cloud sync/proxy as an R1 batch, or provide a generic mutating script for cleanup, uninstall, permissions, or networking.
- Never execute a mutating command before mode selection and the matching operation-card confirmation. Time pressure, administrator status, a numeric target, a broad request, and prior approval of a different action do not relax the gate.

When the user requests an R4 action, refuse that action, explain the concrete failure/recovery risk, and offer the nearest R0/R1 diagnostic or supported settings alternative.

## Privacy boundary

Collect only system state necessary for the named optimization question. Do not read, store, echo, or publish passwords, browser history, cookies, tokens, Wi-Fi passwords, proxy credentials, personal document contents, chat records, or unrelated filenames. Do not connect to the network or send telemetry by default.

Write reports only to a directory the user explicitly selected after validating that it is not a dangerous root or reparse target. Before sharing a report, redact user names, device names, serial numbers, public IP addresses, account identifiers, organization details, and sensitive paths. State exactly what was unreadable instead of requesting broader access.

## Completion checklist

- [ ] Confirm Windows 10/11 scope, lifecycle facts, ownership, user context, and selected mode.
- [ ] Record required functions, baseline evidence, target, uncertainty, and a health-based stop condition.
- [ ] Load only the required modules and preserve managed-device, OneDrive, pagefile, proxy, and reparse-point boundaries.
- [ ] Provide one complete operation card per candidate and obtain the risk-specific confirmation before any mutation.
- [ ] Keep backups and rollback steps usable by the real signed-in user; validate both the metric and affected functions after each action.
- [ ] Report actions not taken, failed or blocked checks, remaining risk, privacy redactions, and why further optimization stopped.
