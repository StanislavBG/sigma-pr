# Local working conventions (not committed)

Personal/working guidance for agents in this repo. Complements the checked-in
[AGENTS.md](AGENTS.md) — where they overlap, AGENTS.md wins for repo mechanics; this file
captures how we collaborate. **Sigma is a shared public project** (upstream `midt-bg/sigma` +
external contributors), **not solo development.** Optimize for the team, not for throughput.

## Pull requests: fewer, not more

A PR is a request for other people's time and CI. Minimize the count.

- **Consolidate related work into ONE PR.** Several fixes to the same file/subsystem (e.g. the
  ETL identity fixes to `normalize-raw.sql`) belong in a single reviewable PR, not one-per-issue.
  One _logical_ change per PR — but "logical" means the smallest thing a reviewer can approve as a
  unit, not the smallest diff.
- **Never open a duplicate PR of someone else's work** without a stated reason. If a contributor
  already has a PR open, help _that_ PR — don't recreate it.
- **Superseded PRs get closed immediately** with a comment pointing to the replacement (as #205/#207
  were folded into #203). Don't leave redundant PRs open.
- **Don't split to look busy.** This is not a PR competition. If in doubt, combine and ask.
- **Open a PR only when asked**, per AGENTS.md. Pushing a branch ≠ opening a PR.

## Working with contributors' PRs and forks

- **Check push access before planning a rebase.** We (`StanislavBG`) have pull-only on `midt-bg`
  and on contributor forks; `maintainerCanModify=true` does _not_ help (it needs base-repo write).
  We can only push to what we own: `StanislavBG/sigma` and `StanislavBG/sigma-pr`.
- **Never force-push or rebase a branch on a fork we don't own.** For a contributor PR that needs a
  rebase, coordinate — don't overwrite their branch, and don't silently recreate it.
- **Cross-repo PRs to `midt-bg` must originate from `StanislavBG/sigma-pr`** (the in-network fork).
  `StanislavBG/sigma` is not in midt-bg's fork network, so PRs from it are rejected. Push feature
  branches to `sigma-pr` (the `fork` remote); mirror to `StanislavBG/sigma` main only for Replit.

## Reviewers — don't spam

- **Never re-request a reviewer who is already assigned.** Only request when a review is actually
  needed and not already pending.
- Approval dismisses on new pushes, so the reviewer (Todor) approves **last** — request review only
  once CI is green and threads are resolved. Don't ping mid-work.

## ETL: keep the two paths in parity

The pipeline has **two** scripts and they must agree:

- `scripts/normalize-raw.sql` — full rebuild
- `scripts/refresh-slice.sql` — incremental catch-up (the path that actually runs after backfill)

**Any change to identity, dedup, or keying (authorities, bidders, EIK validity) must be applied to
BOTH, using identical expressions.** `packages/db/src/refresh-slice.test.ts` enforces parity; a
one-path change will pass local eyeballing and fail CI. When you touch one, touch the other.

## Verify before shipping

- Run the minimal tests that cover the change (AGENTS.md). For SQL/ETL, run the parity + integrity
  suites, not just a visual read.
- `sqlite3` CLI may be absent locally — use Node's `node:sqlite` to execute statements against a
  fixture and confirm behavior before pushing.
- No fabricated/sample data; stay consistent with Sigma Core's data model (see the memory notes and
  AGENTS.md "Sigma Core vs Sigma Plus").

## Default posture

When a change is genuinely large and independent, a separate PR is fine. When it's related,
combine. When unsure whether to open another PR, **ask first** — the bias is toward fewer, larger,
well-scoped PRs that respect reviewers' time.
