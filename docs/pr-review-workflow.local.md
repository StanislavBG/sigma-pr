# PR review workflow (local, contributor-scope)

Not checked into upstream policy — this is how *I* (a contributor, not owner) work
sigma's PR queue day to day. Complements [AGENTS.md](../AGENTS.md) (repo mechanics) and
[CLAUDE.local.md](../CLAUDE.local.md) (fewer-PRs / fork-push rules), which win on conflict.

## Why this exists

The default `/project-status` global framework assumes a project I fully own (KPI, crons,
health). Sigma is a **public repo I contribute to** — "status" here means *my open PRs*:
where they stand, what's blocking merge, and whether I owe a response. Solo-dev automation
(KPI loops, health checks) doesn't apply; team practices (review, respond to comments,
signal readiness) do.

## Scope (agreed)

- **Mine only.** Not a triage of all open PRs on the repo (that's `/find-opportunity`'s job
  for picking new work) — this is "where do MY submissions stand."
- **Local only, for now.** Lives in `sigma/.claude/skills/`, not the shared plugin. May be
  promoted/generalized later once the shape proves out on this repo.

## Flow — two skills (one a 5-step pipeline), auto-chained from one /project-status run
   (pr-signal excluded)

```
project-status-local  →  pr-review-sweep  →  [pr-signal]
      (read-only,           :fetch → :classify →     (contacts a
   then auto-chains)         :check-fixed → :queue      reviewer —
                              → :land-and-resolve;       RARE, only on
                              always queues a             explicit
                              /develop PRD per            per-PR ask,
                              (PR, type) bundle,           never
                              never fixes inline;          auto-chained)
                              never contacts a
                              reviewer)
                                       |
                                       v
                         back to project-status-local
```

> **History.** This originally chained through a three-way split — `pr-triage-feedback` →
> `pr-address-feedback` → `pr-commit`, with `pr-address-feedback` queuing a `/develop` PRD per
> PR (the global CLAUDE.md model-economics rule: real code changes run on the cheaper executor
> tier, not inline in an interactive session). Those three files were lost when the branch that
> introduced them (`recover/pr-overruns-wip-586`) never merged to `main`. A later rebuild of
> `pr-review-sweep` covered the same ground as one skill but briefly fixed threads **inline and
> synchronously** instead of queuing — that shortcut has since been reverted:
> `pr-review-sweep:queue` always queues a `/develop` PRD, no exceptions, and additionally
> classifies each thread as `bug` or `feature` so the PRD gets acceptance criteria suited to the
> kind of work it is. A future fast-queue lane in the scheduler itself (not a bypass here) is the
> right place to shorten the loop for small mechanical fixes, if that turns out to be worth
> building.

A single `/project-status` invocation drives every blocking-on-me PR's unresolved review threads
to queued, then (once the scheduler completes each PRD) resolved — it does not stop at
reporting, and it does not contact a reviewer either.

1. **`project-status-local`** — enumerate my open PRs on `midt-bg/sigma`: CI status, review
   state (approved/changes-requested/pending), unresolved comment count, staleness. Renders the
   rollup, then **chains** into step 2 below for every blocking PR — it does not stop at
   reporting, and it never invokes `pr-signal`.
2. **`pr-review-sweep`** (5-step nested pipeline) — for one PR flagged blocked:
   - `:fetch` — every unresolved review thread, fully paginated GraphQL.
   - `:classify` — per thread, two axes: disposition (accept-as-is / policy-override — repo
     policy wins silently over a conflicting reviewer ask, per AGENTS.md/CLAUDE.local.md —
     / needs-my-decision) and type (bug / feature, for accept/policy-override threads only).
   - `:check-fixed` — read current code + recent commits before queuing anything; already-fixed
     threads skip straight to `:land-and-resolve`.
   - `:queue` — bundle survivors by (PR, type) into one `/develop` PRD per bundle, with
     type-appropriate acceptance criteria (a `bug` bundle requires a reproduction + regression
     test; a `feature` bundle requires tight scope + pattern consistency). Duplicate-guarded —
     never double-queues the same bundle.
   - `:land-and-resolve` — once the scheduler reports a bundle's PRD `completed` (a later run
     notices this, not the same invocation that queued it), confirm its verification actually
     ran, reply naming the fixing commit SHA, resolve the thread.
   A needs-my-decision thread stops and asks — never guessed — but halts only **that thread**;
   every other thread on every other PR keeps flowing.
3. **`pr-signal`** (separate, rare, never auto-chained) — the only skill that requests or
   re-requests a reviewer. Requires CI green *at the moment of signaling* (re-checked, not
   inherited) and the user's fresh, per-PR approval given in the current conversation — a
   blanket "signal when ready" never carries forward, and this repo doesn't tag reviewers often,
   so expect this skill to run infrequently (see the reviewer-ping gate in
   `project-status-local`).

## Hardening invariants (shared across the chain)

- **Ground truth for "unresolved" is GraphQL `reviewThreads.isResolved`**, fully paginated
  (`first: 100` — smaller page sizes silently truncated on real PRs) — never a
  last-reply/last-push heuristic; every skill counts the same way. An "outdated" thread is not
  thereby addressed.
- **Always via the scheduler, never inline.** Every genuinely-unfixed thread is fixed by a
  `/develop` PRD; this skill's own steps never write application code.
- **Idempotent re-runs.** One queued/in-flight PRD per (PR, type) bundle; replies aren't
  re-posted; resolving an already-resolved thread is a no-op; re-running the sweep on a PR with
  nothing new to do is a no-op report.
- **Every step re-checks the PR is still open** before acting — a merge/close mid-chain stops
  that PR's chain with a report, and a needs-my-decision halt is per-thread (other threads and
  other PRs keep flowing).
- **Push only to what we own** — verify `headRepositoryOwner` is `StanislavBG` before any push;
  a contributor-owned head branch is a hard stop.

## Out of scope for now

- No KPI section for this repo (contributor, not owner — doesn't apply).
- No usage/consumption telemetry step (not applicable to a contributor workflow).
- Not triaging others' PRs, not deciding what to work on next (`/find-opportunity` already
  owns that).

## `issue-address` — the issue-scoped counterpart

Everything above is scoped to PRs *I already opened*. `issue-address` is the sibling entry
point for a GitHub **issue** — `find-opportunity` (or the user) names one, and `issue-address`
(itself a 6-step nested-skill pipeline: select → confirm-open → claim → reproduce → fix →
verify) takes it from report to landed PR: reproduce, confirm no open PR already fixes it
(checking everyone's, not just mine), root-cause, queue via `/develop`, track, independently
re-verify, open the PR (only when asked), and post a short standard-format comment on the
issue. It feeds into this doc's conventions rather than duplicating them — the opened PR gets a
clean, current description, and the issue comment follows `succinct-pr-communication`'s bullet
format. See [.claude/skills/issue-address/SKILL.md](../.claude/skills/issue-address/SKILL.md).
