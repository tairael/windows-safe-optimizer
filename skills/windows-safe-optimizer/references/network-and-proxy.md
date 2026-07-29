# Network and proxy

## Read first

Describe the failing application, destination class, connection type, affected user, start time, expected duration, and required services before proposing any network change. Map the actual path: name resolution (`DNS`), route and `TCP` connection, `TLS` handshake, application request (`HTTP`), and any long-lived `WebSocket` or `SSE` stream. A single short HTTPS success proves only that particular name, route, TCP/TLS session, and HTTP exchange worked at that moment; it does not prove a proxy upgrade, a stream, a VPN route, or another application works.

Identify whether the application uses its own proxy setting, the Windows system proxy, a PAC file, a named proxy client such as Clash, or a `VPN`/enterprise tunnel. Do not read, request, echo, save, or test a `proxy credential`; use a user-confirmed non-secret indication of authentication success or failure instead. On a managed device, preserve enterprise proxy, VPN, zero-trust, and policy behavior unless the owner and exact authorized object are established.

## Evidence

Record the application and process, destination hostname (redacted if sensitive), protocol, proxy-selection source, network/VPN state, exact symptom, timestamps, and a reproducible test duration. For DNS, compare the expected name resolution result and failure mode without publishing local addresses. For TCP and TLS, record whether the intended host and port can establish a session and whether hostname/certificate validation completes; do not bypass certificate errors. For HTTP, record the expected status or application response without copying authorization headers, cookies, tokens, request bodies, or proxy secrets.

For WebSocket, test the required upgrade plus bidirectional message or application activity over the needed duration. For SSE, test the event-stream response, events or heartbeats, reconnect behavior, and the needed duration. Repeat the same real transport in a fresh application process or session after a justified configuration change. Record an intermittent result, captive portal, DNS failure, proxy authentication result, VPN-policy block, and certificate error as distinct observations rather than treating them as proof of one cause.

## Candidate classes

| Candidate | Evidence needed | Preserve / action boundary | Risk upgrade | Validation | Stop condition |
|---|---|---|---|---|---|
| Transient network or service incident | Timed symptom, affected transport, and a repeat after the suspected interval | Preserve all settings; wait or use the service's supported status path | R0 observation | Repeat the same DNS/TCP/TLS/HTTP or stream test | Stop if the symptom clears without a configuration change |
| Application-specific proxy mismatch | Named process, its documented proxy source, expected destination, and comparison with another path | Change only the identified application setting through its supported interface | R2; raise for unknown ownership, work tooling, or a shared client | Restart the application and repeat its actual transport and duration | Stop if the setting source is uncertain or the required service regresses |
| System proxy, PAC, Clash, or VPN chain | Exact configuration object, owner, original state, policy constraints, and a causal test result | Preserve the current configuration and all credentials; one object only, with restoration recorded first | R3 | Use a fresh process/session and repeat every affected transport | Stop if policy, ownership, rollback, or causality is not proven |
| DNS resolver or route hypothesis | Resolver/path evidence, destination scope, VPN requirement, and no certificate or service-side explanation | Do not alter DNS, TCP parameters, routes, or registry values as a generic fix | R3 | Re-run the original application test and required VPN/enterprise access checks | Stop if the diagnosis is incomplete or a safer owner-supported path exists |

## Preserve

Preserve DNS, TCP defaults, certificate validation, system proxy ownership, proxy authentication boundaries, Clash profiles, VPN/zero-trust access, enterprise policy, and applications that depend on the current path. Do not disable a VPN, remove certificate checks, switch to an unverified resolver, or use registry/TCP tuning folklore to make one request appear faster. A successful direct HTTP request is not permission to bypass the proxy path an application or organization requires.

## Risk upgrades

Raise risk for a system proxy, PAC, proxy client profile, Clash, VPN, route, resolver, certificate store, firewall rule, registry value, managed device, shared network, or unknown setting owner. Classify any configuration change to DNS, TCP, Clash, VPN, proxy, or registry as R3 until the exact object, original state, user impact, backup/rollback, and written authorization for deep-collaboration are established. In conservative-advice or advice-only work, provide diagnosis and manual restoration-aware guidance only; do not execute or suggest a blanket change.

## Validation

Validate the original application in the same user context with a fresh process/session. Re-test the required layers: DNS resolution, TCP reachability, TLS hostname/certificate validation, expected HTTP behavior, and the actual WebSocket or SSE connection lifecycle where those transports are used. Observe the connection for the user-required duration and verify intended VPN, enterprise, and other dependent applications still work. Compare the original symptom and record the exact configuration object changed; do not accept a one-time short HTTPS result as complete validation.

## Stop

Stop when the actual required transport remains healthy for the agreed duration, dependent services work, and no security or policy boundary regresses. Stop without changing configuration when the evidence names no object, the issue is intermittent or external, a credential is required, the device is managed, or the next action would alter Clash, DNS, TCP, VPN, proxy, or registry state without a proven cause and authorized rollback.
