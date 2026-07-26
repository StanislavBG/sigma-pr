---
name: project-status-local
model: opus
description: >-
  Sigma-specific implementation of /project-status. Sigma is a public repo
  (midt-bg/sigma) I contribute to, not own — "status" here means MY open PRs:
  where each stands, what's blocking merge, whether I owe a response. No
  KPI/crons/health (contributor scope, not ownership). Use whenever /project-status
  runs in this repo, or the user asks "what's my PR status", "any comments on my
  open PRs", "what's blocking my PRs". See docs/pr-review-workflow.local.md for
  the full flow this feeds into (pr-review-sweep, run per blocking PR).
---

# project-status-local (sigma) — my open PR rollup, then the sweep→queue→land loop

This skill's own bash steps are read-only — it never edits code, comments, or pushes directly.
It chains into `pr-review-sweep` (a 5-step nested pipeline: `:fetch` → `:classify` →
`:check-fixed` → `:queue` → `:land-and-resolve`, run per blocking PR), so a single
`/project-status` run drives every blocking PR's unresolved review threads to a queued fix and
eventually resolved, without a human re-invoking the skill by hand. See
[docs/pr-review-workflow.local.md](../../../docs/pr-review-workflow.local.md) for how this fits
the larger flow.

> Historical note: this skill originally chained through a three-way split
> (`pr-triage-feedback` → `pr-address-feedback` → `pr-commit`, each queuing a `/develop` PRD).
> Those files were lost when the branch carrying them (`recover/pr-overruns-wip-586`) never
> merged, and a later rebuild of `pr-review-sweep` briefly fixed threads inline instead of
> queuing them. That inline shortcut has since been reverted — `pr-review-sweep:queue` always
> queues a `/develop` PRD, no exceptions — per the standing rule that real code changes never
> happen inline in an interactive session. If a fast lane for small mechanical review fixes is
> ever worth having, that belongs as a priority/fast-queue lane in the scheduler itself, not as
> a bypass here.

## Steps

0. **This is now the full loop, not just a report.** After rendering the rollup (step 4), for
   every PR in the blocking-on-me set, auto-run `pr-review-sweep` — it classifies each unresolved
   thread by disposition (accept-as-is / policy-override / needs-my-decision) and, for threads
   going forward, by type (bug / feature), checks whether it's already fixed, queues a
   `/develop` PRD per (PR, type) bundle for what's left, and — once the scheduler reports a PRD
   `completed` — replies and resolves the threads it addressed. A needs-my-decision thread
   still stops and asks — never guessed — but it halts only **that thread**; every other thread
   on every other PR keeps flowing, and the open questions are collected into the final report.
   This turns one `/project-status` invocation into: audit → sweep every blocked PR's threads →
   queue their fixes → (on a later run, once PRDs complete) land and resolve → report
   readiness-to-signal. `pr-signal` — the separate, rarely-invoked skill that actually contacts
   a reviewer — is never auto-run by this chain. The reviewer-ping gate below is never relaxed
   by this automation — sweeping, queuing, and landing fixes needs no approval; signaling a
   reviewer always does, per PR, fresh each time.

1. **List my open PRs.**
   ```bash
   gh pr list --repo midt-bg/sigma --author "@me" --state open \
     --json number,title,url,isDraft,updatedAt,statusCheckRollup,reviewDecision
   ```
   Also check `StanislavBG/sigma-pr` if any PRs were opened from that fork and don't show
   under `midt-bg/sigma --author @me` (cross-repo forked PRs still list under the base repo,
   but confirm both per CLAUDE.local.md's fork-remote convention).

2. **Per PR, pull review threads.**
   ```bash
   gh pr view <number> --repo midt-bg/sigma --json reviews,comments,reviewRequests
   gh api repos/midt-bg/sigma/pulls/<number>/comments
   ```
   Count unresolved review threads using GraphQL `reviewThreads.isResolved` as the ground
   truth — the last-reply/last-push heuristic drifts and different runs disagree; never use it
   for the count (same discipline `pr-review-sweep:fetch` applies, `first: 100` and all). Note
   the reviewer and how long it's been unanswered.

3. **Determine what's blocking merge**, per PR:
   - CI red → blocking, cite the failing check.
   - `reviewDecision: CHANGES_REQUESTED` or unresolved threads → blocking, cite count.
   - `reviewDecision: APPROVED` + CI green → ready, note if it just needs a merge (not mine
     to do on `midt-bg` — pull-only access, per CLAUDE.local.md).
   - No reviewer activity yet, PR young → waiting, not blocked.
   - No reviewer activity yet, PR stale (>1 week per CLAUDE.local.md's "don't ping mid-work"
     but also don't let it rot) → flag as a candidate for a check-in, not a re-request (never
     re-request an already-assigned reviewer).

4. **Render the rollup** — one row per PR:

   | PR | Title | CI | Review | Unresolved | Blocking on | Next action |
   |---|---|---|---|---|---|---|

   Lead with any PR that's blocking-on-me (I owe a response/fix) — that's the actionable
   set. Then PRs blocking-on-them (waiting on reviewer/CI) for visibility only.

5. **Chain into the loop.** For each PR with unresolved comments, run step 0 above:
   `pr-review-sweep`. This skill's own bash steps stay read-only; the chaining happens by
   invoking `pr-review-sweep`, never by editing/committing/pushing/commenting directly in this
   skill's body.
   - If a PR merged or closed between the rollup and the chain step, drop it from the chain
     and note it — never sweep against a closed PR.

## Reviewer-ping gate (hard rule, applies to the whole flow)

Never request or re-request a reviewer, and never post anything that functions as a nudge to a
reviewer (a "ready for re-review" comment, an @-mention, a re-request), without the user's
**explicit, per-PR** approval first. `pr-review-sweep` never touches this — it queues, lands,
replies, and resolves, and stops. Only `pr-signal` contacts a reviewer, and only on its own
gate, described there. This
gate is stricter than — and overrides — the CI-green-and-threads-resolved heuristic: that
heuristic decides when a PR is *technically* ready to signal, not whether to actually send the
signal. Reaching
"technically ready" is never itself the go-ahead. A blanket "yes, signal reviewers when ready"
does not carry forward to the next PR — get the ask for each PR by number. When reporting a PR
as ready in the rollup, say so and wait; do not act on it in the same turn.

**CI-red voids any standing approval.** Approval to signal is scoped to "CI green at the moment
of signaling," not to the PR number in the abstract. If CI was green when the user approved but
goes red before the signal is actually sent (a later push, a flaky rerun, a new commit), the
approval is void — re-confirm CI is green immediately before acting, and if it isn't, stop and
re-ask rather than signaling on a stale approval. Never let the user approve a PR that is
currently CI-red in the first place — say so plainly in the rollup instead of prompting for
approval on it.
