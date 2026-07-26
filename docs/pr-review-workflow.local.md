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

## Flow — two atomic skills, auto-chained from one /project-status run (pr-signal excluded)

```
project-status-local  →  pr-review-sweep  →  [pr-signal]
      (read-only,           (fetch → classify →     (contacts a
   then auto-chains)         check-if-fixed →         reviewer —
                              fix-with-verify →        RARE, only on
                              reply-and-resolve;        explicit
                              inline, synchronous,      per-PR ask,
                              never queues a PRD;       never
                              never contacts a          auto-chained)
                              reviewer)
                                       |
                                       v
                         back to project-status-local
```

> **Superseded design, kept for context.** This originally chained through a three-way split —
> `pr-triage-feedback` → `pr-address-feedback` → `pr-commit`, with `pr-address-feedback` queuing
> a `/develop` PRD per PR (the global CLAUDE.md model-economics rule: real code changes run on
> the cheaper executor tier, not inline in an interactive session). Those three files were lost
> when the branch that introduced them (`recover/pr-overruns-wip-586`) never merged to `main`.
> `pr-review-sweep` was independently rebuilt to cover the same ground as one skill, and made a
> different scope call: it fixes review-comment threads **inline and synchronously** rather than
> queuing a PRD per thread, on the reasoning that review fixes are typically small and mechanical.
> That's a real, deliberate divergence from the model-economics rule — surface it back to the
> user if a sweep turns out to need substantial, non-mechanical work; don't silently do
> PRD-scale work inline just because this skill's default path is inline.

A single `/project-status` invocation drives every blocking-on-me PR's unresolved review threads
to resolved — it does not stop at reporting, and it does not contact a reviewer either.

1. **`project-status-local`** — enumerate my open PRs on `midt-bg/sigma`: CI status, review
   state (approved/changes-requested/pending), unresolved comment count, staleness. Renders the
   rollup, then **chains** into step 2 below for every blocking PR — it does not stop at
   reporting, and it never invokes `pr-signal`.
2. **`pr-review-sweep`** — for one PR flagged blocked: fetch every unresolved review thread
   (fully paginated GraphQL), classify each as accept-as-is / policy-override (per AGENTS.md,
   CLAUDE.local.md — repo policy wins silently over a conflicting reviewer ask) / needs-my-decision,
   check whether it's already fixed before writing anything, fix genuinely-unfixed
   accept/policy-override threads with real test/typecheck verification, commit + push to the
   fork branch, then reply naming the fixing commit SHA and resolve the thread. A
   needs-my-decision thread stops and asks — never guessed — but halts only **that thread**;
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
- **Idempotent re-runs.** Replies aren't re-posted; resolving an already-resolved thread is a
  no-op; re-running the sweep on a PR with nothing new to do is a no-op report.
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
