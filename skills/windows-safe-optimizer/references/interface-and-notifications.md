# Interface and notifications

## Read first

Start with the user's stated distraction, workflow, accessibility needs, and `user preference`; do not infer that a sparse desktop is always better. Separate cosmetic interruption reduction from a signal that reports a security, account, backup, sync, recovery, or update failure. A `security notification` or `update notification` is not advertising and must remain visible enough for the real signed-in user to act on it.

Identify whether the target is taskbar/Start content, recommendations, application promotion, ordinary app notification, focus behavior, a `background permission`, or a failure alert. Confirm device ownership and management policy before offering a setting; a work profile, accessibility aid, parental control, or organization policy can make a seemingly cosmetic control operationally important.

## Evidence

Record the exact source/application, notification type, frequency, wording/category, current delivery route, user impact, and required alerts. Distinguish a repeated promotional message from a security, account, backup, sync, update, or recovery failure. Record whether the user needs banners, sound, badges, lock-screen display, taskbar indicators, accessibility announcements, or background activity for a named application.

Use supported Settings or application controls and capture the original state before an approved change. Do not disable a whole notification class just because one item was noisy, and do not interpret a missing alert as a resolved underlying problem. If a message indicates a failed backup, sign-in, update, or security action, preserve the alert and diagnose or route the failure instead of hiding it.

## Candidate classes

| Candidate | Evidence needed | Preserve / action boundary | Risk upgrade | Validation | Stop condition |
|---|---|---|---|---|---|
| Promotional or recommendation content | Exact source, category, frequency, and user preference | Reduce only the identified supported recommendation/advertising surface | R1/R2 if it changes Start/taskbar behavior or a managed policy | Confirm the named distraction stops and navigation/accessibility remain usable | Stop if the surface cannot be distinguished from a required alert |
| Ordinary application notification | Named app, message class, required feature, and delivery preference | Adjust only that application's supported notification options | R2 for background-dependent, work, sync, or accessibility functions | Trigger or observe the relevant normal notification and required app function | Stop if the app's role or alert category is uncertain |
| Background permission or activity | Exact application, purpose, battery/privacy trade-off, and user preference | Change one `background permission` through supported settings; preserve sign-in, sync, call, accessibility, and backup requirements | R2; raise for shared account, managed device, or service dependency | Confirm the foreground and required background function still work | Stop on missed required work, sync, call, backup, or accessibility behavior |
| Security, account, backup, update, or recovery failure alert | Exact failure class, source, ownership, and user-visible impact | Preserve visibility and route to the corresponding security, account, backup, or update guidance | R2/R3 according to the underlying remediation; never mute it as a fix | Confirm the underlying failure is resolved while the alert channel remains available | Stop and seek the owner/vendor when policy, credentials, or recovery authority is required |

## Preserve

Preserve security notification, update notification, account-protection, backup, sync, recovery, sign-in, accessibility, and managed-device alerts. Preserve taskbar and Start access needed for the user's workflow, and preserve an application's required background capability. Do not use registry edits, blanket debloat tools, service changes, or a global "turn off all notifications" action to reduce distraction.

## Risk upgrades

Raise risk for a system-wide notification switch, background permission that supports sync/calls/backup/accessibility, account or work-profile setting, policy-managed device, registry/service setting, or an alert that may report security, account, backup, update, or recovery failure. Treat hiding, disabling, or making these failure notifications inaccessible as R4. An R2 customization needs one named setting, original state, feature impact, user confirmation, reversal, and functional validation; it is not authorization to alter unrelated notification categories.

## Validation

Validate the named interface preference in the real signed-in user's workflow: confirm the unwanted promotional or ordinary app interruption changed as requested, the navigation remains usable, and the affected application still performs its needed foreground/background function. Separately confirm that security, update, account, backup, sync, and recovery alerts still have a visible delivery path. If the original item was a failure alert, validate the underlying condition rather than the absence of the message.

## Stop

Stop when the user preference is met, required workflow and accessibility functions work, and security/update/account/backup/recovery failures remain visible. Stop without changing anything when the alert class is uncertain, a managed policy owns it, a background dependency is unproven, or the proposed reduction would hide a warning instead of resolving its cause.
