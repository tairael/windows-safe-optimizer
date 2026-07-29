# Security and privacy

## Read first

Treat security as a required function, not spare capacity. Establish Windows edition/version, device ownership, management state, and the visible state of `Defender`, `firewall`, `Windows Update`, `UAC`, account protection, encryption, recovery, and relevant privacy controls before proposing a change. Do not weaken a protection to improve a resource number or remove a warning merely because it interrupts the user.

For Windows 10, report the detected version and its real `Windows 10 lifecycle` status from a current authoritative source when available. A version that still starts applications is not necessarily entitled to normal security updates. Do not conceal lifecycle risk by disabling update, security, or support notifications.

## Evidence

Collect only the minimum state needed for the question: protection health and last-known status, firewall profile state, update result/error category, UAC state, recovery/encryption visibility, account-protection warning class, and policy/management indicators. Separate an unreadable status, a policy-controlled setting, a pending restart, an expired support state, and an actual protection failure. Do not collect passwords, recovery keys, security logs containing identities, browser data, tokens, or private network details.

Record the user-visible symptom, the affected control, source and timestamp, required applications, and uncertainty. When a third-party security product or organizational policy owns a control, identify that ownership before offering any setting path. A green UI indicator alone is not proof that every update, recovery, firewall profile, or account safeguard is healthy.

## Candidate classes

| Candidate | Evidence needed | Preserve / action boundary | Risk upgrade | Validation | Stop condition |
|---|---|---|---|---|---|
| Stale or unclear status | Fresh timestamp, source, ownership, and whether a restart or supported check is pending | Refresh or explain through supported Windows/vendor surfaces; preserve protections | R0/R1; raise if policy or a security product owns it | Confirm status is readable and required protection remains enabled | Stop if the source remains unavailable or policy-owned |
| Privacy preference | Exact setting, data/function trade-off, user purpose, and ownership | Change only the named supported privacy preference; preserve security reporting and account recovery | R2 for shared/managed settings or broad diagnostics changes | Re-check the setting and affected feature | Stop if impact or ownership is unclear |
| Update, account, recovery, or encryption warning | Exact warning, version/support state, required backup/recovery path, and policy context | Keep update, account protection, recovery, and encryption paths visible; use the supported owner path | R2; R3 for policy, encryption, identity, or recovery changes | Confirm the warning's real outcome and required sign-in/recovery function | Stop and refer to the owner/vendor if remediation needs credentials, keys, or policy authority |
| Request to disable a core control | Specific claimed symptom and safer diagnostic alternative | Keep Defender, firewall, Windows Update, UAC, encryption, and recovery enabled | R4 | Use read-only evidence or vendor/security support instead | Stop; do not provide a disablement recipe |

## Preserve

Preserve Defender real-time protection, firewall profiles, Windows Update, UAC, device encryption, recovery, account protection, supported security notifications, and managed-device controls. Do not add exclusions, disable services, turn off tamper protection, weaken firewall rules, suppress updates, or lower UAC as an optimization path. Preserve recovery keys and credentials by not reading or copying them; tell the user when the owning administrator or account provider must handle an issue.

## Risk upgrades

Treat security exclusions, firewall rules, identity/account changes, encryption and recovery configuration, policy settings, services, registry values, and enterprise security agents as R3 or R4 according to their protection impact. A request to disable Defender, firewall, Windows Update, UAC, device encryption, or recovery is R4 and must be refused even in deep-collaboration. Raise to R3 for a managed device, unfamiliar product ownership, required credentials, a recovery-key dependency, or an unverified Windows 10 lifecycle claim.

## Validation

After a permitted, supported setting change, confirm the exact intended privacy preference or warning outcome without suppressing the underlying security signal. Verify Defender, firewall, Windows Update, UAC, recovery, account protection, and required applications remain functional; where Windows 10 lifecycle is relevant, state the source/date and remaining limitation rather than inferring support from a UI. Validate in the real signed-in user context and record policy blocks or unreadable state explicitly.

## Stop

Stop when core protection remains enabled, the verified user preference is met, and the security/update/account/recovery state is visible and understood. Stop and escalate to the owner, Microsoft, vendor, or security professional when malware is suspected, a policy controls the device, a key or credential is needed, a protection failure is unresolved, or Windows 10 is outside its supported lifecycle. Do not trade protection for silence, speed, or a cleaner dashboard.
