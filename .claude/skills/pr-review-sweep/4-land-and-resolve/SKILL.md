---
name: pr-review-sweep:land-and-resolve
description: Step 4 of pr-review-sweep — once a queued PRD reports completed (or a thread was found already-fixed in step 2), reply on the GitHub thread naming the fixing commit SHA and resolve it. Runs async relative to steps 0-3, typically triggered by a later project-status-local pass noticing a completed PRD.
---

# pr-review-sweep:land-and-resolve

Two entry points:

1. **Already-fixed threads** from `pr-review-sweep:check-fixed` — no PRD to wait on, act
   immediately using the commit that step already identified.
2. **Queued PRDs** from `pr-review-sweep:queue` that the scheduler now reports
   `completed` — this is where this step actually waits on external state; a fresh
   `/project-status` (or manual) run is what notices the PRD finished and re-enters here.

## Steps

1. **Confirm the PRD actually ran its required verification** — both independent passes,
   and (for a `bug` bundle) that the regression test genuinely exists and is green, not
   just claimed in the PRD's own summary. A PRD marked `completed` without evidence of the
   ACs having run is `needs_review`, not landed — report it as stuck, don't proceed to
   reply/resolve.
2. **Confirm CI is green** on the PR after the PRD's commit landed.
3. **Reply** on each thread the PRD addresses, naming the specific fixing commit SHA, so
   the reviewer can verify without re-reading the whole diff.
4. **Resolve** the thread via GraphQL `resolveReviewThread`. Order matters: reply first,
   resolve second, so there's a paper trail explaining why a thread closed before it drops
   off the unresolved list.

Needs-my-decision threads (set aside back in `pr-review-sweep:classify`), and any
policy-override thread where convention says the reviewer should be the one to close it,
are deliberately left unresolved after the reply — that is correct behavior, not an
oversight.

## Stuck PRDs

A `failed` or `needs_review` PRD is reported to the user as a stuck bundle, never silently
retried and never silently downgraded to an inline fix — re-queuing or fixing it directly
both require the user's decision, since either implies the original PRD's scope or ACs
were wrong.

## Hard constant

**Never contact a reviewer** at any point in this step — replying to a thread and
resolving it are not reviewer contact; requesting/re-requesting one is `pr-signal`'s job
alone, gated separately.

## Output

Per thread: resolved (+ the SHA it was resolved against), or reported as blocked (PRD
still in flight, or stuck) — loops back to `project-status-local`'s rollup either way.
