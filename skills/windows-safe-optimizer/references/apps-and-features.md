# Apps and features

## Read first

Start from the user's named workflow and the registered application or Windows feature, not from a folder name, a generic debloat list, or an arbitrary app count. Identify whether the item is an application, vendor utility, `dependency`, `shared component`, driver, enterprise tool, or Windows `optional feature`. A large or unfamiliar item is not evidence that it is safe to remove.

Use `official uninstall` through the product's supported maintenance surface (such as Settings, the vendor uninstaller, or the owning organization) before considering any residual files. Do not delete an application directory to imitate an uninstall. On a managed device, retain VPN, zero-trust, endpoint security, device-management, and policy-related software until ownership and policy are established.

## Evidence

For each candidate, record its exact registered identity, publisher, version, installation or feature source, user purpose, whether it is running, and the supported removal or disablement path. Record the required function, related applications, and whether the item supplies a `dependency` or `shared component` that another retained application could use.

For a Windows `optional feature`, identify the feature name, current state, feature purpose, and affected Windows capability. Distinguish a feature that is merely unused today from one needed for a role, development toolchain, accessibility, recovery path, virtual machine, or enterprise connection. If evidence is unavailable, mark it unknown rather than inferring that removal will free useful space or improve performance.

## Candidate classes

| Candidate | Evidence needed | Preserve / action boundary | Risk upgrade | Validation | Stop condition |
|---|---|---|---|---|---|
| Application the user no longer wants | Registered identity, user confirmation, running-process state, and supported removal path | Use `official uninstall` for one named product; preserve unrelated files and user data unless a separate proposal covers them | R2; raise for drivers, licenses, work profiles, or uncertain ownership | Confirm the registered entry and required applications after removal | Stop if the official path fails or the product identity is uncertain |
| Duplicate-purpose consumer app | User's actual `use case`, feature comparison, and the retained product | Remove only the explicitly rejected product through its supported path | R2; raise for migration data, browser profiles, or shared integrations | Open the retained product and verify the required workflow | Stop if the retained workflow has not been proven |
| Vendor utility or background companion | Exact publisher, device relationship, startup/service role, and user need | Preserve update, firmware, driver, accessibility, and recovery functions | R2; raise for hardware control, security, or an unknown service | Verify device function, updates, and any named vendor feature | Stop if its role cannot be shown |
| `optional feature` | Exact feature name, state, Windows capability, and role impact | Change one supported feature only; preserve recovery, virtualization, accessibility, and required tooling | R2; raise for enterprise policy, development dependencies, or restart impact | Confirm state, restart requirement, and affected capability | Stop if another required use is plausible or validation needs a role not available now |
| Suspected leftover after completed removal | Evidence of completed uninstall, exact ownership, and no running process | Treat residual review as a separate item; never use it as a substitute for uninstall | R2; raise for protected paths, cloud sync, permissions, or unclear parent ownership | Confirm only the approved residual changed and dependent apps work | Stop if ownership or rollback is unclear |

## Preserve

Preserve Windows and recovery components, drivers, security software, shared runtimes, installers needed for repair, application data of unknown ownership, and every `dependency` or `shared component` whose consumers are not identified. Preserve enterprise VPN, zero-trust, endpoint security, device-management, and policy tools until their owner and policy allow a specific change.

Do not remove a Windows `optional feature` simply because it is not visible in the current workflow. Do not remove an app because its installation folder is large, and do not combine uninstall, startup, service, notification, and optional-feature changes into one approval.

## Risk upgrades

Raise the risk for drivers, device utilities, security products, license managers, shared runtimes, `dependency` chains, `shared component` ownership, Windows `optional feature` changes, managed devices, cloud-synced data, unknown publishers, required elevation, or a requested residual deletion. Treat a work application, VPN, zero-trust tool, or security agent as R3 until ownership, policy, exact target, backup, rollback, and the affected access path are established.

An unavailable supported uninstaller is a stop signal for removal, not permission to delete folders, alter services, or run a bulk removal tool. Keep actions item-specific and use the normal mode and confirmation gates.

## Validation

After one approved `official uninstall` or feature change, confirm the exact application or feature state through its supported surface. Reopen each required retained application and test the stated `use case`; for a feature, test the Windows capability it supports. Re-measure storage only when that was an expected gain, and report it separately from functional validation.

For managed or enterprise-adjacent software, validate required sign-in, VPN/zero-trust access, endpoint protection visibility, and policy-dependent work before treating the change as successful. Record a failed uninstall, required restart, or policy block as an outcome; do not escalate to residual deletion automatically.

## Stop

Stop when the user's named application or feature decision is complete, required functions still work, and any expected storage or startup benefit is measured. Stop without removing anything when the identity, `dependency`, `shared component`, `optional feature` impact, enterprise ownership, or rollback path is uncertain. Offer unresolved candidates as advice only.
