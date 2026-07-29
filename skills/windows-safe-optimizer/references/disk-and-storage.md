# Disk and storage

## Read first

Establish the affected volume's capacity, `volume free space`, free percentage, target free-space threshold, and required functions before proposing a candidate. Inventory only the agreed scan root and record unreadable locations separately. A directory's `logical size` estimates candidate scope; it is not proof of reclaimable blocks or a substitute for before/after volume readings.

Do not cross a mount, junction, symbolic link, or `reparse point`. Do not inspect, move, or remove a `cloud sync` root or placeholder until the user has explicitly accepted the local and cloud consequence. A healthy volume ends cleanup work; free space is not a reason to keep searching for files to delete.

## Evidence

For each candidate, record its exact identity, owner/application relationship, logical size, volume free space before the action, last-use or installation evidence where available, running-process state, and uncertainty. Match an installed application to its registered entry and its supported maintenance path before treating its files as removable. For a duplicate, record both complete paths, byte size, and hash; equal hashes prove equal bytes, not that either copy is disposable.

Treat an installer, download, cache, temporary item, incomplete download, recycle-bin item, and installed application as different candidate classes. Record access denied, a lock, and an unavailable path as outcomes, not as permission to broaden scope.

## Candidate classes

Use one operation card for each independently recoverable candidate; do not combine a disk sweep into one approval.

| Candidate | Evidence needed | Preserve / action boundary | Risk upgrade | Validation | Stop condition |
|---|---|---|---|---|---|
| Obsolete installer or verified duplicate | Exact path, hash where a retained copy exists, product/install evidence, and volume baseline | Keep one known-good retained copy; remove only the approved file or move it to a recoverable location | R1; raise for unclear ownership, a shared download root, or a reparse point | Confirm the named object changed as approved and re-measure volume free space | Stop if the retained copy or use evidence is uncertain |
| Application no longer wanted | Registered identity, user confirmation, running-process check, and supported removal path | Use `official uninstall` first; preserve shared runtimes, license data, and unrelated folders | R2; raise if removal affects drivers, security, a work profile, or shared components | Verify uninstall status, required applications, and volume free space | Stop if the official path is unavailable or reports an error; investigate before any residual review |
| Residual files after a completed uninstall | Completed uninstall evidence, exact residual ownership, parent boundary, no running process, and no sync/reparse crossing | Manual deletion is a separate, item-specific proposal; never substitute it for official uninstall | R2; raise to R3 for cloud sync, permissions, protected locations, or unclear parent ownership | Confirm only the named residual is gone and dependent apps still work | Stop if ownership, rollback, or feature impact cannot be shown |
| Application-managed cache or temporary files | Official cache location, size, current process state, and feature impact | Prefer the application's supported cache control; keep the parent/application directory | R1; raise for locks, ACLs, update data, or a shared cache | Reopen the application, check its expected function, then compare volume free space | Stop if the cache repopulates normally or the expected gain is too small |
| Incomplete download or recycle-bin item | Status, owning application, age, exact object, and no active transfer | Keep active downloads and any item needed for recovery; empty only approved contents | R1; raise for cloud sync, a shared folder, or unknown file type | Check the transfer/application state and volume free space | Stop if an item is active, ambiguous, or the health threshold is met |

Manual deletion must state the exact object, user context, recoverable backup or why none applies, rollback path, and validation. It is never a bulk fallback for an unavailable uninstall entry.

## Preserve

Preserve Windows and recovery files, the `pagefile`, installed-program directories, shared runtimes, driver and security components, package/installer maintenance stores, application data of unknown ownership, and the user-approved retained copy of any duplicate. Preserve directories even when only their approved cache contents are cleared. Do not infer that a large directory is safe merely because it has an old timestamp.

## Risk upgrades

Raise the candidate risk when it involves cloud sync, a reparse point, a mount, a protected or access-denied location, a managed device, an active process, an uninstall failure, unknown ownership, or an irreversible deletion. An R2/R3 candidate needs the mode-specific confirmation and the backup/rollback reference before any execution. Refuse registry cleaners, recursive root cleanup, broad ownership changes, and one-click cleanup bundles.

## Validation

Compare the same volume's free-space reading immediately before and after the single approved action. Report both the candidate's logical size and the measured volume free-space delta; explain any mismatch without claiming extra benefit. Confirm the approved object state, reopen or exercise the affected application where relevant, and verify sync health when cloud data was in scope. Record a locked or skipped item without retrying through unrelated directories.

## Stop

Stop when the user-selected free-space threshold is healthy, the required functions validate, or the next candidate has uncertain ownership, disproportionate risk, or trivial expected gain. Provide remaining candidates as advice only; do not continue cleanup to maximize a number.
