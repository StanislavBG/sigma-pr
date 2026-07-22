# Security advisories

## GHSA-f88m-g3jw-g9cj — sharp < 0.35.0 (High, CVSS 7.0)

`sharp` is pulled in transitively via `wrangler` → `miniflare`. It is a dev/build-time
dependency only — it never ships to the deployed Worker. Fixed by pinning a pnpm override:

```yaml
overrides:
  sharp: '^0.35.0'
```

Resolved version across all branches: `sharp@0.35.3`. Verified clean with OSV-Scanner v2.4.0
(`osv-scanner scan source -L pnpm-lock.yaml` → `No issues found`).

Rollout, by branch:

| Branch | Commit SHA |
| --- | --- |
| `fix/bump-sharp-0-35` | `10393ed` |
| `docs/methodology-dashboards` (PR #193) | `5f94c94` |
| `pr/trends` (PR #170) | `9b2d054` |
| `feat/productivity-tools` (PR #206) | `a560c88` |
| `feat/network-force-layout` (PR #144) | `d7b147e` |
