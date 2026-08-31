# Does CI actually run `ship-domain.test.ts`?

**Question:** does GitHub CI execute `packages/db/src/ship-domain.test.ts`, or does the suite
silently skip it?

**Verdict: Case A — CI executes it for real.** No CI workflow change is needed. This has been
investigated twice; this document is the record of record so it does not need investigating a
third time (see "Do not re-investigate" below).

## Evidence

Source: the `check` job of PR #269's run, job id `99312350654`, fetched via
`gh api repos/midt-bg/sigma/actions/jobs/99312350654/logs` (`gh run view --log` returned empty
output for this job — use the REST API fallback instead, don't waste a cycle rediscovering that).

Verbatim log lines, in order:

```
cache miss, executing 1a18777a4bcfd8f0
```
Turbo did not replay a cached `@sigma/db:test` result — the test genuinely ran on the runner.

```
> vitest run --coverage
```
The `--coverage` flag reaches vitest through `pnpm test -- --coverage` → `turbo run test --
--coverage`. An earlier "missing second `--`" hypothesis was unfounded.

```
✓ src/ship-domain.test.ts (1 test) 68573ms
✓ preserves multiline text values when shipping to served D1 68570ms
```
The test file and its one test both pass on the runner.

```
Test Files 52 passed (52)
```
All 52 `@sigma/db` test files passed in CI, including `ship-domain.test.ts`.

## Runtime reconciliation: 68.5s in CI vs 200-350s locally

The `check` job's real wall clock was **2m30s** — not the ~100s a prior pass inferred from step
timestamps; that earlier figure was wrong and is corrected here.

`ship-domain.test.ts` drives the real `scripts/ship-domain.mjs`: one `wrangler d1 migrations
apply` plus roughly 55 further `wrangler d1 execute` subprocess round trips. Each round trip pays
wrangler's own CLI cold-start cost. On a GitHub Actions runner that cost is small; in this
devcontainer (slow disk / overlay-fs) it's roughly 5-6s per invocation, which is what turns a
68.5s CI run into 200-350s locally. It is a hardware/IO-speed difference, not a sign that CI is
skipping or faking the test.

## The 52-vs-51 test-file delta

CI reports `Test Files 52 passed (52)` for `@sigma/db`; a local run on
`fix/ship-domain-test-timeout-headroom` reports `51`. Resolved — this is a branch-state
difference, not a coverage-mode or environment-skip artifact.

What was checked:

- `packages/db/vitest.config.ts` sets no `include`/`exclude` override that would change the file
  set under `--coverage`; coverage is applied via `sharedCoverage(['src/**'])`, which is a
  reporting config, not a test-file filter.
- File count on disk at local HEAD: `find src -name '*.test.ts' | wc -l` → **51**.
- File list at PR #269's head commit (`6c4f0d4a824a05055c8c6d2f2b9e480721d5a081`), fetched via
  `git ls-tree -r --name-only 6c4f0d4a... -- packages/db/src`: **52** files.
- Diffing the two lists: PR #269's head has one file that `fix/ship-domain-test-timeout-headroom`
  (based on `origin/main`) does not: `packages/db/src/search-index-sql.test.ts`. Every other file
  matches exactly.

That single extra file fully accounts for the 52-vs-51 delta. It's a complete and benign
explanation: the CI run being cited was on PR #269's branch, which has since added
`search-index-sql.test.ts`; this branch has not picked that file up. No environment-gated skip,
no coverage-mode filtering.

## Do not re-investigate

GitHub Actions log retention expires; the log lines quoted above will eventually disappear from
GitHub. This file is the durable record — cite it instead of re-fetching CI logs. This question
has already cost two prior investigation passes; a third would only re-pay the same cost.

## Noted, not actioned

`scripts/ship-domain.mjs`'s ~56 sequential wrangler subprocess round trips is a real
optimization opportunity (each pays its own CLI cold-start cost) but is separate scope from this
investigation. Not done here.
