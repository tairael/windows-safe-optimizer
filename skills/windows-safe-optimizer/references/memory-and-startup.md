# Memory and startup

## Read first

Treat a high memory percentage as a symptom, not a diagnosis. Collect a comparable restart-and-idle baseline and the affected workload before considering a change. Read `available memory`, `commit`, and `paging` together with responsiveness and sustained disk activity: high percentage alone can be normal when memory is available and the system is responsive.

Keep the system-managed `pagefile` unless a separately justified, recoverable Windows design decision exists. Do not recommend memory cleaners; forcing memory out of working sets can increase paging and delay the same applications when they need their data again.

## Evidence

Record total memory, available memory, commit charge/limit, paging behavior, uptime, active workload, and a short series of idle samples. Group related browser, WebView, editor, game, and helper processes by `process group`; do not add every child working set and call the sum physical memory usage. Compare the same user context and roughly the same post-restart idle interval before and after a proposed startup change.

Identify each startup item, scheduled task, or service by exact name, publisher/owner, trigger, purpose, and its required feature. Mark an unfamiliar item as unknown rather than assuming it is unnecessary.

## Candidate classes

| Candidate | Evidence needed | Preserve / action boundary | Risk upgrade | Validation | Stop condition |
|---|---|---|---|---|---|
| Foreground workload | Process group, user activity, available memory, commit, and responsiveness | Close only work the user confirms is no longer needed; preserve unsaved documents and sessions | R0 advice; raise if ending it risks data or a shared service | Re-check the same workload metric after a short wait | Stop if responsiveness is healthy or the workload is intentional |
| Optional login startup item | Exact identity, owner, trigger, feature, and user confirmation | Disable one independently recoverable item; preserve sign-in, security, drivers, accessibility, VPN, and required sync | R2 for services/tasks or unclear ownership | Restart, wait at idle, verify the feature and compare baseline | Stop on any lost required function or no meaningful change |
| Nonessential background application | Process group, launch source, purpose, and use frequency | Prefer the application's own setting or official uninstall when the user no longer wants it | R2; raise for managed/work tools, shared components, or privilege changes | Reopen required apps and compare available memory, commit, and paging | Stop if feature impact is uncertain or the saving is trivial |
| Suspected leak or pressure | Repeated samples, growth pattern, commit/paging trend, and reproducible workload | Preserve the pagefile and capture a reproducible case; diagnose the responsible application before tuning Windows | R1 investigation; raise for driver, service, or system-configuration changes | Reproduce after app update, restart, or vendor-supported remediation | Stop when samples are stable or evidence is insufficient to name a cause |

## Preserve

Preserve the pagefile, Windows security and update components, audio/display/input drivers, recovery functions, required enterprise access, and the user's named startup capabilities. Preserve an application's update path and manual launch path when disabling its automatic startup. A service that appears small can still supply a required feature; low memory use is not evidence that it is safe to remove.

## Risk upgrades

Raise risk for startup services, scheduled tasks, drivers, enterprise agents, VPN/zero-trust tools, cloud sync, security components, unknown publishers, and any change requiring elevation. A high percentage with normal available memory, modest commit, stable paging, and no user symptom is not a cleanup candidate. Do not batch startup, service, and uninstall changes together.

## Validation

After one approved change, restart and let the same idle interval pass. Compare available memory, commit, paging, startup behavior, and the required feature against the baseline; account for diagnostic tools opened during collection. Verify the changed item's status and a manual launch or recovery path. If the problem occurs only under workload, repeat that workload instead of treating an idle percentage as proof.

## Stop

Stop when the computer is responsive, memory samples are stable, required functions work, and there is no sustained pressure signal. Stop and roll back when a required feature fails, paging/regressions worsen, or the candidate cannot be identified with evidence. Do not pursue an arbitrary memory percentage.
