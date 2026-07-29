# Performance

## Read first

Name the user-visible symptom and reproduce it under comparable conditions before tuning. A slow boot, lag, low frame rate, long load, noisy fan, or high CPU reading can have different causes. Find the limiting `bottleneck`—CPU, memory pressure, storage latency/capacity, GPU, network, background work, or thermal/power limits—before proposing any change.

Record current power source and `power mode`, active foreground work, background scans/installers, `Windows Update` state, and temperature evidence when available. Do not treat an instantaneous utilization number as a root cause.

## Evidence

Capture the symptom's start/end or frequency, the affected application/version, workload, CPU/GPU/memory/storage indicators, available memory and commit where relevant, and the volume free-space baseline. For suspected thermal limits, record `temperature`, cooling/fan clues, repeatability, and whether performance changes after cool-down; do not infer temperature from fan noise alone. Separate temporary update, indexing, anti-malware, or installation work from persistent behavior by observing completion and re-testing.

## Candidate classes

| Candidate | Evidence needed | Preserve / action boundary | Risk upgrade | Validation | Stop condition |
|---|---|---|---|---|---|
| Temporary background work | Identified updater/scanner/indexer, start/end evidence, and symptom timing | Let supported maintenance complete; preserve security and Windows Update | R0 observation; raise if proposing pause/schedule changes | Re-test the same workload after completion | Stop when the temporary work ends or the symptom disappears |
| Power or battery policy mismatch | Current power mode, power source, workload need, and device/vendor guidance | Use supported Windows/vendor settings; preserve battery, thermal, and sleep safeguards | R1; raise for firmware, BIOS, or vendor-control changes | Repeat workload on the selected policy and check temperature/noise/battery impact | Stop when the desired experience is met or trade-off is unacceptable |
| Capacity or storage-latency pressure | Volume free space, active I/O source, affected path, and comparable load | Free only individually verified storage candidates; preserve system files and app data | R1/R2 per storage candidate; defer to storage reference | Re-measure load time and volume free space | Stop when the capacity threshold is healthy or I/O is no longer the bottleneck |
| Application-specific slowdown | Reproducible workflow, version, process group, extension/add-on evidence, and vendor diagnostics | Prefer supported update, repair, or configuration; preserve user data and rollback | R1; raise for uninstall/reset or data-changing repair | Repeat the same workflow and confirm required features | Stop if the issue is not reproducible or a supported fix cannot be verified |
| Sustained thermal or hardware clue | Repeatable temperature/performance relation, power state, error indicators, and device warranty/support context | Keep thermal protection, firmware safeguards, and hardware support paths intact | R2/R3 for hardware, firmware, driver, or enclosure changes | Re-test under the same load and verify no thermal or stability regression | Stop and refer to vendor/hardware support for persistent thermal, error, or stability signs |

## Preserve

Preserve Defender, firewall, UAC, Windows Update, device encryption, recovery, power/thermal protections, drivers, and vendor-supported maintenance paths. Do not use registry cleaners, blanket service disabling, timer or TCP folklore, or generic debloat packs to improve a benchmark. Keep enough free capacity for normal updates, paging, and application work.

## Risk upgrades

Raise risk for firmware/BIOS, drivers, services, registry changes, cooling hardware, managed-device policy, security controls, and changes with no reversible setting. A suspected temperature issue with shutdowns, crashes, burning smell, battery swelling, repeated disk errors, or data corruption is not an optimization exercise: stop and use appropriate hardware or vendor support. Do not change several subsystems to chase an unproven bottleneck.

## Validation

Validate with the original workload, same power source and power mode, comparable temperature conditions, and the required feature set. Report a bounded before/after result for the actual symptom, plus any trade-off in battery, noise, temperature, stability, or update/security state. Revert a reversible setting if the symptom does not improve or a required function regresses.

## Stop

Use a health-based `stop condition`: stop when the target workload is responsive enough, required functions and security/update state remain healthy, and the identified bottleneck no longer causes the symptom. Stop earlier if the evidence is inconclusive, the next change is higher risk than its plausible gain, or a hardware warning appears.
