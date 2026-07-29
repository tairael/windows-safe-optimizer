# New-PC onboarding

## Read first

Begin a new PC in this order: updates, security, `recovery`, `backup`, and the real signed-in user role. Then ask for the person's `use case` (for example, office work, gaming, development, school, or a shared family device), required applications, organization ownership, storage needs, and support constraints. A setup request is not permission to change every default or install an unreviewed collection of software.

Establish a supported `software source` for each needed application: Microsoft Store, the publisher's official site, an organization-managed catalog, or another owner-approved source. Do not install a generic app bundle. Keep enterprise VPN, zero-trust, endpoint security, device-management, and policy tooling unchanged until ownership and policy are explicit.

## Evidence

Record Windows edition/version, update state, security-control visibility, device ownership/management state, available `recovery` path, intended `backup` method, signed-in user role, and the agreed `use case`. For `storage layout`, record the available volumes, capacity/free-space baseline, expected data location, sync boundary, and whether an external or cloud location is user-controlled and recoverable.

For software, record the named application, purpose, publisher, approved `software source`, licensing/account prerequisite, and whether it is personal, work-managed, or security-sensitive. Do not collect credentials, recovery keys, personal documents, browser data, or an unnecessary real-user SID while establishing this general baseline.

## Candidate classes

| Candidate | Evidence needed | Preserve / action boundary | Risk upgrade | Validation | Stop condition |
|---|---|---|---|---|---|
| Windows updates and restart readiness | Current update state, active work, power/network condition, and restart impact | Use supported Windows update controls; preserve security/update safeguards | R1/R2 for disruptive restart or policy ownership | Confirm update outcome and normal sign-in after any required restart | Stop if policy, an error, or a support boundary needs the owner |
| Security and account foundation | Visible Defender, firewall, UAC, encryption, account-protection, and ownership state | Keep protections enabled and use supported owner paths | R2/R3 for policy, identity, encryption, or recovery changes | Confirm protections and required sign-in remain available | Stop if credentials, keys, or policy authority are needed |
| `recovery` and `backup` readiness | Available recovery method, user-accessible backup destination, restore scope, and role requirements | Preserve recovery capability; select or explain one appropriate supported backup approach | R2/R3 for encryption, cloud ownership, or recovery-account changes | Verify the chosen destination is usable and explain a restore test | Stop if the user cannot access recovery or the backup destination |
| `storage layout` choice | Volume baseline, expected data size, sync/offline need, and application requirements | Keep system, recovery, sync, and application boundaries intact; make one named layout choice | R1/R2; raise for repartitioning, cloud sync, or managed storage | Verify intended save location, free space, and sync/backup behavior | Stop if recovery or data ownership would become unclear |
| Needed application | Named `use case`, publisher, approved `software source`, and license/account requirement | Install or advise on one approved application only; keep enterprise/security tooling intact | R2; raise for admin rights, drivers, work software, or unknown source | Launch the app and test its named use | Stop if source, license, policy, or role is unknown |

## Preserve

Preserve Windows Update, Defender, firewall, UAC, encryption, `recovery`, account protection, device drivers, supported vendor maintenance paths, and the user's ability to restore data. Preserve a clear boundary between system files, applications, personal data, cloud-sync data, and backup copies in the `storage layout`.

Preserve enterprise VPN, zero-trust access, endpoint security, device management, certificates, and policy-managed settings until the organization owner confirms their purpose and allowed change. Do not remove optional Windows capabilities merely because the new `use case` has not needed them yet.

## Risk upgrades

Raise risk for a managed PC, organization account, enterprise VPN or zero-trust client, endpoint security, device management, encryption, recovery configuration, partitioning, cloud-sync ownership, an unknown `software source`, drivers, or a request for a generic app bundle. These conditions require the matching risk gate and may require the owner rather than local optimization.

Do not bypass a security warning, disable updates, use a script to install an unreviewed bundle, copy credentials, or create a new backup destination whose ownership and restore path are not clear. A request to "set up everything" still needs named, separately reviewable choices.

## Validation

Validate the foundation in the real user context: updates reach their supported state, core security controls remain enabled, `recovery` is visible, the selected `backup` destination is accessible, and the signed-in user can perform the named `use case`. For a `storage layout` decision, save and reopen a harmless test item in the intended location and confirm that sync/backup behavior matches the chosen boundary.

Validate each installed application against its approved `software source` and intended purpose; do not accept installation success as proof of usability. For enterprise-adjacent systems, verify only the access and protection checks authorized by the owner, and retain any policy block as an unresolved outcome.

## Stop

Stop when the update, security, `recovery`, `backup`, user-role, `use case`, `storage layout`, and approved software-source foundations are understood and the required functions work. Do not continue into convenience installs or broad personalization merely because the machine is new. Stop and route to the owner when enterprise VPN, zero-trust, security, or policy ownership remains unclear.
