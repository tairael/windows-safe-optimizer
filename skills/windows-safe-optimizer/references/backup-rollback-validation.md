# Backup, rollback, and validation

## Read first

Load this reference for every R2/R3 proposal and whenever recovery is ambiguous. Before a change, name one `exact target`, its `original state`, the real execution user, required privileges, expected feature impact, `backup`, `rollback`, and the proof that will count as success. A plan or a command is not evidence that the change or recovery actually worked.

Create one machine-specific change record for each independently recoverable change. Its nine required fields are `target`, `objectType`, `before`, `plannedAfter`, `executionContext`, `backup`, `rollback`, `validation`, and `result`. Record a real-user SID only when a machine-specific change requires it to identify the necessary user context; the general baseline collector never collects a real-user SID.

## Evidence

Capture the `exact target` identity and `objectType` before mutation: the supported setting, registered app, Windows feature, file, service, account context, or configuration object actually proposed. In `before`, record the `original state`, source, timestamp, uncertainty, and any required-function baseline. In `executionContext`, record the execution context: user or role, privilege level, mode, ownership/policy constraint, and machine context needed to repeat or reverse the change without exposing secrets.

The `backup` field names the user-accessible backup or records why it is not applicable; it must not be a vague instruction to "make a backup." The `rollback` field gives the exact supported restoration method, prerequisite, and failure fallback. The `validation` field defines comparable functional and measurement checks. `result` records what happened, including no change, failure, policy block, rollback, or successful validation.

## Candidate classes

| Candidate | Evidence needed | Preserve / action boundary | Risk upgrade | Validation | Stop condition |
|---|---|---|---|---|---|
| Supported app or feature setting | `exact target`, `original state`, setting owner, user impact, and supported reversal | Change one named setting and retain its prior state | R2; raise for shared users, policy, or unavailable reversal | Re-check the setting and the affected feature with `fresh evidence` | Stop if ownership or restoration is unclear |
| Official uninstall or optional feature change | Registered identity/feature name, dependencies, removal path, and recoverable prerequisite | Use the official path only; preserve data and shared components outside the named change | R2; raise for drivers, enterprise tools, or dependency chains | Verify product/feature state and required applications after restart if needed | Stop if the official path fails or rollback cannot be prepared |
| System, network, identity, cloud-sync, or permission configuration | Exact configuration object, current value, owner, policy, and a tested restoration path | Keep one object per record; do not batch related settings | R3 | Repeat the original real-user workflow and dependent functions with `fresh evidence` | Stop if authorization, policy, backup, or rollback is incomplete |
| No safe change identified | Evidence that the symptom is healthy, temporary, external, or ambiguous | Preserve current state and record advice only | R0/R1 advice | Record the read-only finding and no-mutation result | Stop without inventing a change to improve a number |

## Preserve

Preserve recovery capability, user data, supported configuration paths, security controls, enterprise access, policy ownership, and the original state until the change has validated. Preserve the ability of the real signed-in user to locate and use the `backup` and `rollback` material; an administrator-only copy is not enough when the affected user needs recovery.

Do not store passwords, recovery keys, tokens, proxy credentials, private document contents, or unnecessary identity data in the record. Do not collect a real-user SID in a general baseline, and do not turn a generic report into a machine-specific change record without a named change.

## Risk upgrades

Raise risk when the `exact target` is a registry value, service, ACL, proxy/VPN chain, cloud-sync setting, recovery or encryption control, managed-device policy, shared application component, or a user-specific object that needs a specific identity context. Raise risk when the `original state` is unreadable, the `backup` is not user-accessible, the `rollback` has not been tested or cannot be described, or validation cannot use the same real user and required feature.

Never treat a broad approval as authorization for several records. An R3 action needs the exact action, current state, impact, `backup`, `rollback`, validation plan, and the applicable deep-collaboration authorization. If any element is unknown, provide advice and stop before mutation.

## Validation

After a permitted change, record `result` only after obtaining `fresh evidence`: collect the same relevant metric or state under comparable conditions and exercise the affected required function in the intended user context. Confirm the `exact target` reached its planned state, the original symptom improved or remained acceptable, and security, recovery, enterprise, and dependent functions did not regress.

If validation fails, execute or provide the recorded `rollback` through the supported path, then collect `fresh evidence` of the restored `original state` and required function. A missing error message, a one-time success, or a changed configuration screen is not complete validation when the real workflow has not been retested.

## Stop

Stop when the one change record is complete, the actual required function has validated with `fresh evidence`, and the user can access the documented `backup` and `rollback` route. Stop and retain the unresolved `result` when a policy block, missing backup, uncertain original state, failed rollback, or feature regression appears. Escalate to the owner or appropriate support path rather than making compensating changes.
